//
//  VibratorMSound.swift
//  Songwriter Studio Pro
//
//  Created by Modestas Valauskas on 29.07.15.
//  Copyright (c) 2015 ModestasV Studios. All rights reserved.
//

import AudioToolbox
import Foundation

class MetronomeSoundVibrate: MetronomeSound {
    func playMetronome(_ tick: Int) {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
}
