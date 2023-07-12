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

    QGCLabel { text: qsTr("Appl. Area") }
    QGCLabel { text: QGroundControl.unitsConversion.squareMetersToAppSettingsAreaUnits(missionItem.coveredArea).toFixed(2) + " " + QGroundControl.unitsConversion.appSettingsAreaUnitsString }

    QGCLabel { text: qsTr("Effective Dist.") } //FLKTR
    QGCLabel { text: missionItem.actuatorDistance.toFixed(1) + " " + qsTr("m") }

    //QGCLabel { text: qsTr("Grit") } //FLKTR
    //QGCLabel { text: SpreadingUnitComponentController.libraryEntryWeightedGritName(SpreadingUnitComponentController.currentIndex) }

    QGCLabel { text: qsTr("Weight") } //FLKTR
    QGCLabel { text: ((missionItem.vehicleSpeed>0)?missionItem.actuatorDistance*SpreadingUnitComponentController.libraryEntryWeightedGrit(SpreadingUnitComponentController.currentIndex)/(missionItem.vehicleSpeed*1000):0).toFixed(1) + " " + qsTr("kg") }

    /* FLKTR
    QGCLabel { text: qsTr("Photo Count") }
    QGCLabel { text: missionItem.cameraShots }

    QGCLabel { text: qsTr("Photo Interval") }
    QGCLabel { text: missionItem.timeBetweenShots.toFixed(1) + " " + qsTr("secs") }

    QGCLabel { text: qsTr("Trigger Distance") }
    QGCLabel { text: missionItem.cameraCalc.adjustedFootprintFrontal.valueString + " " + missionItem.cameraCalc.adjustedFootprintFrontal.units }
    */
}
