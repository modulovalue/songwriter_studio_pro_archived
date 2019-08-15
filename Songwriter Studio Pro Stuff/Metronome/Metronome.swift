//
//  Metronome.swift
//  SongwriterStudioPro
//
//  Created by Modestas Valauskas on 27.03.17.
//  Copyright © 2017 MV. All rights reserved.
//

import Foundation

class Metronome {
    var metronomeState: Bool = false {
        didSet {
            print("The value of myProperty changed from \(oldValue) to \(metronomeState)")
        }
    }
}
