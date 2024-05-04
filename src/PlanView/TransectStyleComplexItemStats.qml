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

    TransectStyleComplexItemMath {
        id: _math
    }

    QGCLabel {
        id: weightL
        text: qsTr("Weight")
        visible: _tool.value === 1  //applies to spreading
    }
    QGCLabel {
        text: _math.scaled_dist_weight.toFixed(1) + " " + qsTr(" kg")
        visible: weightL.visible
    }

    QGCLabel {
        id: volumeL
        text: qsTr("Volume")
        visible: _tool.value === 2 //applies to spraying
    }
    QGCLabel {
        text: _math.scaled_dist_volume.toFixed(1) + " " + qsTr(" l")
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
        text: (_tool.value === 1)?_math.kg_per_ha.toFixed(1) + " " + qsTr("kg/ha"):_math.l_per_ha.toFixed(1) + " " + qsTr("l/ha")
        visible: appRateL.visible
    }

    QGCLabel {
        text: qsTr("Effective Dist.")
    }
    QGCLabel {
        text: _math.dist.toFixed(1) + " " + qsTr("m")
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
