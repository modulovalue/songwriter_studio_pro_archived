//
//  AboutTabController.swift
//  SongwriterStudioPro
//
//  Created by Modestas Valauskas on 18.12.17.
//  Copyright © 2017 MV. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class AboutTabController: UITableViewController, MFMailComposeViewControllerDelegate  {

    var projectManager: ProjectManagerProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        projectManager = (navigationController?.tabBarController as! SettingsView).projectManager
    }

    @IBAction func showMenu(_ sender: Any) {
        (navigationController?.tabBarController as! SettingsView).menu()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        switch indexPath.row {
        case 0:
            goToHomepage()
        case 1:
            goToTutorials()
        case 2:
            goToContact()
        case 3:
            goToRate()
        case 4:
            versionClicked()
        default:
            print("row not implemented @ AboutTabController")
        }
    }

    func goToHomepage() {
        let url = URL(string: "http://www.songwriterstudiopro.com")!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                print("Open url : \(success)")
            })
        }
    }

    func goToTutorials() {
        let url = URL(string: "http://www.songwriterstudiopro.com/tutorials")!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                print("Open url : \(success)")
            })
        }
    }

    func goToContact() {
        if !MFMailComposeViewController.canSendMail() {
            let alarm = UIAlertController(title: "There was an error.", message: "I'm sorry, please try again later.", preferredStyle: UIAlertControllerStyle.alert)
            alarm.addAction(UIKit.UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in }))
            self.present(alarm, animated: true, completion: nil)
            return
        } else {
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            composeVC.setToRecipients(["mod-val@web.de"])
            composeVC.setSubject("Songwriter Studio Pro: contact")
            composeVC.setMessageBody("", isHTML: false)
            self.present(composeVC, animated: true, completion: nil)
        }
    }

    func goToRate() {
        // TODO add app id
        let url  = NSURL(string: "itms-apps://itunes.apple.com/app/id10249qerqe41703")
        if UIApplication.shared.canOpenURL(url! as URL) == true {
            UIApplication.shared.open(url! as URL, options: [:], completionHandler: nil)
        }
    }

    func versionClicked() {
        let alarm = UIAlertController(title: "Thank you for using Songwriter Studio Pro", message: "I hope you're having a superb experience. You can contact me anytime if not and I will try to help you. \n❤️", preferredStyle: UIAlertControllerStyle.alert)
        alarm.addAction(UIKit.UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in }))
        self.present(alarm, animated: true, completion: nil)
        return
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
    }

}
