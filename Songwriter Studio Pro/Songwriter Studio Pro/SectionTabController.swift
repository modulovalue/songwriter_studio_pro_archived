//
//  SectionTabController.swift
//  SongwriterStudioPro
//
//  Created by Modestas Valauskas on 18.12.17.
//  Copyright © 2017 MV. All rights reserved.
//

import Foundation
import UIKit

class SectionTabController: UITableViewController {

    @IBOutlet weak var lblBarSteps: UILabel!

    lazy var projectManager: ProjectManager? = (navigationController?.tabBarController as! SettingsView).projectManager as? ProjectManager

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI()
    }

    func updateUI() {
        if projectManager?.sectionBarSteps() == .incremental {
            lblBarSteps.text = "Incremental"
        } else if projectManager?.sectionBarSteps() == .double {
            lblBarSteps.text = "2x"
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let manager = projectManager {
            switch indexPath.section {
            case 0:
                if manager.sectionBarSteps() == .incremental {
                    manager.globalSettings(.sectionBarSteps(.double))
                } else if manager.sectionBarSteps() == .double {
                    manager.globalSettings(.sectionBarSteps(.incremental))
                }
                updateUI()
            default:
                break
            }
        } else {
            print("error")
        }
    }

    @IBAction func showMenu(_ sender: Any) {
        (navigationController?.tabBarController as! SettingsView).menu()
    }

}

