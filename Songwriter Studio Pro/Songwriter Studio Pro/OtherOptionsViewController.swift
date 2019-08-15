//
//  OtherOptionsViewController.swift
//  SongwriterStudioPro
//
//  Created by Modestas Valauskas on 09.12.17.
//  Copyright © 2017 MV. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class OtherOptionsViewController: UITableViewController {

    @IBOutlet weak var projectLastSavedLbl: UILabel!
    @IBOutlet weak var projectNameLbl: UILabel!
    @IBOutlet weak var projectBPMLbl: UILabel!
    @IBOutlet weak var projectSampleRateLbl: UILabel!
    @IBOutlet weak var projectSizeLbl: UILabel!

    @IBOutlet weak var outputDeviceSpinner: UIPickerView!
    var inputStuff = InputStuff()
    @IBOutlet weak var inputDeviceSpinner: UIPickerView!
    var outputStuff = OutputStuff()

    @IBOutlet weak var metronomeAudioStyleSpinner: UIPickerView!
    var metronomeAudioStyleStuff = MetronomeAudioStyle()
    @IBOutlet weak var metronomeVisualStyleSpinner: UIPickerView!
    var metronomeVisualStyleStuff = MetronomeVisualStyle()

    var mainScreen: MainScreen? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        projectLastSavedLbl.text = "never"
        projectNameLbl.text = mainScreen!.dataSource?.getProjectName()
        projectBPMLbl.text = "\(String(describing: mainScreen!.dataSource?.getProjectBPM())) BPM"
        projectSampleRateLbl.text = "\(String(describing: mainScreen!.dataSource?.getProjectSamplingRate())) Hz"
        projectSizeLbl.text = "/"

        outputDeviceSpinner.delegate = outputStuff
        outputDeviceSpinner.dataSource = outputStuff
        inputDeviceSpinner.delegate = inputStuff
        inputDeviceSpinner.dataSource = inputStuff

        metronomeAudioStyleSpinner.delegate = metronomeAudioStyleStuff
        metronomeAudioStyleSpinner.dataSource = metronomeAudioStyleStuff
        metronomeVisualStyleSpinner.delegate = metronomeVisualStyleStuff
        metronomeVisualStyleSpinner.dataSource = metronomeVisualStyleStuff

        NotificationCenter
            .default
            .addObserver(
                self,
                selector: #selector(updateAudioRoutingChanged),
                name: NSNotification.Name.AVAudioSessionRouteChange,
                object: nil)

        updateAudioRoutingChanged()
    }

    @objc func updateAudioRoutingChanged() {
        outputDeviceSpinner.reloadAllComponents()
        inputDeviceSpinner.reloadAllComponents()
        outputDeviceSpinner.selectRow(outputStuff.currentValue(), inComponent: 0, animated: true)
        inputDeviceSpinner.selectRow(inputStuff.currentValue(), inComponent: 0, animated: true)
    }

    @IBAction func backBtn(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            // Save
            case 0:
                mainScreen?.delegate?.toolbarEvent(event: .stop)
                // TODO save project
                let timestamp = DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .medium, timeStyle: .short)
                projectLastSavedLbl.text = timestamp
            // Change Name
            case 1:
                mainScreen?.delegate?.toolbarEvent(event: .stop)
                func configurationTextField(textField: UITextField!) {
                    textField.text = mainScreen!.dataSource?.getProjectName()
                }
                let alert = UIAlertController(title: "Change name", message: "Set a new name for this project", preferredStyle: UIAlertControllerStyle.alert)
                alert.addTextField(configurationHandler: configurationTextField)
                alert.addAction(UIAlertAction(title: "Save as a new project (last save acts as a backup)", style: UIAlertActionStyle.default, handler:{ (UIAlertAction) in
                    //alert.textFields?.first?.text
                    // TODO Save as new project
                }))
                alert.addAction(UIAlertAction(title: "Overwrite the old project (just change the name)", style: UIAlertActionStyle.default, handler:{ (UIAlertAction) in
                    //alert.textFields?.first?.text
                    // TODO delete old project
                    // TODO save as new project
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler:{ (UIAlertAction) in }))
                self.present(alert, animated: true, completion: nil)

            // Change BPM
            case 2:
                mainScreen?.delegate?.toolbarEvent(event: .stop)
                func configurationTextField(textField: UITextField!) {
                    textField.text = "\(Int((mainScreen!.dataSource?.getProjectBPM())!))"
                    textField.keyboardType = .numberPad
                }
                let alert = UIAlertController(title: "Change BPM", message: "Enter new BPM (50-300)", preferredStyle: UIAlertControllerStyle.alert)
                alert.addTextField(configurationHandler: configurationTextField)
                alert.addAction(UIAlertAction(title: "Change BPM (data may be lost)", style: UIAlertActionStyle.default, handler:{ (UIAlertAction) in
                    let newBPM = Int((alert.textFields?.first?.text)!)
                    if (newBPM! >= 50 && newBPM! <= 300) {
                        self.mainScreen?.delegate?.toolbarEvent(event: .changedBPM(Double(newBPM!)))
                        self.projectBPMLbl.text = "\(String(describing: self.mainScreen!.dataSource?.getProjectBPM())) BPM"
                    } else {
                        let alarm = UIAlertController(title: "BPM", message: "BPM invalid", preferredStyle: UIAlertControllerStyle.alert)
                        alarm.addAction(UIKit.UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in }))
                        self.present(alarm, animated: true, completion: nil)
                    }
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler:{ (UIAlertAction) in }))
                self.present(alert, animated: true, completion: nil)

            // change samplerate
            case 3:
                let alarm = UIAlertController(title: "Samplerate", message: "For now, changing the samplerate is not supported", preferredStyle: UIAlertControllerStyle.alert)
                alarm.addAction(UIKit.UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in }))
                self.present(alarm, animated: true, completion: nil)
            // show how much project takes
            case 4:
                break
            // delete project
            case 5:
                mainScreen?.delegate?.toolbarEvent(event: .stop)
                let refreshAlert = UIAlertController(title: "Delete", message: "Are you sure you want to delete this project?", preferredStyle: UIAlertControllerStyle.alert)
                refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                    // TODO delete project
                }))
                refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in}))
                present(refreshAlert, animated: true, completion: nil)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                print(AVAudioSession.sharedInstance().currentRoute.outputs)
                break
            case 1:
                break
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                break
            case 1:
                break
            default:
                break
            }
        default:
            break
        }
    }

    class InputStuff: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            if let inputs = AVAudioSession.sharedInstance().inputDataSources {
                return inputs.count
            } else {
                return 0
            }
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            if let inputs = AVAudioSession.sharedInstance().inputDataSources {
                return inputs[row].dataSourceName
            } else {
                return "Error"
            }
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            do {
                try AVAudioSession.sharedInstance().setInputDataSource(AVAudioSession.sharedInstance().inputDataSources![row])
            } catch {
                print("damn error changed input device")
            }
        }

        func currentValue() -> Int {
            if let inputs = AVAudioSession.sharedInstance().inputDataSources {
                if let inputCurrent = AVAudioSession.sharedInstance().inputDataSource {
                    return inputs.index(of: inputCurrent)!
                } else {
                    return 0
                }
            } else {
                return 0
            }
        }
    }

    class OutputStuff: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {

        var outputs = [("Headphones (when plugged in)", {
                            do {
                                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.none)
                            } catch let e {
                                print(e)
                            }
                        }),
                       ("Speaker", {
                            do {
                                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
                                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
                            } catch let e {
                                print(e)
                            }
                       })]

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return outputs.count
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return outputs[row].0
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            outputs[row].1()
        }

        func currentValue() -> Int {
            if AVAudioSession.sharedInstance().currentRoute.outputs[0].uid == "Speaker" {
                return 1
            } else {
                return 0
            }
        }
    }


    class MetronomeAudioStyle: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {

        var audioStyle = ["Off", "Cowbell", "BeepBoop"]

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return audioStyle.count
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return audioStyle[row]
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            //TODO
        }
    }

    class MetronomeVisualStyle: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {

        var visualStyle = ["Off", "Blinking background", "Flashlight", "Vibrate"]

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return visualStyle.count
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return visualStyle[row]
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            //TODO
        }
    }
}
