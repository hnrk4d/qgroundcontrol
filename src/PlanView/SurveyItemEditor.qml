import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Dialogs  1.2
import QtQuick.Extras   1.4
import QtQuick.Layouts  1.2

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import QGroundControl.Palette       1.0
import QGroundControl.FlightMap     1.0

import com.fluktor 1.0 //FLKTR

TransectStyleComplexItemEditor {
    transectAreaDefinitionComplete: missionItem.surveyAreaPolygon.isValid
    transectAreaDefinitionHelp:     qsTr("Use the Polygon Tools to create the polygon which outlines your application area.") //FLKTR
    transectValuesHeaderName:       qsTr("Transects")
    transectValuesComponent:        _transectValuesComponent
    presetsTransectValuesComponent: _transectValuesComponent

    // The following properties must be available up the hierarchy chain
    //  property real   availableWidth    ///< Width for control
    //  property var    missionItem       ///< Mission Item for editor

    property real   _margin:        ScreenTools.defaultFontPixelWidth / 2
    property var    _missionItem:   missionItem

    Component {
        id: _transectValuesComponent

        GridLayout {
            Layout.fillWidth:   true
            columnSpacing:      _margin
            rowSpacing:         _margin
            columns:            2

            QGCLabel { text: qsTr("Angle") }
            FactTextField {
                fact:                   missionItem.gridAngle
                Layout.fillWidth:       true
                onUpdated:              angleSlider.value = missionItem.gridAngle.value
            }

            QGCSlider {
                id:                     angleSlider
                minimumValue:           0
                maximumValue:           359
                stepSize:               1
                tickmarksEnabled:       false
                Layout.fillWidth:       true
                Layout.columnSpan:      2
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
                onValueChanged:         missionItem.gridAngle.value = value
                Component.onCompleted:  value = missionItem.gridAngle.value
                updateValueWhileDragging: true
            }

            QGCLabel {
                text:       qsTr("Turnaround dist")
                visible:    !forPresets
            }
            FactTextField {
                Layout.fillWidth:   true
                fact:               missionItem.turnAroundDistance
                visible:            !forPresets
            }

            QGCComboBox { //FLKTR
                Layout.fillWidth:   true
                Layout.columnSpan:  2
                function createModel() {
                    var l = []
                    for(var i=0; i<SpreadingController.librarySize; i++) {
                        var text = SpreadingController.libraryEntryWeightedGritName(i)+" ["+
                                SpreadingController.gritPerSec(i, 2)+" kg/sec]"
                        l.push(text)
                    }
                    return l
                }
                function indexHasChangedHandler() {
                    //each time the index changes we want to update the motor percentage setting of the
                    //_missionItem. Remember: we reinterprete the camera setting for footprint distance as
                    //actuator setting for motors. The user still can overwrite the motor setting if he/she wants.
                    if(QGroundControl.settingsManager.toolSettings.tool.value === 1) {
                        _missionItem.cameraCalc.adjustedFootprintFrontal.value = SpreadingController.libraryDosingShaft(currentIndex)
                        _missionItem.cameraCalc.imageDensity.value = SpreadingController.libraryRotaryDisk(currentIndex)
                    }
                }

                model : {SpreadingController.librarySize; createModel()} //enforce dependency
                currentIndex: SpreadingController.currentIndex
                onActivated: {
                    SpreadingController.currentIndex = currentIndex
                }

                Component.onCompleted: {
                    SpreadingController.currentIndexChanged.connect(indexHasChangedHandler)
                    if(_tool.value === 1) {
                        _missionItem.cameraCalc.adjustedFootprintFrontal.value = SpreadingController.libraryDosingShaft(currentIndex)
                        _missionItem.cameraCalc.imageDensity.value = SpreadingController.libraryRotaryDisk(currentIndex)
                    }
                }

                visible: _tool.value === 1
            }

            QGCComboBox { //FLKTR
                Layout.fillWidth:   true
                Layout.columnSpan:  2
                function createModel() {
                    var l = []
                    for(var i=0; i<SprayingController.librarySize; i++) {
                        var text = SprayingController.libraryChemical(i)+" ["+
                                SprayingController.libraryPumpValue(i)+" %]"
                        l.push(text)
                    }
                    return l
                }
                function indexHasChangedHandler() {
                    //each time the index changes we want to update the motor percentage setting of the
                    //_missionItem. Remember: we reinterprete the camera setting for footprint distance as
                    //actuator setting for motors. The user still can overwrite the motor setting if he/she wants.
                    if(_tool.value === 2) {
                         _missionItem.cameraCalc.adjustedFootprintFrontal.value = SprayingController.libraryPumpValue(currentIndex)
                    }
                }

                model : {
                    SprayingController.librarySize;
                    createModel()
                } //enforce dependency
                currentIndex: SprayingController.currentIndex
                onActivated: {
                    SprayingController.currentIndex = currentIndex
                }

                Component.onCompleted: {
                    SprayingController.currentIndexChanged.connect(indexHasChangedHandler)
                    if(_tool.value === 2) {
                        _missionItem.cameraCalc.adjustedFootprintFrontal.value = SprayingController.libraryPumpValue(SprayingController.currentIndex)
                    }
                }

                visible: _tool.value === 2
            }

            QGCOptionsComboBox {
                Layout.columnSpan:  2
                Layout.fillWidth:   true
                visible:            !forPresets

                model: [
                    /*FLKTR
                    {
                        text:       qsTr("Hover and capture image"),
                        fact:       missionItem.hoverAndCapture,
                        enabled:    missionItem.cameraCalc.distanceMode === QGroundControl.AltitudeModeRelative || missionItem.cameraCalc.distanceMode === QGroundControl.AltitudeModeAbsolute,
                        visible:    missionItem.hoverAndCaptureAllowed
                    },
                    */
                    {
                        text:       qsTr("Refly at 90 deg offset"),
                        fact:       missionItem.refly90Degrees,
                        enabled:    missionItem.cameraCalc.distanceMode !== QGroundControl.AltitudeModeCalcAboveTerrain,
                        visible:    true
                    },
                    {
                        text:       qsTr("App. in turnarounds"), //FLKTR
                        fact:       missionItem.cameraTriggerInTurnAround,
                        enabled:    missionItem.hoverAndCaptureAllowed ? !missionItem.hoverAndCapture.rawValue : true,
                        visible:    false //true
                    },
                    {
                        text:       qsTr("Fly alternate transects"),
                        fact:       missionItem.flyAlternateTransects,
                        enabled:    true,
                        visible:    _vehicle ? (_vehicle.fixedWing || _vehicle.vtol) : false
                    }
                ]
            }
        }
    }

    KMLOrSHPFileDialog {
        id:             kmlOrSHPLoadDialog
        title:          qsTr("Select Polygon File")
        selectExisting: true

        onAcceptedForLoad: {
            missionItem.surveyAreaPolygon.loadKMLOrSHPFile(file)
            missionItem.resetState = false
            //editorMap.mapFitFunctions.fitMapViewportTomissionItems()
            close()
        }
    }
}
