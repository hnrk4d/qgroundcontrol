import QtQuick          2.3

import QGroundControl               1.0
import QGroundControl.FactSystem    1.0

import com.fluktor 1.0 //FLKTR

Item {
    //FLKTR: the tool library settings impact the application rates
    property Fact _tool: QGroundControl.settingsManager.toolSettings.tool
    property Fact _tankVolume: QGroundControl.settingsManager.toolSettings.tankVolume

    //general
    property real area : _missionItem.coveredArea // in m^2
    property real dist : _missionItem.actuatorDistance
    property real v    : _missionItem.vehicleSpeed // in m/sec
    property real va   : v*_missionItem.cameraCalc.adjustedFootprintSide.value// application speed (in m^2/sec)

    //related to spreading
    property real lib_weight : (_tool.value === 1 && SpreadingController.currentIndex >= 0)?SpreadingController.gritPerSec(SpreadingController.currentIndex):0
    property real dist_weight : (_tool.value === 1 && v>0 && SpreadingController.currentIndex >= 0)?dist*lib_weight/v:0
    property real scaling : (_tool.value === 1 && SpreadingController.currentIndex >= 0)?_missionItem.cameraCalc.adjustedFootprintFrontal.value/SpreadingController.libraryDosingShaft(SpreadingController.currentIndex):0
    property real scaled_dist_weight : dist_weight * scaling
    property real scaled_lib_weight : lib_weight * scaling
    property real kg_per_ha : (_tool.value === 1 && va>0)?scaled_lib_weight*10000/va:0

    //related to spraying
    property real volume_per_sec : (_tool.value === 2 && SprayingController.currentIndex >= 0)?SprayingController.volPerSec(SprayingController.currentIndex):0
    property real dist_volume : (_tool.value === 2 && v>0 && SprayingController.currentIndex >= 0)?dist*volume_per_sec/v:0
    property real scaling1 : (_tool.value === 2 && SprayingController.currentIndex >= 0)?_missionItem.cameraCalc.adjustedFootprintFrontal.value/SprayingController.libraryPumpValue(SprayingController.currentIndex):0
    property real scaled_dist_volume : dist_volume * scaling1
    property real scaled_volume_per_sec : volume_per_sec * scaling1
    property real l_per_ha : (_tool.value === 2 && va>0)?scaled_volume_per_sec*10000/va:0

    //valid for both tools
    property real volume : (_tool.value === 1 && SpreadingController.currentIndex >= 0)?scaled_dist_weight/SpreadingController.libraryDensity(SpreadingController.currentIndex):((_tool.value === 2)?scaled_dist_volume:0)
    property bool tank_refillment_required : (_tool.value === 1 || _tool.value === 2)?(_tankVolume.value < volume):0
}
