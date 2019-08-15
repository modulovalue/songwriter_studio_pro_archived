//
//  SRecorder.swift
//  SongwriterStudioPro
//
//  Created by Modestas Valauskas on 27.03.17.
//  Copyright © 2017 MV. All rights reserved.
//

import Foundation
import AudioKit

class SRecorder: NSObject {

    // RECORDING TEST
//    var recordingSession : AVAudioSession!
//    var audioRecorder    : AVAudioRecorder!
//    var settings         = [String : Int]()

    var mainScreen: MainScreen
    var isRecording: Bool = false {
        didSet {
            // TODO
            mainScreen.scrollViewMain.mode(isRecording: isRecording)
        }
    }

    init(mainScreen: MainScreen) {
        self.mainScreen = mainScreen
    }

    func record() {
 //       recordingSession = AVAudioSession.sharedInstance()
//        do {
//            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
//            try recordingSession.setActive(true)
//            recordingSession.requestRecordPermission() { [unowned self] allowed in
//                DispatchQueue.main.async {
//                    if allowed {
//                        print("Allow")
//                    } else {
//                        print("Dont Allow")
//                    }
//                }
//            }
//        } catch {
//            print("failed to record!")
//        }
//
//        // Audio Settings
//
//        settings = [
//            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//            AVSampleRateKey: 44100,
//            AVNumberOfChannelsKey: 1,
//            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//        ]
//
    }

}

extension SRecorder: RecordDelegate {
    func startRecording() {
        isRecording = true;
        //        let audioSession = AVAudioSession.sharedInstance()
        //        do {
        //            audioRecorder = try AVAudioRecorder(url: Sound.directoryURL(name: "sounddabomb.m4a") as! URL,
        //                                                settings: settings)
        //            audioRecorder.delegate = self
        //            audioRecorder.prepareToRecord()
        //        } catch {
        //            audioRecorder = nil
        //            print("Somthing Wrong.")
        //        }
        //        do {
        //            try audioSession.setActive(true)
        //            audioRecorder.record()
        //        } catch {
        //        }

    }
    func startOverdubRecording() {
        isRecording = true;
        //
        //        time.resumeTimer()
    }
    func stopRecording() {
        isRecording = false;
        //
        //        audioRecorder.stop()
    }
    func stopOverdubRecording() {
        isRecording = false;

        //
        //        time.pauseTimer()
    }
}

extension SRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
//        if !flag {
//            audioRecorder = nil
//            print("Somthing Wrong.")
//        }
    }
}


