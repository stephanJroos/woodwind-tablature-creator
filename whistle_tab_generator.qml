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

MuseScore {
      id: mscore
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
      // USER SETTINGS (& defaults)
      //---------------------------------------------------------

      property int userFontSize: 8
      property int userJustification: 1   // 0=left,1=center,2=right
      property real userOffsetY: 1.2
      property real userLineSpacing: 0.6
      property string userFormatString: "$1    \n$2\n$3\n$4\n$5\n$6\n$7\n$8\n$9\n$+"

      property int defaultFontSize: 8
      property int defaultJustification: 1
      property real defaultOffsetY: 1.2
      property real defaultLineSpacing: 0.6
      property string defaultFormatString: "$1    \n$2\n$3\n$4\n$5\n$6\n$7\n$8\n$9\n$+"

      // For undo/redo
      property var history: 0
      property var modified: false

      //---------------------------------------------------------
      // FINGERING DICTIONARY
      // Last bit = plus sign indicator
      //---------------------------------------------------------

      //Dictionary for your whistle, specifying the note and the fingering pattern (left-> right, starting from the fipple end).
      //2 indicates a closed hole, 1 indicates a half hole, 0 indicates open hole. The last digit is a reserved section indicating how many plusses (+) should be drawn to signal overblowing.
      property var fingeringDict: ({//Fingering dictionary for custom chromatic whistle in the key of
            "G4": "2222222220",      // G4
            "G#4": "2222222200",     // G#4 / Ab4
            "A4": "2222222000",      // A4
            "A#4": "2222220000",     // A#4 / Bb4
            "B4": "2222200000",      // B4
            "C5": "2222000000",      // C5 (middle C)
            "C#5": "2220000000",     // C#5 / Db5
            "D5": "2202000000",      // D5
            "D#5": "2022200000",     // D#5 / Eb5
            "E5": "2020000000",      // E5
            "F5": "0220000000",      // F5
            "F#5": "0000000000",     // F#5 / Gb5
            "G5": "2222222221",      // G5
            "G#5": "2222222201",     // G#5 / Ab5
            "A5": "2222222001",      // A5
            "A#5": "2222220001",     // A#5 / Bb5
            "B5": "2222200001",      // B5
            "C6": "2222000001",      // C6 (one octave above middle C)
            "C#6": "2220000001",     // C#6 / Db6
            "D6": "2200000001",      // D6
            "D#6": "2222222202",     // D#6 / Eb6
            "E6": "2222222002",      // E6
            "F6": "2222220002",      // F6
            "F#6": "0222200002",     // F#6 / Gb6
            "G#6": "0222222222"      // G#6
      })

      onRun: {
            if (!curScore) {
                  error("No score open.\nThis plugin requires an open score to run.\n")
                  quit()
            }

            loadSettings()
      }

      function getHistory() {
            if (history == 0) {
                  history = new commandHistory()
            }
            return history
      }

      function saveSettings() {
            return
            if (!curScore) {
                  console.log("No score open, cannot save preferences")
                  return
            }

            var preferences = curScore.preferences
            if (preferences) {
                  preferences.setString("whistleTab/formatString", userFormatString)
                  preferences.setInt("whistleTab/fontSize", userFontSize)
                  preferences.setInt("whistleTab/justification", userJustification)
                  preferences.setDouble("whistleTab/offsetY", userOffsetY)
                  preferences.setDouble("whistleTab/lineSpacing", userLineSpacing)
                  preferences.setString("whistleTab/fingeringDict", JSON.stringify(fingeringDict))
                  console.log("Settings saved")
            }
      }

      function loadSettings() {
            return
            if (!curScore) {
                  console.log("No score open, using defaults")
                  return
            }

            var preferences = curScore.preferences
            if (preferences) {
                  // Load with defaults if not found
                  userFormatString = preferences.getString("whistleTab/formatString", userFormatString)
                  userFontSize = preferences.getInt("whistleTab/fontSize", userFontSize)
                  userJustification = preferences.getInt("whistleTab/justification", userJustification)
                  userOffsetY = preferences.getDouble("whistleTab/offsetY", userOffsetY)
                  userLineSpacing = preferences.getDouble("whistleTab/lineSpacing", userLineSpacing)

                  var dictStr = preferences.getString("whistleTab/fingeringDict", "")
                  if (dictStr) {
                        fingeringDict = JSON.parse(dictStr)
                  }

                  // Update UI elements with loaded values
                  fontSizeField.text = userFontSize
                  offsetField.text = userOffsetY.toFixed(1)
                  spacingField.text = userLineSpacing.toFixed(1)
                  justCombo.currentIndex = userJustification
                  formatInput.text = userFormatString
                        updatePreview()

                        console.log("Settings loaded")
            }
      }

      function resetToDefaults() {
            getHistory().begin()

            // Set all properties to default values
            setUserFontSize(defaultFontSize)
            setUserJustification(defaultJustification)
            setUserOffsetY(defaultOffsetY)
            setUserLineSpacing(defaultLineSpacing)
            setUserFormatString(defaultFormatString)

            getHistory().end()
            saveSettings() // Save after reset
            updatePreview()
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
      function buildFingeringText(binaryString, formatString, noteName) {

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

                        var plusInt = parseInt(plusBit)
                        if (isNaN(plusInt) || plusInt < 0 || plusInt.toString() !== plusBit) {
                              return "Invalid Plus Bit: must be a positive integer (0, 1, 2, ...)"
                        }
                              //-------------------------------------------------
                              // Clone format string
                              //-------------------------------------------------

                              var output = formatString

                              //-------------------------------------------------
                              // Replace note placeholder ($note) with note name
                              //-------------------------------------------------

                              if (noteName) {
                                    while (output.indexOf("$note") !== -1) {
                                          output = output.replace("$note", noteName)
                                    }
                              }

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

                                                      // Use global replace to replace all occurrences
                                                      var token = "$" + (i+1)
                                                      while (output.indexOf(token) !== -1) {
                                                            output = output.replace(token, symbol)
                                                      }
                              }

                              //-------------------------------------------------
                              // Replace plus placeholder ($+) with number of plusses based on plusBit
                              //-------------------------------------------------

                              // Parse plusBit as integer to determine how many plusses to insert
                              var plusCount = parseInt(plusBit)
                              var plusSymbol = "+".repeat(plusCount)

                              // If plusCount is 0, use empty string
                              if (plusCount === 0) {
                                    plusSymbol = ""
                              }

                              // Replace all $+ placeholders with the generated plus string
                              while (output.indexOf("$+") !== -1) {
                                    output = output.replace("$+", plusSymbol)
                              }

                              //-------------------------------------------------
                              // Final validation
                              //-------------------------------------------------

                              if (output.indexOf("$") !== -1) {
                                    console.log("Warning: Unreplaced placeholders in:", output)
                                    return output  // Return anyway with what we have
                              }

                              return output
      }

      //---------------------------------------------------------
      // APPLY TEXT FORMATTING
      //---------------------------------------------------------

      function formatText(text) {
            console.log("Formatting text - setting fontSize to:", userFontSize)
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
      // CHECK FOR EXISTING ANNOTATIONS
      //---------------------------------------------------------

      function hasExistingAnnotations() {
            if (typeof curScore === "undefined") {
                  return false
            }

            var cursor = curScore.newCursor()
            cursor.rewind(0)

            // Get the first segment
            var segment = cursor.segment

            // Iterate through all segments
            while (segment) {
                  // Check all tracks (staff * 4 + voice)
                  for (var track = 0; track < curScore.ntracks; track++) {
                        var element = segment.elementAt(track)

                        // If this track has a chord
                        if (element && element.type === Element.CHORD) {
                              var chord = element

                              // Some text elements are attached to the segment, not the chord
                              var annotations = segment.annotations
                              if (annotations) {
                                    for (var i = 0; i < annotations.length; i++) {
                                          var annotation = annotations[i]
                                          // Check if this annotation belongs to the same track
                                          if (annotation.track === track && annotation.type === Element.STAFF_TEXT) {
                                                var text = annotation.text
                                                if (text && (text.indexOf("●") !== -1 ||
                                                      text.indexOf("◐") !== -1 ||
                                                      text.indexOf("○") !== -1 ||
                                                      text.indexOf("☒") !== -1)) {
                                                      return true
                                                      }
                                          }
                                    }
                              }
                        }
                  }
                  segment = segment.next
            }

            return false
      }
      //---------------------------------------------------------
      // REMOVE EXISTING ANNOTATIONS
      //---------------------------------------------------------

      function removeExistingAnnotations() {
            if (typeof curScore === "undefined") {
                  return 0
            }

            var cursor = curScore.newCursor()
            var removed = 0

            // Iterate through all tracks
            for (var track = 0; track < curScore.ntracks; track++) {
                  cursor.rewind(0)
                  cursor.track = track

                         // Iterate through all segments
            while (cursor.segment) {
                  // Check all tracks (staff * 4 + voice)
                  for (var track = 0; track < curScore.ntracks; track++) {
                        var element = cursor.segment.elementAt(track)

                        // If this track has a chord
                        if (element && element.type === Element.CHORD) {
                              var chord = element

                              // Some text elements are attached to the segment, not the chord
                              var annotations = cursor.segment.annotations
                              if (annotations) {
                                    for (var i = 0; i < annotations.length; i++) {
                                          var annotation = annotations[i]
                                          // Check if this annotation belongs to the same track
                                          if (annotation.track === track && annotation.type === Element.STAFF_TEXT) {
                                                var text = annotation.text
                                                if (text && (text.indexOf("●") !== -1 ||
                                                      text.indexOf("◐") !== -1 ||
                                                      text.indexOf("○") !== -1 ||
                                                      text.indexOf("☒") !== -1)) {
                                                      removeElement(annotation)
                                                      }
                                          }
                                    }
                              }
                        }
                  }
                  //cursor.segment = cursor.segment.next
                  cursor.next()
            }
            }

            console.log("Removed", removed, "existing annotations")
            return removed
      }

      //---------------------------------------------------------
      // APPLY FINGERINGS
      //---------------------------------------------------------

      function applyFingerings() {
            if (typeof curScore === "undefined") {
                  error("No score selected")
                  return false
            }

            console.log("=== Applying Fingerings ===")
            console.log("userFontSize:", userFontSize)
            console.log("userFormatString:", userFormatString)
            console.log("userJustification:", userJustification)
            console.log("userOffsetY:", userOffsetY)
            console.log("userLineSpacing:", userLineSpacing)

            curScore.startCmd()

            var cursor = curScore.newCursor()
            cursor.rewind(0)

            var count = 0
            while (cursor.segment) {
                  if (cursor.element && cursor.element.type === Element.CHORD) {
                        var chord = cursor.element
                        var midi = chord.notes[0].pitch
                        var noteName = pitchToName(midi)

                        var text = newElement(Element.STAFF_TEXT)

                        if (!fingeringDict[noteName]) { //note not in fingering dictionary
                              text.text = "☒"
                              console.log("Note not in dictionary:", noteName)
                        } else {
                              var diagram = buildFingeringText(fingeringDict[noteName], userFormatString, noteName)
                              text.text = diagram
                              console.log("Note:", noteName, "Diagram:", diagram.replace(/\n/g, "\\n"))
                        }

                        cursor.add(text)
                        formatText(text)

                              // Verify the text object has the properties set
                              console.log("Text fontSize after format:", text.fontSize)
                              console.log("Text offsetY after format:", text.offsetY)
                              console.log("Text lineSpacing after format:", text.lineSpacing)

                              count++
                  }
                  cursor.next()
            }

            curScore.endCmd()
            console.log("Applied fingerings to", count, "notes")
            console.log("=== Done ===")
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
                  function() {
                        userFontSize = oldSize
                        fontSizeField.text = oldSize
                        previewLabel.font.pointSize = oldSize
                  },
                  function() {
                        userFontSize = size
                        fontSizeField.text = size
                        previewLabel.font.pointSize = size
                  },
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
                  function() {
                        userOffsetY = oldOffset
                        offsetField.text = oldOffset.toFixed(1)
                  },
                  function() {
                        userOffsetY = offset
                        offsetField.text = offset.toFixed(1)
                  },
                  "vertical offset"
            )
      }

      function setUserLineSpacing(spacing) {
            var oldSpacing = userLineSpacing
            getHistory().add(
                  function() {
                        userLineSpacing = oldSpacing
                        spacingField.text = oldSpacing.toFixed(1)
                  },
                  function() {
                        userLineSpacing = spacing
                        spacingField.text = spacing.toFixed(1)
                  },
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

      function formatStringChanged(formatString) {
            getHistory().begin()
            setModified(true)
            setUserFormatString(formatString)
            getHistory().end()
            saveSettings()
      }

      function fontSizeChanged(size) {
            getHistory().begin()
            setModified(true)
            setUserFontSize(size)
            updatePreview()
            getHistory().end()
            saveSettings()
      }

      function justificationChanged(justification) {
            getHistory().begin()
            setModified(true)
            setUserJustification(justification)
            updatePreview()
            getHistory().end()
            saveSettings()
      }

      function offsetYChanged(offset) {
            getHistory().begin()
            setModified(true)
            setUserOffsetY(offset)
            updatePreview()
            getHistory().end()
            saveSettings()
      }

      function lineSpacingChanged(spacing) {
            getHistory().begin()
            setModified(true)
            setUserLineSpacing(spacing)
            updatePreview()
            getHistory().end()
            saveSettings()
      }

      Item {
            id: root
            anchors.fill: parent

        ScrollView {
                anchors.fill: parent
                clip: true

            GridLayout {
                  columns: 2
                  anchors.fill: parent
                  anchors.margins: 10

                  // Set up system palette for color management
                  SystemPalette { id: sysPal }

                  // TOP ROW - Text Formatting Options
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
                                    validator: IntValidator { bottom: 1; top: 999 }
                                    background: Rectangle {
                                          color: sysPal.window
                                          border.color: sysPal.mid
                                    }

                                    // Handle Enter key press
                                    onAccepted: {
                                          var newValue = parseInt(text)
                                          if (!isNaN(newValue) && newValue >= 1 && newValue <= 999) {
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
                                                if (!isNaN(newValue) && newValue >= 1 && newValue <= 999) {
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
                                          if (!isNaN(newValue) && newValue >= 1 && newValue <= 999) {
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
                                    onActivated: {
                                          justificationChanged(userJustification)
                                          updatePreview()
                                    }
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
                                    validator: DoubleValidator { bottom: -999.0; top: 999.0; decimals: 1 }
                                    background: Rectangle {
                                          color: sysPal.window
                                          border.color: sysPal.mid
                                    }

                                    onAccepted: {
                                          var newValue = parseFloat(text)
                                          if (!isNaN(newValue) && newValue >= -999.0 && newValue <= 999.0) {
                                                if (newValue !== userOffsetY) {
                                                      offsetYChanged(newValue)
                                                      updatePreview()
                                                }
                                          } else {
                                                text = userOffsetY.toFixed(1)
                                          }
                                    }

                                    onActiveFocusChanged: {
                                          if (!activeFocus) {
                                                var newValue = parseFloat(text)
                                                if (!isNaN(newValue) && newValue >= -999.0 && newValue <= 999.0) {
                                                      if (newValue !== userOffsetY) {
                                                            offsetYChanged(newValue)
                                                            updatePreview()
                                                      }
                                                } else {
                                                      text = userOffsetY.toFixed(1)
                                                }
                                          }
                                    }
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
                                    validator: DoubleValidator { bottom: 0; top: 6; decimals: 1 }
                                    background: Rectangle {
                                          color: sysPal.window
                                          border.color: sysPal.mid
                                    }

                                    onAccepted: {
                                          var newValue = parseFloat(text)
                                          if (!isNaN(newValue) && newValue >= 0 && newValue <= 6) {
                                                if (newValue !== userLineSpacing) {
                                                      lineSpacingChanged(newValue)
                                                      updatePreview()
                                                }
                                          } else {
                                                text = userLineSpacing.toFixed(1)
                                          }
                                    }

                                    onActiveFocusChanged: {
                                          if (!activeFocus) {
                                                var newValue = parseFloat(text)
                                                if (!isNaN(newValue) && newValue >= 0 && newValue <= 999) {
                                                      if (newValue !== userLineSpacing) {
                                                            lineSpacingChanged(newValue)
                                                            updatePreview()
                                                      }
                                                } else {
                                                      text = userLineSpacing.toFixed(1)
                                                }
                                          }
                                    }
                              }
                        }
                  }

                  // MIDDLE ROW - Undo/Redo/Reset Buttons
                  RowLayout {
                        Layout.columnSpan: 2
                        Layout.alignment: Qt.AlignRight
                        spacing: 10
                        Layout.topMargin: 10
                        Layout.bottomMargin: 10

                        Button {
                              id: resetButton
                              text: "Reset to Defaults"
                              contentItem: Text {
                                    text: resetButton.text
                                    color: sysPal.buttonText
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                              }
                              background: Rectangle {
                                    color: sysPal.button
                                    border.color: sysPal.mid
                              }
                              onClicked: {
                                    resetToDefaults()  // ADDED: Reset button handler
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
                                                      formatStringChanged(formatInput.text)
                                                            updatePreview()
                                                }
                                                onTextChanged: {
                                                      updatePreview()
                                                }
                                          }
                                    }

                                    Label {
                                          text: "Use placeholders like $1, $2, ..., $+ for the plus indicator and $note for the note (e.g. G#5)"
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
                                                lineHeight: userLineSpacing
                                                lineHeightMode: Text.ProportionalHeight
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
                                    // Check for existing annotations
                                    if (hasExistingAnnotations()) {
                                          overwriteDialog.open()
                                    } else {
                                          // No existing annotations, just apply
                                       if(applyFingerings())
                                             quit()
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
            id: overwriteDialog
            title: "Existing Annotations Found"
            text: "This score already contains whistle fingering annotations"
            detailedText: "Would you like to override them?"
            standardButtons: [StandardButton.Ok, StandardButton.Cancel]
            onAccepted: {
                  removeExistingAnnotations()
                  if(applyFingerings())
                        quit()

            }
            onRejected: {
                  overwriteDialog.close()
            }
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
