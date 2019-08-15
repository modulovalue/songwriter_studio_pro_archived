//
//  ConvenienceTabController.swift
//  SongwriterStudioPro
//
//  Created by Modestas Valauskas on 18.12.17.
//  Copyright © 2017 MV. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class ConvenienceTabController: UITableViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var tripleTapToTapCell: UITableViewCell!

    lazy var projectManager: ProjectManager? = (navigationController?.tabBarController as! SettingsView).projectManager as? ProjectManager

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI()
    }

    func updateUI() {
        if (projectManager?.convenienceTripleTap())! {
            tripleTapToTapCell.accessoryType = .checkmark
        } else {
            tripleTapToTapCell.accessoryType = .none
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let manager = projectManager {
            switch indexPath.row {
            case 0:
                manager.globalSettings(.convenienceTripleTap(!manager.convenienceTripleTap()))
                updateUI()
            case 1:
                if !MFMailComposeViewController.canSendMail() {
                    let alarm = UIAlertController(title: "There was an error.", message: "I'm sorry, please try again later.", preferredStyle: UIAlertControllerStyle.alert)
                    alarm.addAction(UIKit.UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in }))
                    self.present(alarm, animated: true, completion: nil)
                    return
                } else {
                    let composeVC = MFMailComposeViewController()
                    composeVC.mailComposeDelegate = self
                    composeVC.setToRecipients(["mod-val@web.de"])
                    composeVC.setSubject("Songwriter Studio Pro: convenience feature suggestion")
                    composeVC.setMessageBody("", isHTML: false)
                    self.present(composeVC, animated: true, completion: nil)
                }
            default:
                break
            }
        } else {
            print("error")
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        if error != nil {
            let alarm = UIAlertController(title: "Thank you!", message: ":)", preferredStyle: UIAlertControllerStyle.alert)
            alarm.addAction(UIKit.UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in }))
            self.present(alarm, animated: true, completion: nil)
        } else {
            let alarm = UIAlertController(title: "Please try again", message: "", preferredStyle: UIAlertControllerStyle.alert)
            alarm.addAction(UIKit.UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in }))
            self.present(alarm, animated: true, completion: nil)
        }
        updateUI()
    }

    @IBAction func showMenu(_ sender: Any) {
        (navigationController?.tabBarController as! SettingsView).menu()
    }

}
