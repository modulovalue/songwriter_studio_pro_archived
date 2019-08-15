//
//  Project.swift
//  SongwriterStudioPro
//
//  Created by Modestas Valauskas on 16.12.17.
//  Copyright © 2017 MV. All rights reserved.
//

import Foundation
import Disk

struct ProjectInformation: Codable {
    var name: String
    var initBPM: Double
    var audioPath: String?
    var projectDataPath: String?
}
