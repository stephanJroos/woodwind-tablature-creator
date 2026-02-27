//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Generalized whistle tab plugin
//  Requires the tin whistle font downloaded from Blayne Chastain:
//     https://www.blaynechastain.com/tin-whistle-tab-sibelius-plugin/
//
//  Based on the Note Names Plugin which is:
//  Copyright (C) 2012 Werner Schweer
//  Copyright (C) 2013 - 2016 Joachim Schmitz
//  Copyright (C) 2014 Jörn Eichler
//
//  and also based on the Recorder Woodwind Tablature plugin:
//  Copyright (C)2011 Dario Escobedo, Werner Schweer, Jens Iwanenko and others
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE
//=============================================================================

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import MuseScore 3.0
import FileIO 3.0

MuseScore {
      version: "4.1"
      title: "ASCII Whistle Fingering"
      description: "Inserts ASCII fingering diagrams using binary dictionary"
      pluginType: "dialog"
      categoryCode: "composing-arranging-tools"
      thumbnailName: "whistle_tab.png"

      width: 790
      height: 644

      property bool isDarkMode: false
      property color textColor: isDarkMode ? "#ffffff" : "#000000"
      property color backgroundColor: isDarkMode ? "#333333" : "#ffffff"

      //---------------------------------------------------------
      // USER SETTINGS (defaults)
      //---------------------------------------------------------

      property int userFontSize: 14
      property int userJustification: 1   // 0=left,1=center,2=right
      property real userOffsetY: 3.0
      property real userLineSpacing: 0.5
      property string userFormatString: "$1  \n$2\n$3\n$4\n$5\n$6\n$7\n$8\n$9\n$+"

      // For undo/redo
      property var history: 0
      property var modified: false

      //---------------------------------------------------------
      // FINGERING DICTIONARY
      // Last bit = plus sign indicator
      //---------------------------------------------------------

      //Dictionary for your whistle, specifying the note and the fingering pattern (starting from the fipple end).
      //2 indicates a closed hole, 1 indicates a half hole, 0 indicates open hole. The last bit is a reserved flag for whether a (+) symbol should be drawn.
      property var fingeringDict: ({
            "G5": "1111111111",
            "A5": "1111111100",
            "B5": "1111111000",
            "C6": "1111110000",
            "D6": "1111100000",
            "E6": "1111000000",
            "F#6": "1110000000",
            "G6": "1100000001"
      })

      onRun: {
            if (!curScore) {
                  error("No score open.\nThis plugin requires an open score to run.\n")
                  quit()
            }
      }

      function getHistory() {
            if (history == 0) {
                  history = new commandHistory()
            }
            return history
      }

      function error(errorMessage) {
            errorDialog.text = qsTr(errorMessage)
            errorDialog.open()
      }

      SystemPalette {
            id: systemPalette
            onWindowTextChanged: {
                  // Detect if we're in dark mode by comparing text and background brightness
                  var textBrightness = getBrightness(windowText)
                  var windowBrightness = getBrightness(window)
                  isDarkMode = textBrightness > windowBrightness
            }
            Component.onCompleted: {
                  // Initial detection
                  var textBrightness = getBrightness(windowText)
                  var windowBrightness = getBrightness(window)
                  isDarkMode = textBrightness > windowBrightness
            }
      }

      function getBrightness(color) {
            // Simple brightness calculation (0-255)
            return 0.299 * color.r * 255 + 0.587 * color.g * 255 + 0.114 * color.b * 255
      }

      //---------------------------------------------------------
      // MIDI → NOTE NAME
      //---------------------------------------------------------

      function pitchToName(midiPitch) {
            var names = ["C","C#","D","D#","E","F",
            "F#","G","G#","A","A#","B"]

            var pitchClass = midiPitch % 12
            var octave = Math.floor(midiPitch / 12) - 1

            return names[pitchClass] + octave
      }

      //---------------------------------------------------------
      // BUILD ASCII DIAGRAM
      //---------------------------------------------------------

      //Build fingering text using binary representation of the fingering for a note.
      //The last bit is the plus bit, indicating the first octave (0) or the second octave (1), to be annotated with a +
      function buildFingeringText(binaryString, formatString) {

            //-------------------------------------------------
            // Basic validation
            //-------------------------------------------------

            if (!binaryString || binaryString.length < 2)
                  return "Invalid fingering pattern. Length is wrong"

                  if (!formatString || typeof formatString !== "string")
                        return "ERR"

                        var holeCount = binaryString.length - 1
                        var plusBit = binaryString[binaryString.length - 1]

                        //-------------------------------------------------
                        // Validate allowed characters
                        //-------------------------------------------------

                        for (var i = 0; i < holeCount; i++) {
                              if (binaryString[i] !== "0" &&
                                    binaryString[i] !== "1" &&
                                    binaryString[i] !== "2")
                                    return "Invalid Fingering Pattern Value. Must be one of 0,1,2"
                        }

                        if (plusBit !== "0" && plusBit !== "1")
                              return "Invalid Plus Bit"

                              //-------------------------------------------------
                              // Clone format string
                              //-------------------------------------------------

                              var output = formatString

                              //-------------------------------------------------
                              // Replace numbered placeholders ($1 … $N)
                              //-------------------------------------------------

                              for (var i = 0; i < holeCount; i++) {

                                    var symbol

                                    if (binaryString[i] === "2")
                                          symbol = "●"
                                          else if (binaryString[i] === "1")
                                                symbol = "◐"
                                                else
                                                      symbol = "○"

                                                      var token = new RegExp("\\$" + (i+1) + "(?!\\d)", "g")
                                                      output = output.replace(token, symbol)
                              }

                              //-------------------------------------------------
                              // Replace plus placeholder ($+)
                              //-------------------------------------------------

                              var plusSymbol = (plusBit === "1") ? "+" : " "
                              output = output.replace(/\$\+/g, plusSymbol)

                              //-------------------------------------------------
                              // Final validation
                              //-------------------------------------------------

                              if (/\$\d+|\$\+/.test(output))
                                    return "Regex Validation Error"

                                    return output
      }

      //---------------------------------------------------------
      // APPLY TEXT FORMATTING
      //---------------------------------------------------------

      function formatText(text) {
            text.fontSize = userFontSize
            text.placement = Placement.BELOW
            text.autoplace = false
            text.offsetY = userOffsetY
            text.lineSpacing = userLineSpacing

            if (userJustification === 0)
                  text.align = Align.LEFT
                  else if (userJustification === 1)
                        text.align = Align.HCENTER
                        else
                              text.align = Align.RIGHT
      }

      //---------------------------------------------------------
      // APPLY FINGERINGS
      //---------------------------------------------------------

      function applyFingerings() {
            if (typeof curScore === "undefined") {
                  error("No score selected")
                  return false
            }

            curScore.startCmd()

            var cursor = curScore.newCursor()
            cursor.rewind(0)

            while (cursor.segment) {
                  if (cursor.element && cursor.element.type === Element.CHORD) {
                        var chord = cursor.element
                        var midi = chord.notes[0].pitch
                        var noteName = pitchToName(midi)

                        var text = newElement(Element.STAFF_TEXT)

                        if (!fingeringDict[noteName]) { //note not in fingering dictionary
                              text.text = "☒"
                        } else {
                              var diagram = buildFingeringText(fingeringDict[noteName], userFormatString)
                              text.text = diagram
                        }

                        cursor.add(text)
                        formatText(text)
                  }
                  cursor.next()
            }

            curScore.endCmd()
            return true
      }

      function getFirstNoteName() {
            for (var note in fingeringDict) {
                  return note  // Returns the first key in the dictionary
            }
            return "G5"  // Fallback if dictionary is empty
      }

      function getPreviewText() {
            var firstNote = getFirstNoteName()
            if (fingeringDict[firstNote]) {
                  // Use the current formatInput.text instead of userFormatString
                  // to show real-time updates as the user types
                  return buildFingeringText(fingeringDict[firstNote], formatInput.text)
            }
            return "No preview available"
      }

      function updatePreview() {
            previewLabel.text = getPreviewText()
      }

      function setUserFontSize(size) {
            var oldSize = userFontSize
            getHistory().add(
                  function() { userFontSize = oldSize },
                             function() { userFontSize = size; fontSizeSpin.value = size },
                             "font size"
            )
      }

      function setUserJustification(just) {
            var oldJust = userJustification
            getHistory().add(
                  function() { userJustification = oldJust; justCombo.currentIndex = oldJust },
                             function() { userJustification = just; justCombo.currentIndex = just },
                             "justification"
            )
      }

      function setUserOffsetY(offset) {
            var oldOffset = userOffsetY
            getHistory().add(
                  function() { userOffsetY = oldOffset; offsetSpin.value = oldOffset * 10 },
                             function() { userOffsetY = offset; offsetSpin.value = offset * 10 },
                             "vertical offset"
            )
      }

      function setUserLineSpacing(spacing) {
            var oldSpacing = userLineSpacing
            getHistory().add(
                  function() { userLineSpacing = oldSpacing; spacingSpin.value = oldSpacing * 10 },
                             function() { userLineSpacing = spacing; spacingSpin.value = spacing * 10 },
                             "line spacing"
            )
      }

      function setUserFormatString(format) {
            var oldFormat = userFormatString
            getHistory().add(
                  function() { userFormatString = oldFormat; formatInput.text = oldFormat },
                             function() { userFormatString = format; formatInput.text = format },
                             "format string"
            )
      }

      function setModified(state) {
            var oldModified = modified
            getHistory().add(
                  function() { modified = oldModified },
                             function() { modified = state },
                             "modified"
            )
      }

      function formatStringChanged() {
            getHistory().begin()
            setModified(true)
            setUserFormatString(formatInput.text)
            getHistory().end()
      }

      function fontSizeChanged() {
            getHistory().begin()
            setModified(true)
            setUserFontSize(fontSizeSpin.value)
            updatePreview()
            getHistory().end()
      }

      function justificationChanged() {
            getHistory().begin()
            setModified(true)
            setUserJustification(justCombo.currentIndex)
            updatePreview()
            getHistory().end()
      }

      function offsetYChanged() {
            getHistory().begin()
            setModified(true)
            setUserOffsetY(offsetSpin.value / 10)
            updatePreview()
            getHistory().end()
      }

      function lineSpacingChanged() {
            getHistory().begin()
            setModified(true)
            setUserLineSpacing(spacingSpin.value / 10)
            updatePreview()
            getHistory().end()
      }

      function formatCurrentValues() {
            var data = {
                  fontSize: userFontSize,
                  justification: userJustification,
                  offsetY: userOffsetY,
                  lineSpacing: userLineSpacing,
                  formatString: userFormatString,
                        fingeringDict: fingeringDict
            }
            return JSON.stringify(data)
      }

      function restoreSavedValues(data) {
            getHistory().begin()
            setUserFontSize(data.fontSize)
            setUserJustification(data.justification)
            setUserOffsetY(data.offsetY)
            setUserLineSpacing(data.lineSpacing)
            setUserFormatString(data.formatString)
            // Restore fingering dict if present
            if (data.hasOwnProperty('fingeringDict')) {
                  fingeringDict = data.fingeringDict
            }
            getHistory().end()
      }

      Item {
            anchors.fill: parent

            GridLayout {
                  columns: 2
                  anchors.fill: parent
                  anchors.margins: 10

                  // Set up system palette for color management
                  SystemPalette { id: sysPal }

                  // TOP ROW - Text Formatting Options
                  GroupBox {
                        title: "Text Formatting"
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        background: Rectangle {
                              color: sysPal.window
                              border.color: sysPal.mid
                        }
                        label: Label {
                              text: parent.title
                              color: sysPal.windowText
                              background: Rectangle { color: sysPal.window }
                        }

                        GridLayout {
                              columns: 4
                              anchors.fill: parent
                              anchors.margins: 10
                              columnSpacing: 20
                              rowSpacing: 10

                              Label {
                                    text: "Font Size:"
                                    color: sysPal.windowText
                                    Layout.alignment: Qt.AlignRight
                              }
                              // Font Size
                              TextField {
                                    id: fontSizeField
                                    Layout.preferredWidth: 80
                                    text: userFontSize
                                    color: sysPal.text
                                    selectionColor: sysPal.highlight
                                    selectedTextColor: sysPal.highlightedText
                                    validator: IntValidator { bottom: 6; top: 72 }
                                    background: Rectangle {
                                          color: sysPal.window
                                          border.color: sysPal.mid
                                    }

                                    // Handle Enter key press
                                    onAccepted: {
                                          var newValue = parseInt(text)
                                          if (!isNaN(newValue) && newValue >= 6 && newValue <= 72) {
                                                if (newValue !== userFontSize) {
                                                      fontSizeChanged(newValue)
                                                }
                                          } else {
                                                text = userFontSize  // Revert to previous value if invalid
                                          }
                                    }

                                    // Handle focus loss
                                    onActiveFocusChanged: {
                                          if (!activeFocus) {
                                                var newValue = parseInt(text)
                                                if (!isNaN(newValue) && newValue >= 6 && newValue <= 72) {
                                                      if (newValue !== userFontSize) {
                                                            fontSizeChanged(newValue)
                                                      }
                                                } else {
                                                      text = userFontSize  // Revert to previous value if invalid
                                                }
                                          }
                                    }

                                    // Update preview in real-time as user types
                                    onTextChanged: {
                                          var newValue = parseInt(text)
                                          if (!isNaN(newValue) && newValue >= 6 && newValue <= 72) {
                                                // Temporarily update preview without committing to history
                                                previewLabel.font.pointSize = newValue
                                          }
                                    }
                              }
                              Label {
                                    text: "Justification:"
                                    color: sysPal.windowText
                                    Layout.alignment: Qt.AlignRight
                              }
                              ComboBox {
                                    id: justCombo
                                    Layout.preferredWidth: 120
                                    model: ["Left", "Center", "Right"]
                                    currentIndex: userJustification
                                    onActivated: justificationChanged()
                                    contentItem: Text {
                                          text: justCombo.displayText
                                          color: sysPal.windowText
                                          font: justCombo.font
                                          horizontalAlignment: Text.AlignLeft
                                          verticalAlignment: Text.AlignVCenter
                                          elide: Text.ElideRight
                                    }
                                    background: Rectangle {
                                          color: sysPal.window
                                          border.color: sysPal.mid
                                    }
                              }

                              Label {
                                    text: "Vertical Offset:"
                                    color: sysPal.windowText
                                    Layout.alignment: Qt.AlignRight
                              }
                              // Vertical Offset
                              TextField {
                                    id: offsetField
                                    Layout.preferredWidth: 80
                                    text: userOffsetY.toFixed(1)
                                    color: sysPal.text
                                    selectionColor: sysPal.highlight
                                    selectedTextColor: sysPal.highlightedText
                                    validator: DoubleValidator { bottom: -20.0; top: 20.0; decimals: 1 }
                                    background: Rectangle {
                                          color: sysPal.window
                                          border.color: sysPal.mid
                                    }

                                    onAccepted: {
                                          var newValue = parseFloat(text)
                                          if (!isNaN(newValue) && newValue >= -20.0 && newValue <= 20.0) {
                                                if (newValue !== userOffsetY) {
                                                      offsetYChanged(newValue)
                                                }
                                          } else {
                                                text = userOffsetY.toFixed(1)
                                          }
                                    }

                                    onActiveFocusChanged: {
                                          if (!activeFocus) {
                                                var newValue = parseFloat(text)
                                                if (!isNaN(newValue) && newValue >= -20.0 && newValue <= 20.0) {
                                                      if (newValue !== userOffsetY) {
                                                            offsetYChanged(newValue)
                                                      }
                                                } else {
                                                      text = userOffsetY.toFixed(1)
                                                }
                                          }
                                    }

                                    // Offset doesn't affect preview content, so no onTextChanged needed
                              }

                              Label {
                                    text: "Line Spacing:"
                                    color: sysPal.windowText
                                    Layout.alignment: Qt.AlignRight
                              }
                              // Line Spacing
                              TextField {
                                    id: spacingField
                                    Layout.preferredWidth: 80
                                    text: userLineSpacing.toFixed(1)
                                    color: sysPal.text
                                    selectionColor: sysPal.highlight
                                    selectedTextColor: sysPal.highlightedText
                                    validator: DoubleValidator { bottom: 0.5; top: 3.0; decimals: 1 }
                                    background: Rectangle {
                                          color: sysPal.window
                                          border.color: sysPal.mid
                                    }

                                    onAccepted: {
                                          var newValue = parseFloat(text)
                                          if (!isNaN(newValue) && newValue >= 0.5 && newValue <= 3.0) {
                                                if (newValue !== userLineSpacing) {
                                                      lineSpacingChanged(newValue)
                                                }
                                          } else {
                                                text = userLineSpacing.toFixed(1)
                                          }
                                    }

                                    onActiveFocusChanged: {
                                          if (!activeFocus) {
                                                var newValue = parseFloat(text)
                                                if (!isNaN(newValue) && newValue >= 0.5 && newValue <= 3.0) {
                                                      if (newValue !== userLineSpacing) {
                                                            lineSpacingChanged(newValue)
                                                      }
                                                } else {
                                                      text = userLineSpacing.toFixed(1)
                                                }
                                          }
                                    }

                                    // Line spacing doesn't affect preview content, so no onTextChanged needed
                              }
                        }
                  }

                  // MIDDLE ROW - Save/Load/Undo/Redo Buttons
                  RowLayout {
                        Layout.columnSpan: 2
                        Layout.alignment: Qt.AlignRight
                        spacing: 10
                        Layout.topMargin: 10
                        Layout.bottomMargin: 10

                        Button {
                              id: saveButton
                              text: qsTranslate("PrefsDialogBase", "Save Settings")
                              contentItem: Text {
                                    text: saveButton.text
                                    color: sysPal.buttonText
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                              }
                              background: Rectangle {
                                    color: sysPal.button
                                    border.color: sysPal.mid
                              }
                              onClicked: {
                                    saveDialog.folder = filePath
                                    saveDialog.visible = true
                              }
                        }

                        Button {
                              id: loadButton
                              text: qsTranslate("PrefsDialogBase", "Load Settings")
                              contentItem: Text {
                                    text: loadButton.text
                                    color: sysPal.buttonText
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                              }
                              background: Rectangle {
                                    color: sysPal.button
                                    border.color: sysPal.mid
                              }
                              onClicked: {
                                    loadDialog.folder = filePath
                                    loadDialog.visible = true
                              }
                        }

                        Button {
                              id: undoButton
                              text: qsTranslate("PrefsDialogBase", "Undo")
                              contentItem: Text {
                                    text: undoButton.text
                                    color: sysPal.buttonText
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                              }
                              background: Rectangle {
                                    color: sysPal.button
                                    border.color: sysPal.mid
                              }
                              onClicked: {
                                    getHistory().undo()
                                    // Update text fields after undo
                                    fontSizeField.text = userFontSize
                                    offsetField.text = userOffsetY.toFixed(1)
                                    spacingField.text = userLineSpacing.toFixed(1)
                                    justCombo.currentIndex = userJustification
                              }
                        }

                        Button {
                              id: redoButton
                              text: qsTranslate("PrefsDialogBase", "Redo")
                              contentItem: Text {
                                    text: redoButton.text
                                    color: sysPal.buttonText
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                              }
                              background: Rectangle {
                                    color: sysPal.button
                                    border.color: sysPal.mid
                              }
                              onClicked: {
                                    getHistory().redo()
                                    // Update text fields after redo
                                    fontSizeField.text = userFontSize
                                    offsetField.text = userOffsetY.toFixed(1)
                                    spacingField.text = userLineSpacing.toFixed(1)
                                    justCombo.currentIndex = userJustification
                              }
                        }
                  }

                  // BOTTOM ROW - Format String and Preview
                  GroupBox {
                        title: "Format String & Preview"
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        background: Rectangle {
                              color: sysPal.window
                              border.color: sysPal.mid
                        }
                        label: Label {
                              text: parent.title
                              color: sysPal.windowText
                              background: Rectangle { color: sysPal.window }
                        }

                        RowLayout {
                              width: parent.width
                              spacing: 20
                              anchors.margins: 10

                              // Format String Area (left side)
                              ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 5

                                    Label {
                                          text: "Format String:"
                                          color: sysPal.windowText
                                          font.bold: true
                                    }

                                    ScrollView {
                                          Layout.fillWidth: true
                                          Layout.fillHeight: true
                                          Layout.preferredHeight: 200
                                          clip: true
                                          background: Rectangle {
                                                color: sysPal.window
                                                border.color: sysPal.mid
                                          }

                                          TextArea {
                                                id: formatInput
                                                width: parent.width
                                                height: contentHeight
                                                wrapMode: TextEdit.Wrap
                                                text: userFormatString
                                                color: sysPal.text
                                                selectionColor: sysPal.highlight
                                                selectedTextColor: sysPal.highlightedText
                                                background: Rectangle {
                                                      color: sysPal.window
                                                      border.color: sysPal.mid
                                                }
                                                property var previousText: userFormatString
                                                onEditingFinished: {
                                                      formatStringChanged()
                                                            updatePreview()
                                                }
                                                onTextChanged: {
                                                      updatePreview()
                                                }
                                          }
                                    }

                                    Label {
                                          text: "Use placeholders like $1, $2, ... and $+ for the plus indicator"
                                          font.pixelSize: 10
                                          color: sysPal.windowText
                                    }
                              }

                              // Preview Area (right side)
                              GroupBox {
                                    title: "Preview (" + getFirstNoteName() + ")"
                                    Layout.preferredWidth: 200
                                    Layout.fillHeight: true
                                    background: Rectangle {
                                          color: sysPal.window
                                          border.color: sysPal.mid
                                    }
                                    label: Label {
                                          text: parent.title
                                          color: sysPal.windowText
                                          background: Rectangle { color: sysPal.window }
                                    }

                                    ScrollView {
                                          anchors.fill: parent
                                          anchors.margins: 5
                                          clip: true
                                          background: Rectangle {
                                                color: sysPal.window
                                                border.color: sysPal.mid
                                          }

                                          Label {
                                                id: previewLabel
                                                text: getPreviewText()
                                                font.family: "Courier"
                                                font.pointSize: userFontSize
                                                color: sysPal.windowText
                                                wrapMode: Text.WordWrap
                                                width: parent.width
                                          }
                                    }
                              }
                        }
                  }

                  // BOTTOM BUTTONS - Apply and Cancel
                  RowLayout {
                        Layout.columnSpan: 2
                        Layout.alignment: Qt.AlignRight
                        spacing: 10
                        Layout.topMargin: 10

                        Button {
                              id: applyButton
                              text: qsTranslate("PrefsDialogBase", "Apply")
                              contentItem: Text {
                                    text: applyButton.text
                                    color: sysPal.buttonText
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                              }
                              background: Rectangle {
                                    color: sysPal.button
                                    border.color: sysPal.mid
                              }
                              onClicked: {
                                    if (applyFingerings()) {
                                          if (modified) {
                                                quitDialog.open()
                                          } else {
                                                quit()
                                          }
                                    }
                              }
                        }

                        Button {
                              id: cancelButton
                              text: qsTranslate("PrefsDialogBase", "Cancel")
                              contentItem: Text {
                                    text: cancelButton.text
                                    color: sysPal.buttonText
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                              }
                              background: Rectangle {
                                    color: sysPal.button
                                    border.color: sysPal.mid
                              }
                              onClicked: {
                                    if (modified) {
                                          quitDialog.open()
                                    } else {
                                          quit()
                                    }
                              }
                        }
                  }
            }
      }

      MessageDialog {
            id: errorDialog
            title: "Error"
            text: ""
            onAccepted: {
                  errorDialog.close()
            }
      }

      MessageDialog {
            id: quitDialog
            title: "Quit?"
            text: "Do you want to quit the plugin?"
            detailedText: "You have unsaved changes. You can save your settings to a file before quitting if you like."
            standardButtons: [StandardButton.Ok, StandardButton.Cancel]
            onAccepted: {
                  quit()
            }
            onRejected: {
                  quitDialog.close()
            }
      }

      FileIO {
            id: saveFile
            source: ""
      }

      FileIO {
            id: loadFile
            source: ""
      }

      function getFile(dialog) {
            return dialog.filePath
      }

      FileDialog {
            id: loadDialog
            title: "Load Settings"
            onAccepted: {
                  loadFile.source = getFile(loadDialog)
                  var data = JSON.parse(loadFile.read())
                  restoreSavedValues(data)
                  loadDialog.visible = false
            }
            onRejected: {
                  loadDialog.visible = false
            }
            visible: false
      }

      FileDialog {
            id: saveDialog
            title: "Save Settings"
            onAccepted: {
                  saveFile.source = getFile(saveDialog)
                  saveFile.write(formatCurrentValues())
                  saveDialog.visible = false
            }
            onRejected: {
                  saveDialog.visible = false
            }
            visible: false
      }

      // Command pattern for undo/redo
      function commandHistory() {
            function Command(undo_fn, redo_fn, label) {
                  this.undo = undo_fn
                  this.redo = redo_fn
                  this.label = label // for debugging
            }

            var history = []
            var index = -1
            var transaction = 0
            var maxHistory = 30

            function newHistory(commands) {
                  if (index < maxHistory) {
                        index++
                        history = history.slice(0, index)
                  } else {
                        history = history.slice(1, index)
                  }
                  history.push(commands)
            }

            this.add = function(undo, redo, label) {
                  var command = new Command(undo, redo, label)
                  command.redo()
                  if (transaction) {
                        history[index].push(command)
                  } else {
                        newHistory([command])
                  }
            }

            this.undo = function() {
                  if (index != -1) {
                        history[index].slice().reverse().forEach(
                              function(command) {
                                    command.undo()
                              }
                        )
                        index--
                  }
            }

            this.redo = function() {
                  if ((index + 1) < history.length) {
                        index++
                        history[index].forEach(
                              function(command) {
                                    command.redo()
                              }
                        )
                  }
            }

            this.begin = function() {
                  if (transaction) {
                        throw new Error("already in transaction")
                  }
                  newHistory([])
                  transaction = 1
            }

            this.end = function() {
                  if (!transaction) {
                        throw new Error("not in transaction")
                  }
                  transaction = 0
            }
      }
}
