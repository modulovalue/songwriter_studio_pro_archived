//
//  AudioTabController.swift
//  SongwriterStudioPro
//
//  Created by Modestas Valauskas on 18.12.17.
//  Copyright © 2017 MV. All rights reserved.
//

import Foundation
import UIKit

class AudioTabController: UITableViewController {

    @IBOutlet weak var lblDefaultBpm: UILabel!

    lazy var projectManager: ProjectManager? = (navigationController?.tabBarController as! SettingsView).projectManager as? ProjectManager

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI()
    }

    func updateUI() {
        lblDefaultBpm.text = "\(projectManager!.audioDefaultBPM()) BPM"
    }

    @IBAction func showMenu(_ sender: Any) {
        (navigationController?.tabBarController as! SettingsView).menu()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let manager = projectManager {
            switch indexPath.section {
            case 0:
                getBPM {
                    manager.globalSettings(.audioDefaultBPM($0))
                    self.updateUI()
                }
            default:
                break
            }
        } else {
            print("error")
        }
    }

    func getBPM(bpm: @escaping (Double) -> Void) {
        func configurationTextFieldBPM(textField: UITextField!) {
            textField.text = "\(projectManager!.audioDefaultBPM())"
            textField.keyboardType = .numberPad
        }
        let alert = UIAlertController(title: "Choose the default BPM", message: "Please keep it between 50 and 300 \n70 - slow \n 110 - normal \n 140 - fast", preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField(configurationHandler: configurationTextFieldBPM)
        alert.addAction(UIAlertAction(title: "Choose", style: UIAlertActionStyle.default, handler:{ (UIAlertAction) in
            let newBPM = Double((alert.textFields?.first?.text)!)
            if newBPM != nil && newBPM! >= 50 && newBPM! <= 300 {
                bpm(newBPM!)
            } else {
                let alarm = UIAlertController(title: "Please choose a different BPM value", message: "BPM invalid", preferredStyle: UIAlertControllerStyle.alert)
                alarm.addAction(UIKit.UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in }))
                self.present(alarm, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler:{ (UIAlertAction) in }))
        self.present(alert, animated: true, completion: nil)
    }

}
