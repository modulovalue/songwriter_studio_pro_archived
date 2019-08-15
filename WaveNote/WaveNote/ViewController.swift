//
//  ViewController.swift
//  WaveNote
//
//  Created by Modestas Valauskas on 10.08.17.
//  Copyright © 2017 MV. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    var selectedFile: String! {
        didSet {
            fileName.stringValue = selectedFile
            checkSelectedFile(path: selectedFile)
            currentNoteLabel.stringValue = "Current Note: \(getCurrentNote(path: selectedFile))"
        }
    }


    var comboBoxItems: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        for i in 0..<132 {
            let newElement = "\(toNote(number: i % 12))\(i / 12)"
            comboBoxItems.append(newElement)
        }
        comboBox.isEditable = false
        comboBox.removeAllItems()
        comboBox.addItems(withObjectValues: comboBoxItems)
        comboBox.selectItem(at: 60)
    }

    @IBOutlet weak var comboBox: NSComboBox!

    @IBOutlet weak var fileName: NSTextField!

    @IBAction func loadFile(_ sender: Any) {

        let dialog = NSOpenPanel()
        dialog.title                   = "Choose a wav file"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = false
        dialog.canCreateDirectories    = true
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = ["wav"]

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url
            if (result != nil) { selectedFile = result!.path }
        }
    }

    @IBAction func saveFile(_ sender: Any) {
        let newHexNote = String(format:"%2X", comboBox.indexOfSelectedItem)

        do {
            try changeNote(file: selectedFile, toNote: newHexNote)
                .write(to: URL(fileURLWithPath: selectedFile), options: .atomic)
        } catch {
            print(error)
        }
    }

    @IBOutlet weak var currentNoteLabel: NSTextField!

    func toNote(number: Int) -> String {
        switch number {
        case 0: return "C"
        case 1: return "C#"
        case 2: return "D"
        case 3: return "D#"
        case 4: return "E"
        case 5: return "F"
        case 6: return "F#"
        case 7: return "G"
        case 8: return "G#"
        case 9: return "A"
        case 10: return "A#"
        case 11: return "B"
        default:
            return "Not possible"
        }
    }

    func changeNote(file: String, toNote: String) -> Data {
        var dataRaw: Data! = nil

        do {
            dataRaw = try NSData(contentsOfFile: file) as Data
        } catch {
            print("whoopsie daysy")
        }

        let newNoteData = dataWithHexString(hex: toNote)
        let rawRange = dataRaw.range(of: dataWithHexString(hex: "696e7374"))

        if let range = rawRange {
            let replaceAt = dataRaw.index(range.lowerBound, offsetBy: 8)..<dataRaw.index(range.upperBound, offsetBy: 5)
            dataRaw.replaceSubrange(replaceAt, with: newNoteData)
        } else {
            print("couldn't find information about notes on sound file")
        }

        return dataRaw
    }

    func checkSelectedFile(path: String) {
        print(path)
    }

    func dataWithHexString(hex: String) -> Data {
        var hex = hex
        var data = Data()
        while(hex.characters.count > 0) {
            let c: String = hex.substring(to: hex.index(hex.startIndex, offsetBy: 2))
            hex = hex.substring(from: hex.index(hex.startIndex, offsetBy: 2))
            var ch: UInt32 = 0
            Scanner(string: c).scanHexInt32(&ch)
            var char = UInt8(ch)
            data.append(&char, count: 1)
        }
        return data
    }

    func getCurrentNote(path: String) -> String {
        var returnValue = "Error loading file"
        var dataRaw: Data! = nil

        do {
            dataRaw = try NSData(contentsOfFile: path) as Data
        } catch {
            print("whoopsie daysy")
        }

        let rawRange = dataRaw.range(of: dataWithHexString(hex: "696e7374"))

        if let range = rawRange {
            let replaceAt = dataRaw.index(range.lowerBound, offsetBy: 8)..<dataRaw.index(range.upperBound, offsetBy: 5)
            let str = dataRaw[replaceAt].hexDescription
            returnValue = str[0] + " and " + str[1] + " TODO parse"
        } else {
            print("couldn't find information about notes on sound file")
        }

        return returnValue
    }
}

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }

    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}

extension String {
    func indexDistance(of character: Character) -> Int? {
        guard let index = characters.index(of: character) else { return nil }
        return distance(from: startIndex, to: index)
    }
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }

    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }

    subscript (r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return String(self[Range(start ..< end)])
    }
}
