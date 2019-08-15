//
//  ClickMSound1.swift
//  Songwriter Studio Pro
//
//  Created by Modestas Valauskas on 29.07.15.
//  Copyright (c) 2015 ModestasV Studios. All rights reserved.
//

import AudioToolbox
import Foundation

class MetronomeSoundLogic: MetronomeSound {

    var metronomeHigh: SystemSoundID = 0
    var metronomeLow: SystemSoundID = 1

    init() {
//        var soundURL = Bundle.main.url(forResource: "CLK_LOGIC2", withExtension: "wav")
//        AudioServicesCreateSystemSoundID(soundURL as! CFURL, &metronomeLow)
//        soundURL = Bundle.main.url(forResource: "CLK_LOGIC1", withExtension: "wav")
//        AudioServicesCreateSystemSoundID(soundURL as! CFURL, &metronomeHigh)
    }

    func playMetronome(_ tick: Int) {
        switch tick {
        case 0:
            AudioServicesPlaySystemSound(metronomeHigh)
        case 1:
            AudioServicesPlaySystemSound(metronomeLow)
        case 2:
            AudioServicesPlaySystemSound(metronomeLow)
        case 3:
            AudioServicesPlaySystemSound(metronomeLow)
        default:
            return
        }
    }
}
