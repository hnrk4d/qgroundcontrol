/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "NTRIP.h"
#include "QGCLoggingCategory.h"
#include "QGCToolbox.h"
#include "QGCApplication.h"
#include "SettingsManager.h"
#include "PositionManager.h"
#include "NTRIPSettings.h"

#include <QDebug>

NTRIP::NTRIP(QGCApplication* app, QGCToolbox* toolbox)
    : QGCTool(app, toolbox)
{
}

void NTRIP::setToolbox(QGCToolbox* toolbox)
{
    QGCTool::setToolbox(toolbox);

    NTRIPSettings* settings = qgcApp()->toolbox()->settingsManager()->ntripSettings();
    if (settings->ntripServerConnectEnabled()->rawValue().toBool()) {
        qCDebug(NTRIPLog) << settings->ntripEnableVRS()->rawValue().toBool();
        _rtcmMavlink = new RTCMMavlink(*toolbox);

        _tcpLink = new NTRIPTCPLink(settings->ntripServerHostAddress()->rawValue().toString(),
                                    settings->ntripServerPort()->rawValue().toInt(),
                                    settings->ntripUsername()->rawValue().toString(),
                                    settings->ntripPassword()->rawValue().toString(),
                                    settings->ntripMountpoint()->rawValue().toString(),
                                    settings->ntripWhitelist()->rawValue().toString(),
                                    settings->ntripEnableVRS()->rawValue().toBool());
        connect(_tcpLink, &NTRIPTCPLink::error,              this, &NTRIP::_tcpError,           Qt::QueuedConnection);
        connect(_tcpLink, &NTRIPTCPLink::RTCMDataUpdate,   _rtcmMavlink, &RTCMMavlink::RTCMDataUpdate);
    }
}


void NTRIP::_tcpError(const QString errorMsg)
{
    qgcApp()->showAppMessage(tr("NTRIP Server Error: %1").arg(errorMsg));
}


NTRIPTCPLink::NTRIPTCPLink(const QString& hostAddress,
                           int port,
                           const QString &username,
                           const QString &password,
                           const QString &mountpoint,
                           const QString &whitelist,
                           const bool    &enableVRS)
    : QThread       ()
    , _hostAddress  (hostAddress)
    , _port         (port)
    , _username     (username)
    , _password     (password)
    , _mountpoint   (mountpoint)
    , _isVRSEnable  (enableVRS)
    , _vrsSendTimer(0)
    , _socketConnectTimer(0)
    , _toolbox      (qgcApp()->toolbox())
{
    for(const auto& msg: whitelist.split(',')) {
        int msg_int = msg.toInt();
        if(msg_int) {
            _whitelist.insert(msg_int);
        }
    }
    qCDebug(NTRIPLog) << "whitelist: " << _whitelist;
    if (!_rtcm_parsing) {
        _rtcm_parsing = new RTCMParsing();
    }
    _rtcm_parsing->reset();
    _state = NTRIPState::uninitialised;
    _lastPackageReceived = QTime::currentTime();

    // Start TCP Socket
    moveToThread(this);
    start();
}

NTRIPTCPLink::~NTRIPTCPLink(void) {
    if(_socketConnectTimer) {
        _socketConnectTimer->stop();
        QObject::disconnect(_socketConnectTimer, &QTimer::timeout, this, &NTRIPTCPLink::_hardwareConnect);
        delete _socketConnectTimer;
        _socketConnectTimer=0;
    }
    if (_socket) {
        if(_isVRSEnable) {
            _vrsSendTimer->stop();
            QObject::disconnect(_vrsSendTimer, &QTimer::timeout, this, &NTRIPTCPLink::_sendNMEA);
            delete _vrsSendTimer;
            _vrsSendTimer = nullptr;
        }
        _disconnectTcpSocket();

        // Delete Rtcm Parsing instance
        delete(_rtcm_parsing);
        _rtcm_parsing = nullptr;
    }
    quit();
    wait();
}

void NTRIPTCPLink::_disconnectTcpSocket() {
    if(_socket) {
        QObject::disconnect(_socket, &QTcpSocket::readyRead, this, &NTRIPTCPLink::_readBytes);
        _socket->disconnectFromHost();
        _socket->deleteLater();
        _socket = nullptr;
    }
}

void NTRIPTCPLink::run(void) {
    sleep(120); //give drone some time to connect and param transfer
    _socketConnectTimer = new QTimer();
    _socketConnectTimer->setInterval(5000);
    _socketConnectTimer->setSingleShot(false);
    QObject::connect(_socketConnectTimer,&QTimer::timeout, this, &NTRIPTCPLink::_hardwareConnect);
    _socketConnectTimer->start();

    // Init VRS Timer
    if(_isVRSEnable) {
        _vrsSendTimer = new QTimer();
        _vrsSendTimer->setInterval(_vrsSendRateMSecs);
        _vrsSendTimer->setSingleShot(false);
        QObject::connect(_vrsSendTimer, &QTimer::timeout, this, &NTRIPTCPLink::_sendNMEA);
        _vrsSendTimer->start();
    }

    exec();
}

void NTRIPTCPLink::_hardwareConnect() {
    if(abs(QTime::currentTime().secsTo(_lastPackageReceived)) > 60) {
        //something wrong, last received package time too long ago
        _disconnectTcpSocket();
        _lastPackageReceived=QTime::currentTime(); //avoid disconnect next loop
        //the reconnect happens in the next loop
        qCDebug(NTRIPLog) << "no response from server, trying to reconnect";
        return;
    }
    if(_socket) {
        //nothing to do
        return;
    }

    qCDebug(NTRIPLog) << "NTRIP Socket trying to connect";
    _socket = new QTcpSocket();
    _socket->connectToHost(_hostAddress, static_cast<quint16>(_port));

    // Give the socket time to connect to the other side otherwise error out
    if (!_socket->waitForConnected(4000)) {
        qCDebug(NTRIPLog) << _socket->errorString();
        delete _socket;
        _socket = 0;
        return;
    }

    QObject::connect(_socket, &QTcpSocket::readyRead, this, &NTRIPTCPLink::_readBytes);

    // If username is specified, send an http get request for data
    if (!_username.isEmpty()) {
        qCDebug(NTRIPLog) << "Sending HTTP request";
        QString auth = _username;
        if (!_password.isEmpty()) {
            auth += ":"+_password;
        }
        auth=auth.toUtf8().toBase64();
        //QString query = "GET /%1 HTTP/1.0\r\nUser-Agent: NTRIP\r\nAuthorization: Basic %2\r\n\r\n";
        QString query = "GET /%1 HTTP/1.1\r\nHost: %2:%3\r\nNtrip-Version: Ntrip/2.0\r\nUser-Agent: NTRIP Fluktor/1.0\r\n"
                        "Authorization: Basic %4\r\nConnection: close\r\n\r\n";
        QByteArray str = query.arg(_mountpoint).arg(_hostAddress).arg(_port).arg(auth).toUtf8();
        qCDebug(NTRIPLog) << str;
        _socket->write(str);
        _state = NTRIPState::waiting_for_http_response;
    } else {
        // If no mountpoint is set, assume we will just get data from the tcp stream
        _state = NTRIPState::waiting_for_rtcm_header;
    }

    qCDebug(NTRIPLog) << "NTRIP Socket connected";
    return;
}

void NTRIPTCPLink::_parse(const QByteArray &buffer)
{
    for(const uint8_t byte : buffer) {
        if(_state == NTRIPState::waiting_for_rtcm_header) {
            if(byte != RTCM3_PREAMBLE)
                continue;
            _state = NTRIPState::accumulating_rtcm_packet;
        }
        if(_rtcm_parsing->addByte(byte)) {
            _state = NTRIPState::waiting_for_rtcm_header;
            QByteArray message((char*)_rtcm_parsing->message(), static_cast<int>(_rtcm_parsing->messageLength()));
            //TODO: Restore the following when upstreamed in Driver repo
            //uint16_t id = _rtcm_parsing->messageId();
            uint16_t id = ((uint8_t)message[3] << 4) | ((uint8_t)message[4] >> 4);
            if(_whitelist.empty() || _whitelist.contains(id)) {
                emit RTCMDataUpdate(message);
                qCDebug(NTRIPLog) << "Sending " << id << "of size " << message.length();
            } else {
                qCDebug(NTRIPLog) << "Ignoring " << id;
            }
            _rtcm_parsing->reset();
        }
    }
}

void NTRIPTCPLink::_readBytes(void)
{
    if (!_socket) {
        return;
    }
    if(_state == NTRIPState::waiting_for_http_response) {
        QString line = _socket->readAll();
        qCDebug(NTRIPLog) << line;
        if (line.contains("200")){
            _state = NTRIPState::waiting_for_rtcm_header;
        } else {
            qCWarning(NTRIPLog) << "Server responded with " << line;
            // TODO: Handle failure. Reconnect?
            // Just move into parsing mode and hope for now.
            _state = NTRIPState::waiting_for_rtcm_header;
        }
        return;
    }
    QByteArray bytes = _socket->readAll();
    qCDebug(NTRIPLog) << bytes;
    _lastPackageReceived=QTime::currentTime();
    _parse(bytes);
}

void NTRIPTCPLink::_sendNMEA() {
    QGeoCoordinate position = _toolbox->qgcPositionManager()->gcsPosition();

    if(!position.isValid()) {
        if(_toolbox &&
            _toolbox->multiVehicleManager() &&
            _toolbox->multiVehicleManager()->activeVehicleAvailable() &&
            _toolbox->multiVehicleManager()->activeVehicle()) {
            position=_toolbox->multiVehicleManager()->activeVehicle()->coordinate();
            if(!position.isValid()) {
                qCDebug(NTRIPLog) << "no valid drone or groundstation geolocation, giving up";
                return;
            }
        }
    }

    double lat = position.latitude();
    double lng = position.longitude();
    double alt = position.altitude();

    qCDebug(NTRIPLog) << "lat : " << lat << " lon : " << lng << " alt : " << alt;

    QString time = QDateTime::currentDateTimeUtc().toString("hhmmss.zzz");

    if(!std::isnan(lat) && !std::isnan(lng)) {
        double latdms = (int) lat + (lat - (int) lat) * .6f;
        double lngdms = (int) lng + (lng - (int) lng) * .6f;
        if(isnan(alt) || alt<0.0) alt = 0.0;

        QString line = QString("$GP%1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11,%12,%13,%14,%15")
                .arg("GGA", time,
                     QString("%1").arg((double)qFabs(latdms * 100), 7, 'f', 2, '0'), //leading zeros are very important
                     lat < 0 ? "S" : "N",
                     QString("%1").arg((double)qFabs(lngdms * 100), 8, 'f', 2, '0'), //ditto
                     lng < 0 ? "W" : "E",
                     "1", "10", "1",
                     QString::number(alt, 'f', 2),
                     "M", "0", "M", "0.0", "0");

        // Calculate checksum and send message
        QString checkSum = _getCheckSum(line);
        QString nmeaMessage = QString(line + "*" + checkSum + "\r\n");

        // Write nmea message
        if(_socket) {
            qCDebug(NTRIPLog) << "write NMEA Message : " << nmeaMessage.toUtf8();
            _socket->write(nmeaMessage.toUtf8());
        }
    }
}

QString NTRIPTCPLink::_getCheckSum(QString line) {
    QByteArray temp_Byte = line.toUtf8();
    const char* buf = temp_Byte.constData();

    char character;
    int checksum = 0;

    for(int i = 0; i < line.length(); i++) {
        character = buf[i];
        switch(character) {
        case '$':
            // Ignore the dollar sign
            break;
        case '*':
            // Stop processing before the asterisk
            i = line.length();
            continue;
        default:
            // First value for the checksum
            if(checksum == 0) {
                // Set the checksum to the value
                checksum = character;
            }
            else {
                // XOR the checksum with this character's value
                checksum = checksum ^ character;
            }
        }
    }

    return QString("%1").arg(checksum, 0, 16);
}
