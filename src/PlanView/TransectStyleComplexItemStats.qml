import QtQuick          2.3
import QtQuick.Controls 1.2

import QGroundControl               1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0

import com.fluktor 1.0 //FLKTR

// Statistics section for TransectStyleComplexItems
Grid {
    // The following properties must be available up the hierarchy chain
    //property var    missionItem       ///< Mission Item for editor

    columns:        2
    columnSpacing:  ScreenTools.defaultFontPixelWidth

    //FLKTR: the tool library settings impact the application rates
    property Fact _tool: QGroundControl.settingsManager.toolSettings.tool

    //general
    property real area : missionItem.coveredArea // in m^2
    property real dist : missionItem.actuatorDistance
    property real v    : missionItem.vehicleSpeed // in m/sec
    property real va   : v*missionItem.cameraCalc.adjustedFootprintSide.value// application speed (in m^2/sec)

    //related to spreading
    property real lib_weight : (_tool.value === 1 && SpreadingController.currentIndex >= 0)?SpreadingController.gritPerSec(SpreadingController.currentIndex):0
    property real dist_weight : (_tool.value === 1 && v>0 && SpreadingController.currentIndex >= 0)?dist*lib_weight/v:0
    property real scaling : (_tool.value === 1 && SpreadingController.currentIndex >= 0)?missionItem.cameraCalc.adjustedFootprintFrontal.value/SpreadingController.libraryDosingShaft(SpreadingController.currentIndex):0
    property real scaled_dist_weight : dist_weight * scaling
    property real scaled_lib_weight : lib_weight * scaling
    property real kg_per_ha : (_tool.value === 1 && va>0)?scaled_lib_weight*10000/va:0

    //related to spraying
    property real volume_per_sec : (_tool.value === 2 && SprayingController.currentIndex >= 0)?SprayingController.volPerSec(SprayingController.currentIndex):0
    property real dist_volume : (_tool.value === 2 && v>0 && SprayingController.currentIndex >= 0)?dist*volume_per_sec/v:0
    property real scaling1 : (_tool.value === 2 && SprayingController.currentIndex >= 0)?missionItem.cameraCalc.adjustedFootprintFrontal.value/SprayingController.libraryPumpValue(SprayingController.currentIndex):0
    property real scaled_dist_volume : dist_volume * scaling1
    property real scaled_volume_per_sec : volume_per_sec * scaling1
    property real l_per_ha : (_tool.value === 2 && va>0)?scaled_volume_per_sec*10000/va:0

    QGCLabel {
        id: weightL
        text: qsTr("Weight")
        visible: _tool.value === 1  //applies to spreading
    }
    QGCLabel {
        text: scaled_dist_weight.toFixed(1) + " " + qsTr(" kg")
        visible: weightL.visible
    }

    QGCLabel {
        id: volumeL
        text: qsTr("Volume")
        visible: _tool.value === 2 //applies to spraying
    }
    QGCLabel {
        text: scaled_dist_volume.toFixed(1) + " " + qsTr(" l")
        visible: volumeL.visible
    }

    QGCLabel {
        text: qsTr("Appl. Area")
    }
    QGCLabel {
        text: QGroundControl.unitsConversion.squareMetersToAppSettingsAreaUnits(missionItem.coveredArea).toFixed(2) + " " + QGroundControl.unitsConversion.appSettingsAreaUnitsString
    }

    QGCLabel {
        id: appRateL
        text: qsTr("Appl. Rate")
        visible: _tool.value !== 0
    }
    QGCLabel {
        text: (_tool.value === 1)?kg_per_ha.toFixed(1) + " " + qsTr("kg/ha"):l_per_ha.toFixed(1) + " " + qsTr("l/ha")
        visible: appRateL.visible
    }

    QGCLabel {
        text: qsTr("Effective Dist.")
    }
    QGCLabel {
        text: dist.toFixed(1) + " " + qsTr("m")
    }

    /* FLKTR
    QGCLabel { text: qsTr("Photo Count") }
    QGCLabel { text: missionItem.cameraShots }

    QGCLabel { text: qsTr("Photo Interval") }
    QGCLabel { text: missionItem.timeBetweenShots.toFixed(1) + " " + qsTr("secs") }

    QGCLabel { text: qsTr("Trigger Distance") }
    QGCLabel { text: missionItem.cameraCalc.adjustedFootprintFrontal.valueString + " " + missionItem.cameraCalc.adjustedFootprintFrontal.units }
    */
}
