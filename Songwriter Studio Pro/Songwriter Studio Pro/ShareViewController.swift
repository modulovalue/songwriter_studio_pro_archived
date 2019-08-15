//
//  ShareViewController.swift
//  SongwriterStudioPro
//
//  Created by Modestas Valauskas on 13.12.17.
//  Copyright © 2017 MV. All rights reserved.
//

import Foundation
import UIKit

class ShareViewController: UIViewController {

    var projectManager: ProjectManagerProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func aiffbutton(_ sender: Any) {
        print("shareaiff")
    }

    @IBAction func mp3button(_ sender: Any) {
        print("sharemp3")
    }

    @IBAction func wavbutton(_ sender: Any) {
        print("sharewav")
    }

    @IBAction func shareLinkButton(_ sender: Any) {
        print("sharelink")
    }

}
