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
      thumbnailName: "whistle_tab_generator.png"

      //Autoload font
      FontLoader {
            id: whistleFont
             source: "WhistleSymbols.ttf"
             onStatusChanged: {
                   if (status === FontLoader.Ready) {
                         console.log("Font loaded successfully: " + "WhistleSymbols")
                         console.log("Font family name: " + "WhistleSymbols")
                   } else if (status === FontLoader.Error) {
                         error("Custom font failed to load! Check file path for: WhistleSymbols.ttf")
                   }
             }
      }

      width: 620
      height: 700


      property bool isDarkMode: false
      property color textColor: isDarkMode ? "#ffffff" : "#000000"
      property color backgroundColor: isDarkMode ? "#333333" : "#ffffff"

      //---------------------------------------------------------
      // USER SETTINGS (& defaults)
      //---------------------------------------------------------

      property int userFontSize: 8
      property int userJustification: 1   // 0=left,1=center,2=right
      property real userOffsetY: 1.2
      property real userLineSpacing: 0.8
      property string userFormatString: ""   // mirrors current profile's formatString
      property string userFontFamily: "Menlo, Consolas, Liberation Mono, Courier New, monospace"


      property int defaultFontSize: 8
      property int defaultJustification: 1
      property real defaultOffsetY: 1.2
      property real defaultLineSpacing: 0.8
      property string defaultFontFamily: "Menlo, Consolas, Liberation Mono, Courier New, monospace"

      // For undo/redo
      property var history: 0
      property var modified: false

      //---------------------------------------------------------
      // FINGERING DICTIONARY
      // Last bit = plus sign indicator
      //---------------------------------------------------------

      //Dictionary for your whistle, specifying the note and the fingering pattern (left-> right, starting from the fipple end).
      //2 indicates a closed hole, 1 indicates a half hole, 0 indicates open hole. The last digit is a reserved section indicating how many plusses (+) should be drawn to signal overblowing.

//      ○ = 0
//      ◐ = 1
//      ● = 2

      //Example fingering specification for high D whistle overblowing one octave to G6
//            |---------------------------------------------
//windway ->  | | |             ●  ●  ●    ○  ○  ○         |
//            |---------------------------------------------
//                "G6":   "     2  2  2    0  0  0  1 " <- last bit indicates number of +'s to add (i.e. how many times to overblow). Can be >= 0


//Example fingering specification for G#5 on a high D whistle
//            |---------------------------------------------
//windway ->  | | |             ●  ●  ◐    ○  ○  ○         |
//            |---------------------------------------------
//                 "G#5": "     2  2  1    0  0  0  0 " <- overblow bit set to zero to indicate first octave
//                              |  |  |    |  |  |  |
// variables in format string: $1 $2 $3   $4 $5 $6 $+   and then $note would be replaced with 'G#5'


//Can have any number of holes in the specification, but the formatting string must consume all hole variables

         // Hardcoded default profiles
      property var defaultProfiles: [
            {
                  name: "Custom Chromatic G Whistle (9 holes)",
                  fingeringDict: {
                        "G4": "2222222220",
                        "G#4": "2222222200",
                        "A4": "2222222000",
                        "A#4": "2222220000",
                        "B4": "2222200000",
                        "C5": "2222000000",
                        "C#5": "2220000000",
                        "D5": "2202000000",
                        "D#5": "2022200000",
                        "E5": "2020000000",
                        "F5": "0220000000",
                        "F#5": "0000000000",
                        "G5": "2222222221",
                        "G#5": "2222222201",
                        "A5": "2222222001",
                        "A#5": "2222220001",
                        "B5": "2222200001",
                        "C6": "2222000001",
                        "C#6": "2220000001",
                        "D6": "2200000001",
                        "D#6": "2222222202",
                        "E6": "2222222002",
                        "F6": "2222220002",
                        "F#6": "0222200002",
                        "G#6": "0222222222"
                  },
                  formatString: "$1    \n$2\n$3\n$4\n$5\n\n$6\n$7\n$8\n$9\n$+\n$note"
            },
            {
                  name: "High D Whistle (6 holes)",
                  fingeringDict: {
                        "D5": "2222220",
                        "D#5": "2222210",
                        "E5": "2222200",
                        "F5": "2222100",
                        "F#5": "2222000",
                        "G5": "2220000",
                        "G#5": "2210000",
                        "A5": "2200000",
                        "A#5": "2100000",
                        "B5": "2000000",
                        "C6": "0220000",
                        "C#6": "0000000",
                        "D6": "0222221",
                        "D#6": "2222211",
                        "E6": "2222201",
                        "F6": "2222101",
                        "F#6": "2222001",
                        "G6": "2220001",
                        "G#6": "2210001",
                        "A6": "2200001",
                        "A#6": "2100001",
                        "B6": "2000001",
                        "C7": "0202221",
                        "C#7": "0000001",
                        "D7": "2222222",
                  },
                  formatString: "$1\n$2\n$3\n\n$4\n$5\n$6\n$+\n\n$note"
            },
            {
                  "name": "C Whistle (6 holes)",
                  "fingeringDict": {
                        "C4": "2222220",
                        "C#4": "2222210",
                        "D4": "2222200",
                        "D#4": "2222100",
                        "E4": "2222000",
                        "F4": "2220000",
                        "F#4": "2210000",
                        "G4": "2200000",
                        "G#4": "2022220",
                        "A4": "2000000",
                        "A#4": "0220000",
                        "B4": "0000000",
                        "C5": "0222221",
                        "C#5": "2222211",
                        "D5": "2222201",
                        "D#5": "2222101",
                        "E5": "2222001",
                        "F5": "2220001",
                        "F#5": "2202201",
                        "G5": "2200001",
                        "G#5": "2020001",
                        "A5": "2000001",
                        "A#5": "0202221",
                        "B5": "0000001",
                        "C6": "0222222",
                  },
                  formatString: "$1\n$2\n$3\n\n$4\n$5\n$6\n$+\n\n$note"
            }
      ]

      // Runtime copy of profiles (loaded/saved via preferences)
      property var profiles: []
      property int currentProfileIndex: 0

      //---------------------------------------------------------
      // FINGERING DICTIONARY HELPERS
      //---------------------------------------------------------


      function getCurrentFingeringDict() {
            return profiles.length > 0 ? profiles[currentProfileIndex].fingeringDict : {}
      }

      function getCurrentFormatString() {
            return profiles.length > 0 ? profiles[currentProfileIndex].formatString : ""
      }

      function setCurrentFormatString(newFormat) {
            if (profiles.length > 0) {
                  profiles[currentProfileIndex].formatString = newFormat
                  userFormatString = newFormat
            }
      }


      Settings {
            id: pluginSettings
            category: "whistleTab"

            // Declare each setting as a property (with defaults)
            property string storedProfiles: ""
            property int storedCurrentProfile: 0
            property int storedFontSize: 8
            property int storedJustification: 1
            property real storedOffsetY: 1.2
            property real storedLineSpacing: 0.6
            property string storedFontFamily: defaultFontFamily
      }

      //---------------------------------------------------------
      // onRun
      //---------------------------------------------------------

      onRun: {
            if (!curScore) {
                  error("No score open.\nThis plugin requires an open score to run.\n")
                  quit()
            }

            loadSettings()

            // Ensure UI reflects loaded data
            userFormatString = getCurrentFormatString()
            fontSizeField.text = userFontSize
            offsetField.text = userOffsetY.toFixed(1)
            spacingField.text = userLineSpacing.toFixed(1)
            justCombo.currentIndex = userJustification
            formatInput.text = userFormatString
                  profileCombo.currentIndex = currentProfileIndex
                  updatePreview()
      }

      //---------------------------------------------------------
      // Undo/redo helpers (unchanged)
      //---------------------------------------------------------

      function getHistory() {
            if (history == 0) {
                  history = new commandHistory()
            }
            return history
      }

      //---------------------------------------------------------
      // Persistence using global preferences object
      //---------------------------------------------------------

      function saveSettings() {
            // Save profiles as JSON string
            var profilesForStorage = profiles.map(p => ({
                  name: p.name,
                  fingeringDict: p.fingeringDict,
                  formatString: p.formatString
            }))
            pluginSettings.storedProfiles = JSON.stringify(profilesForStorage)
            pluginSettings.storedCurrentProfile = currentProfileIndex
            pluginSettings.storedFontSize = userFontSize
            pluginSettings.storedJustification = userJustification
            pluginSettings.storedOffsetY = userOffsetY
            pluginSettings.storedLineSpacing = userLineSpacing
            pluginSettings.storedFontFamily = userFontFamily

            console.log("Settings saved")
      }

      function loadSettings() {
            // Load profiles
            var profilesStr = pluginSettings.storedProfiles
            if (profilesStr && profilesStr !== "") {
                  try {
                        var loaded = JSON.parse(profilesStr)
                        profiles = loaded.map(p => ({
                              name: p.name,
                              fingeringDict: p.fingeringDict,
                              formatString: p.formatString
                        }))
                  } catch (e) {
                        console.log("Failed to parse saved profiles, using defaults")
                        error("Failed to parse saved profiles, using defaults")

                        profiles = defaultProfiles.map(p => ({
                              name: p.name,
                              fingeringDict: JSON.parse(JSON.stringify(p.fingeringDict)),
                                                             formatString: p.formatString
                        }))
                  }
            } else {
                  profiles = defaultProfiles.map(p => ({
                        name: p.name,
                        fingeringDict: JSON.parse(JSON.stringify(p.fingeringDict)),
                                                       formatString: p.formatString
                  }))
            }

            // Load current profile index
            currentProfileIndex = pluginSettings.storedCurrentProfile
            if (currentProfileIndex < 0 || currentProfileIndex >= profiles.length)
                  currentProfileIndex = 0

                  // Load global settings (fall back to defaults if stored value is undefined)
                  userFontSize = pluginSettings.storedFontSize || defaultFontSize
                  userJustification = pluginSettings.storedJustification || defaultJustification
                  userOffsetY = pluginSettings.storedOffsetY || defaultOffsetY
                  userLineSpacing = pluginSettings.storedLineSpacing || defaultLineSpacing
                  userFontFamily = pluginSettings.storedFontFamily || defaultFontFamily


                  if (typeof fontFamilyField !== 'undefined') {
                        fontFamilyField.text = userFontFamily
                  }

                  console.log("Settings loaded")
      }
      //---------------------------------------------------------
      // Reset to defaults
      //---------------------------------------------------------

      function resetToDefaults() {
            getHistory().begin()   // if you have undo/redo

            // 1. Restore profiles from defaultProfiles
            profiles = defaultProfiles.map(p => ({
                  name: p.name,
                  fingeringDict: JSON.parse(JSON.stringify(p.fingeringDict)),
                                                 formatString: p.formatString
            }))
            currentProfileIndex = 0

            // 2. Reset global settings to defaults
            setUserFontSize(defaultFontSize)
            setUserJustification(defaultJustification)
            setUserOffsetY(defaultOffsetY)
            setUserLineSpacing(defaultLineSpacing)
            setUserFontFamily(defaultFontFamily)


            // 3. Update UI to reflect the new profile and settings
            userFormatString = getCurrentFormatString()
            formatInput.text = userFormatString
                  profileCombo.currentIndex = 0
                  fontSizeField.text = userFontSize
                  fontFamilyField.text = userFontFamily
                  offsetField.text = userOffsetY.toFixed(1)
                  spacingField.text = userLineSpacing.toFixed(1)
                  justCombo.currentIndex = userJustification

                  // 4. Persist all changes to Settings
                  pluginSettings.storedProfiles = JSON.stringify(profiles.map(p => ({
                        name: p.name,
                        fingeringDict: p.fingeringDict,
                        formatString: p.formatString
                  })))
                  pluginSettings.storedCurrentProfile = currentProfileIndex
                  pluginSettings.storedFontSize = userFontSize
                  pluginSettings.storedJustification = userJustification
                  pluginSettings.storedOffsetY = userOffsetY
                  pluginSettings.storedLineSpacing = userLineSpacing
                  pluginSettings.storedFontFamily = userFontFamily
                  pluginSettings.sync()   // optional: force immediate write

                  getHistory().end()
                  updatePreview()
                  console.log("Reset to defaults")
      }

      //---------------------------------------------------------
      // Error dialog
      //---------------------------------------------------------

      function error(errorMessage) {
            errorDialog.text = qsTr(errorMessage)
            errorDialog.open()
      }

      //---------------------------------------------------------
      // Dark mode detection
      //---------------------------------------------------------

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
                                    symbol = String.fromCharCode(0xE001)  // Closed hole - custom font
                                    else if (binaryString[i] === "1")
                                          symbol = String.fromCharCode(0xE002)  // Half hole - custom font
                                          else
                                                symbol = String.fromCharCode(0xE000) // Open Hole - custom font

                                                var token = "$" + (i+1)
                                                while (output.indexOf(token) !== -1) {
                                                      output = output.replace(token, symbol)
                                                }
                        }

                        var plusCount = parseInt(plusBit)
                        var plusSymbol = "+".repeat(plusCount)
                        if (plusCount === 0) {
                              plusSymbol = ""
                        }

                              //-------------------------------------------------
                              // Replace plus placeholder ($+) with number of plusses based on plusBit
                              //-------------------------------------------------

                            while (output.indexOf("$+") !== -1) {
                              output = output.replace("$+", plusSymbol)
                        }

                              //-------------------------------------------------
                              // Final validation
                              //-------------------------------------------------

                           if (output.indexOf("$") !== -1) {
                              console.log("Warning: Unreplaced placeholders in:", output)
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

            //var family = "WhistleSymbols"
            //text.defaultFont = family
            text.fontFamily = getFontStack()

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
                              // Some text elements are attached to the segment, not the chord
                              var annotations = segment.annotations
                              if (annotations) {
                                    for (var i = 0; i < annotations.length; i++) {
                                          var annotation = annotations[i]
                                          // Check if this annotation belongs to the same track
                                          if (annotation.track === track && annotation.type === Element.STAFF_TEXT) {
                                                var text = annotation.text
                                                if (text && (text.indexOf(String.fromCharCode(0xE001)) !== -1 ||  // Closed hole - custom font
                                                      text.indexOf(String.fromCharCode(0xE002)) !== -1 || // Half hole - custom font
                                                      text.indexOf(String.fromCharCode(0xE000)) !== -1 || // Open hole - custom font
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

                  while (cursor.segment) {
                        var element = cursor.segment.elementAt(track)

                        // If this track has a chord
                        if (element && element.type === Element.CHORD) {
                              // Some text elements are attached to the segment, not the chord
                              var annotations = cursor.segment.annotations
                              if (annotations) {
                                    for (var i = 0; i < annotations.length; i++) {
                                          var annotation = annotations[i]
                                          // Check if this annotation belongs to the same track
                                          if (annotation.track === track && annotation.type === Element.STAFF_TEXT) {
                                                var text = annotation.text
                                                if (text && (text.indexOf(String.fromCharCode(0xE001)) !== -1 || //Closed hole symbol
                                                      text.indexOf(String.fromCharCode(0xE002)) !== -1 || // Half hole - custom font
                                                      text.indexOf(String.fromCharCode(0xE000)) !== -1 || // Open Hole
                                                      text.indexOf("☒") !== -1)) {
                                                      removeElement(annotation)
                                                      removed++
                                                      }
                                          }
                                    }
                              }
                        }
                        cursor.next()
                  }
            }
            console.log("Removed", removed, "existing annotations")
            return removed
      }

      //---------------------------------------------------------
      // APPLY FINGERINGS (uses current profile's dictionary)
      //---------------------------------------------------------

      function applyFingerings() {
            if (typeof curScore === "undefined") {
                  error("No score selected")
                  return false
            }

            console.log("=== Applying Fingerings ===")
            console.log("Profile:", profiles[currentProfileIndex].name)
            console.log("userFontSize:", userFontSize)
            console.log("userFormatString:", userFormatString)
            console.log("userJustification:", userJustification)
            console.log("userOffsetY:", userOffsetY)
            console.log("userLineSpacing:", userLineSpacing)

            curScore.startCmd()

            var cursor = curScore.newCursor()
            cursor.rewind(0)

            var dict = getCurrentFingeringDict()
            var count = 0

            while (cursor.segment) {
                  if (cursor.element && cursor.element.type === Element.CHORD) {
                        var chord = cursor.element
                        var midi = chord.notes[0].pitch
                        var noteName = pitchToName(midi)

                        var text = newElement(Element.STAFF_TEXT)

                        if (!dict[noteName]) {
                              text.text = "☒"
                              console.log("Note not in dictionary:", noteName)
                        } else {
                              var diagram = buildFingeringText(dict[noteName], userFormatString, noteName)

                              text.text = "<font face=\"" + getFontStack() + "\">" + diagram + "</font>";

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

      //---------------------------------------------------------
      // Preview helpers (use current profile)
      //---------------------------------------------------------

	function getRandomNoteName() {
    var dict = getCurrentFingeringDict()
    var notes = []
    
    // Collect all note names into an array
    for (var note in dict) {
        notes.push(note)
    }
    
    // If dictionary is empty, return fallback
    if (notes.length === 0) {
        return "G5"
    }
    
    // Generate random index and return corresponding note
    var randomIndex = Math.floor(Math.random() * notes.length)
    return notes[randomIndex]
}


      function getPreviewText() {
            var dict = getCurrentFingeringDict()
            var firstNote = getRandomNoteName()
            if (dict[firstNote]) {
                  return buildFingeringText(dict[firstNote], formatInput.text, firstNote)
            }
            return "No preview available"
      }

      function getPreviewFont(){
            var baseFont = Qt.font({
                  family: "WhistleSymbols",
                  pointSize: userFontSize
            })

            // Split userFontFamily string into array and flatten with whistle font
            var fallbacks = userFontFamily.split(',').map(f => f.trim())
            baseFont.families = ["WhistleSymbols"].concat(fallbacks)


            return baseFont
      }


      // Build the full font stack dynamically
      function getFontStack() {
            return "WhistleSymbols" + ", " + userFontFamily;
      }


      function updatePreview() {
            previewLabel.text = getPreviewText()
      }

      //---------------------------------------------------------
      // Setters with undo/redo
      //---------------------------------------------------------

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
      function setUserFontFamily(family) {
            var oldFamily = userFontFamily
            getHistory().add(
                  function() {
                        userFontFamily = oldFamily
                        fontFamilyField.text = oldFamily
                        previewLabel.font = getPreviewFont()
                  },
                  function() {
                        userFontFamily = family
                        fontFamilyField.text = family
                        previewLabel.font = getPreviewFont()
                  },
                  "font family"
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
            var oldProfileFormat = getCurrentFormatString()
            getHistory().add(
                  function() {
                        // Undo: restore both userFormatString and the profile's formatString
                        userFormatString = oldFormat
                        formatInput.text = oldFormat
                              if (profiles.length > 0) {
                                    profiles[currentProfileIndex].formatString = oldProfileFormat
                              }
                  },
                  function() {
                        // Redo: apply new format to both
                        userFormatString = format
                        formatInput.text = format
                              if (profiles.length > 0) {
                                    profiles[currentProfileIndex].formatString = format
                              }
                  },
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

      //---------------------------------------------------------
      // Event handlers (call setters and save)
      //---------------------------------------------------------

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

      function fontFamilyChanged(family) {
            getHistory().begin()
            setModified(true)
            setUserFontFamily(family)
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

      function profileChanged(index) {
            if (index < 0 || index >= profiles.length) return
                  currentProfileIndex = index
                  userFormatString = profiles[index].formatString
                  formatInput.text = userFormatString
                        updatePreview()
                        saveSettings()   // immediately save profile change
      }

      //---------------------------------------------------------
      // UI (unchanged)
      //---------------------------------------------------------

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

                        SystemPalette { id: sysPal }

                        // PROFILE SELECTOR
                        GroupBox {
                              title: "Whistle Profile"
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
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 20

                                    Label {
                                          text: "Select whistle:"
                                          color: sysPal.windowText
                                    }
                                    ComboBox {
                                          id: profileCombo
                                          Layout.fillWidth: true
                                          model: profiles.map(p => p.name)
                                          currentIndex: currentProfileIndex
                                          onActivated: {
                                                profileChanged(index)
                                          }
                                          contentItem: Text {
                                                text: profileCombo.displayText
                                                color: sysPal.windowText
                                                font: profileCombo.font
                                                horizontalAlignment: Text.AlignLeft
                                                verticalAlignment: Text.AlignVCenter
                                                elide: Text.ElideRight
                                          }
                                          background: Rectangle {
                                                color: sysPal.window
                                                border.color: sysPal.mid
                                          }
                                    }
                                    Item {
                                          height: 50  // Spacer
                                          width: parent.width
                                    }
                              }
                        }

                        // TOP ROW - Text Formatting Options
                        GroupBox {
                              title: "Text Formatting"
                              //Layout.fillWidth: true
                              Layout.preferredWidth: 600
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

                                          onActiveFocusChanged: {
                                                if (!activeFocus) {
                                                      var newValue = parseInt(text)
                                                      if (!isNaN(newValue) && newValue >= 1 && newValue <= 999) {
                                                            if (newValue !== userFontSize) {
                                                                  fontSizeChanged(newValue)
                                                            }
                                                      } else {
                                                            text = userFontSize
                                                      }
                                                }
                                          }

                                          onTextChanged: {
                                                var newValue = parseInt(text)
                                                if (!isNaN(newValue) && newValue >= 1 && newValue <= 999) {
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
                                                justificationChanged(index)
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
                                          text: "Font Family:"
                                          color: sysPal.windowText
                                          Layout.alignment: Qt.AlignRight
                                    }
                                    TextField {
                                          id: fontFamilyField
                                          //Layout.preferredWidth: 120
                                          Layout.fillWidth: true
                                          text: userFontFamily
                                          color: sysPal.text
                                          selectionColor: sysPal.highlight
                                          selectedTextColor: sysPal.highlightedText
                                          background: Rectangle {
                                                color: sysPal.window
                                                border.color: sysPal.mid
                                          }
                                          onAccepted: {
                                                if (text !== userFontFamily) {
                                                      fontFamilyChanged(text)
                                                }
                                          }
                                          onActiveFocusChanged: {
                                                if (!activeFocus && text !== userFontFamily) {
                                                      fontFamilyChanged(text)
                                                }   }
                                    }

                                    Label {
                                          text: "Line Spacing:"
                                          color: sysPal.windowText
                                          Layout.alignment: Qt.AlignRight
                                    }
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
                                    Item {
                                          height: 50  // Spacer
                                          width: parent.width
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
                                          resetToDefaults()
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
                                                text: "Use placeholders like $1, $2, ..., for the holes, \n$+ for the plus indicator and $note for the note (e.g. G#5)"
                                                font.pixelSize: 10
                                                color: sysPal.windowText
                                          }
                                    }

                                    // Preview Area (right side)
                                    GroupBox {
                                          title: "Preview"
                                          Layout.preferredWidth: 120
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
                                                      //font.family: getFontStack()
                                                      //font.pointSize: userFontSize
                                                      color: sysPal.windowText
                                                      wrapMode: Text.WordWrap
                                                      width: parent.width
                                                      lineHeight: userLineSpacing
                                                      lineHeightMode: Text.ProportionalHeight
                                                      font: getPreviewFont()

                                                      // Dynamic alignment based on userJustification
                                                      horizontalAlignment: {
                                                            if (userJustification === 0) return Text.AlignLeft
                                                                  if (userJustification === 1) return Text.AlignHCenter
                                                                        return Text.AlignRight
                                                      }
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
                                          if (hasExistingAnnotations()) {
                                                overwriteDialog.open()
                                          } else {
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
            title: "Whistle Tab Generator"
            text: "An error occurred"
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

      //---------------------------------------------------------
      // Command pattern for undo/redo (unchanged)
      //---------------------------------------------------------


      // Command pattern for undo/redo
      function commandHistory() {
            function Command(undo_fn, redo_fn, label) {
                  this.undo = undo_fn
                  this.redo = redo_fn
                  this.label = label
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
