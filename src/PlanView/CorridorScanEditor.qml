import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.4
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
    transectAreaDefinitionComplete: _missionItem.corridorPolyline.isValid
    transectAreaDefinitionHelp:     qsTr("Use the Polyline Tools to create the polyline which defines the corridor.")
    transectValuesHeaderName:       qsTr("Corridor")
    transectValuesComponent:        _transectValuesComponent
    presetsTransectValuesComponent: _transectValuesComponent

    // The following properties must be available up the hierarchy chain
    //  property real   availableWidth    ///< Width for control
    //  property var    missionItem       ///< Mission Item for editor

    property real   _margin:        ScreenTools.defaultFontPixelWidth / 2
    property var    _missionItem:   missionItem

    property Fact _tool: QGroundControl.settingsManager.toolSettings.tool

    Component {
        id: _transectValuesComponent

        GridLayout {
            columnSpacing:  _margin
            rowSpacing:     _margin
            columns:        2

            QGCLabel { text: qsTr("Width") }
            FactTextField {
                fact:               _missionItem.corridorWidth
                Layout.fillWidth:   true
            }

            QGCLabel {
                text:       qsTr("Turnaround dist")
                visible:    !forPresets
            }
            FactTextField {
                fact:               _missionItem.turnAroundDistance
                Layout.fillWidth:   true
                visible:            !forPresets
            }

            QGCComboBox { //FLKTR
                Layout.fillWidth:   true
                Layout.columnSpan:  2
                function createModel() {
                    var l = []
                    for(var i=0; i<SpreadingUnitComponentController.librarySize; i++) {
                        var text = SpreadingUnitComponentController.libraryEntryWeightedGritName(i)+" ["+
                                SpreadingUnitComponentController.gritPerSec(i, 2)+" kg/sec]"
                        l.push(text)
                    }
                    return l
                }

                function indexHasChangedHandler() {
                    //see: SurveyItemEditor.indexHasChangedHandler
                    _missionItem.cameraCalc.adjustedFootprintFrontal.value = SpreadingUnitComponentController.libraryDosingShaft(currentIndex)
                    _missionItem.cameraCalc.imageDensity.value = SpreadingUnitComponentController.libraryRotaryDisk(currentIndex)
                }

                model : {SpreadingUnitComponentController.librarySize; createModel()} //enforce dependency
                currentIndex: SpreadingUnitComponentController.currentIndex
                onActivated: {
                    SpreadingUnitComponentController.currentIndex = currentIndex
                }

                Component.onCompleted: {
                    SpreadingUnitComponentController.currentIndexChanged.connect(indexHasChangedHandler)
                    _missionItem.cameraCalc.adjustedFootprintFrontal.value = SpreadingUnitComponentController.libraryDosingShaft(currentIndex)
                    _missionItem.cameraCalc.imageDensity.value = SpreadingUnitComponentController.libraryRotaryDisk(currentIndex)
                }

                visible: _tool.value !== 0
            }

            FactCheckBox {
                Layout.columnSpan:  2
                text:               qsTr("App. in turnarounds") //FLKTR
                fact:               _missionItem.cameraTriggerInTurnAround
                enabled:            _missionItem.hoverAndCaptureAllowed ? !_missionItem.hoverAndCapture.rawValue : true
                visible:            !forPresets
            }
        }
    }
}
