import QtQuick          2.3
import QtQuick.Controls 1.2

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0

import com.fluktor 1.0 //FLKTR

// Statistics section for TransectStyleComplexItems
Grid {
    // The following properties must be available up the hierarchy chain
    //property var    missionItem       ///< Mission Item for editor

    columns:        2
    columnSpacing:  ScreenTools.defaultFontPixelWidth

    //FLKTR: the dosing shaft impacts the application rate based on the measurements of the library
    property real lib_weight : (missionItem.vehicleSpeed>0)?missionItem.actuatorDistance*SpreadingUnitComponentController.libraryEntryWeightedGrit(SpreadingUnitComponentController.currentIndex)/(missionItem.vehicleSpeed*1000):0
    property real scaling : missionItem.cameraCalc.adjustedFootprintFrontal.value/SpreadingUnitComponentController.libraryDosingShaft(SpreadingUnitComponentController.currentIndex)
    property real weight : lib_weight*scaling
    property real area : QGroundControl.unitsConversion.squareMetersToAppSettingsAreaUnits(missionItem.coveredArea)
    property real kg_per_ha : weight/(area*0.0001)

    QGCLabel { text: qsTr("Weight") } //FLKTR
    QGCLabel { text: weight.toFixed(1) + " " + qsTr(" kg") }

    QGCLabel { text: qsTr("Appl. Area") }
    QGCLabel { text: area.toFixed(2) + " " + QGroundControl.unitsConversion.appSettingsAreaUnitsString }

    QGCLabel { text: qsTr("Appl. Rate") } //FLKTR
    QGCLabel { text: kg_per_ha.toFixed(1) + " " + qsTr("kg/ha") }

    QGCLabel { text: qsTr("Effective Dist.") } //FLKTR
    QGCLabel { text: missionItem.actuatorDistance.toFixed(1) + " " + qsTr("m") }

    /* FLKTR
    QGCLabel { text: qsTr("Photo Count") }
    QGCLabel { text: missionItem.cameraShots }

    QGCLabel { text: qsTr("Photo Interval") }
    QGCLabel { text: missionItem.timeBetweenShots.toFixed(1) + " " + qsTr("secs") }

    QGCLabel { text: qsTr("Trigger Distance") }
    QGCLabel { text: missionItem.cameraCalc.adjustedFootprintFrontal.valueString + " " + missionItem.cameraCalc.adjustedFootprintFrontal.units }
    */
}
