import Foundation
import CoreAudio
import Accelerate
import AudioToolbox
import SSPWaveView
import SSPTimelineIndicator
import RxCocoa
import RxSwift
import AVFoundation

typealias Bars = Int
typealias SectionIndex = Int

@objc class Playlist: NSObject {

    private let disposeBag = DisposeBag()
    var overdubMode: Variable<OverdubMode> = Variable(.INITOVERDUBMODE)
    var liveVoiceActive: Variable<Bool>! = Variable(.LIVEVOICEACTIVE)
    var playMode: Variable<PlayMode> = Variable(.INITPLAYMODE)
    var metronomePlaying: Variable<Bool> = Variable(.INITMETRONOMEPLAYING)
    var outputState: Variable<SpeakerOutput> = Variable(.mute)
    var recordState: Variable<SpeakerOutput> = Variable(.mute)

    var uiCallbacks: PlaylistUICallbacks?
    var playback: SSPPlayback!
    var sectionArray: SectionArray!
    var audioManager: AudioManager!

    // To keep the playback running after stopping recording while playback was running when started
    var wasRunningOnRecordingStarted = false

    // reset to true when recording stops to avoid feebback loop on pullsamples
    @objc public var firstPull = 2

    func setupUICallback(uiCallback: PlaylistUICallbacks) {
        self.uiCallbacks = uiCallback
        uiCallbacks?.callSectionUIEvent(.setBarsAt(0, .STARTBARS))
        sectionArray = SectionArray(playlist: self, firstSectionBars: .STARTBARS)
        playback = SSPPlayback(delegate: self as SSPPlaybackDelegate, dataSource: self as SSPPlaybackDataSource)
        playback.setupPlayback()
        playback.getSamplingRateObservable().asObservable()
            .subscribe(onNext: { sampleRate in self.uiCallbacks?.callUIEvent(.newSamplerate(sampleRate)) })
            .disposed(by: disposeBag)
        playback.getBPMObservable().asObservable()
            .subscribe(onNext: { bpm in self.uiCallbacks?.callUIEvent(.newBPM(bpm)) })
            .disposed(by: disposeBag)
        audioManager = AudioManager(callback: self as AudioManagerTrackUpdateCallback)
        audioManager.addTrack(sampleSize: Int(getSectionTime(index: 0).end))
        playMode.asObservable()
            .subscribe(onNext: { value in self.uiCallbacks?.callUIEvent(.modeSetTo(value))})
            .disposed(by: disposeBag)
        liveVoiceActive.asObservable()
            .subscribe(onNext: { value in self.uiCallbacks?.callUIEvent(.setLiveVoiceActive(value))})
            .disposed(by: disposeBag)
        metronomePlaying.asObservable()
            .subscribe(onNext: { value in self.uiCallbacks?.callUIEvent(.metronomeSetTo(value))})
            .disposed(by: disposeBag)
        outputState.asObservable()
            .subscribe(onNext: { value in setSpeakerState(value.rawValue)})
            .disposed(by: disposeBag)
        recordState.asObservable()
            .subscribe(onNext: { value in setRecordState(value.rawValue)})
            .disposed(by: disposeBag)
        overdubMode.asObservable()
            .subscribe(onNext: { value in
                self.uiCallbacks?.callUIEvent(.setOverdubMode(value))
                switch value {
                case .replace:
                    self.recordState.value = .mic
                case .add:
                    self.recordState.value = .recordingAndMic
                }
            }).disposed(by: disposeBag)
        initSampling()
        startSample(self)
    }

    // Code for "AudioUnitsAccess.m"
    @objc func getSampleRate() -> Float64 {
        return playback.getSamplingRate()
    }

    @objc public func pushSamples(samples: UnsafePointer<Float32>, size: Int) {
        playback.pushSamples(size: size)

        if !playback.getIsPaused() {
            let samplesArray = Array(UnsafeBufferPointer(start: samples, count: size))
//
//            var real = [Double](input)
//            var imaginary = [Double](repeating: 0.0, count: input.count)
//            var splitComplex = DSPDoubleSplitComplex(realp: &real, imagp: &imaginary)
//
//            let length = vDSP_Length(floor(log2(Float(input.count))))
//            let radix = FFTRadix(kFFTRadix2)
//            let weights = vDSP_create_fftsetupD(length, radix)
//            vDSP_fft_zipD(weights!, &splitComplex, 1, length, FFTDirection(FFT_FORWARD))
//
//            var magnitudes = [Double](repeating: 0.0, count: input.count)
//            vDSP_zvmagsD(&splitComplex, 1, &magnitudes, 1, vDSP_Length(input.count))
//
//            var normalizedMagnitudes = [Double](repeating: 0.0, count: input.count)
//            vDSP_vsmulD(sqrt(magnitudes), 1, [2.0 / Double(input.count)], &normalizedMagnitudes, 1, vDSP_Length(input.count))
//            
//            vDSP_destroy_fftsetupD(weights)
//            
//            return normalizedMagnitudes
//

            let curTime = playback.getTimeFor(atWhere: .currentTime)
            let selectedSectionIndex = sectionArray.selectedIndex()
            if playMode.value == .song {
                sectionArray.sectionArray.enumerated().forEach({ index, _ in
                    let t = getSectionTime(index: index)
                    if curTime >= t.begin && curTime < t.end {
                        uiCallbacks?.callSectionUIEvent(
                            .setScrobbleAt(
                                index,
                                (Double(Double(curTime - t.begin) / Double(t.end - t.begin) ))
                            )
                        )
                    }
                })
            } else if playMode.value == .section {
                let t = getSectionTime(index: selectedSectionIndex)
                uiCallbacks?.callSectionUIEvent(
                    .setScrobbleAt(
                        sectionArray.selectedIndex(),
                        (Double(Double(curTime) / Double(t.end - t.begin) ))
                    )
                )
            }
            if playback.getIsRecording() && !playback.getIsPaused() {
                audioManager.pushSamples(samples: samplesArray, currentTime: curTime, playMode: playMode.value, index: selectedSectionIndex)
            }
        }
    }

    @objc public func pullSamples(size: Int) -> UnsafePointer<Float32> {
        updateAudioState()
        return UnsafePointer(audioManager.getSamplesForNext(size: size, currentTime: playback.getTimeFor(atWhere: .currentTime), playMode: playMode.value, index: sectionArray.selectedIndex()))
    }

    // ------------------------------------------------

    func updateAudioState() {
        // Mute Output when playback is Paused
        if playback.getIsPaused() {
            outputState.value = .mute
        } else {
            // Determine output whether only Mic/RecordingAndMix/Mute or only play therecording
            if playback.getIsRecording() {
                if liveVoiceActive.value {
                    if overdubMode.value == .replace {
                        outputState.value = .mic
                    } else {
                        outputState.value = .recordingAndMic
                    }
                } else {
                    outputState.value = .mute
                }
            } else {
                outputState.value = .recording
            }
            // Determine whether to record the mix or the recording and mic oder to record nothing
            if playback.getIsRecording() {
                if overdubMode.value == .replace {
                    recordState.value = .mic
                } else {
                    recordState.value = .recordingAndMic
                }
            } else {
                recordState.value = .mute
            }
        }
    }

    func getSectionTime(index: Int) -> (begin: Int64, end: Int64) {
        var sectionEndTime: Int64 = 0
        var sectionBeginTime: Int64 = 0
        for i in 0...index {
            sectionBeginTime = sectionEndTime
            sectionEndTime += playback.getTimeFor(atWhere: .beat, amount: sectionArray.sectionArray[i].sectionBars * 4)
        }
        return (begin: sectionBeginTime, end: sectionEndTime)
    }

    var time = 10;

    var waveIndicatorMoved = false /* needed for differentiation @ waveViewTouchesEnded */

}

extension Playlist: AudioManagerTrackUpdateCallback {

    func update(samples: [Float32], trackIndex: Int) {
        let howManyBands = sectionArray.sectionArray[trackIndex].sectionBars * Int.beatsPerBar * Int.WAVEVIEWRESOLUTIONPERBEAT
        let arr = samplesToBandArray(samples: samples, bandCount: howManyBands) // TO-DO Maybe obtimize further
        uiCallbacks?.callSectionUIEvent(.setWaveViewBands(trackIndex, arr))
    }

    func updateBandsLast(trackIndex: Int, deltaBars: Int) {
        let deltaBands: Int = Int.WAVEVIEWRESOLUTIONPERBEAT * Int.beatsPerBar * deltaBars
        if deltaBars > 0 {
            let newBands = Array(repeatElement(Band(magnitude: Float32(0), color: .waveViewNotRecordingBandColor), count: deltaBands))
            uiCallbacks?.callSectionUIEvent(.addEmptyBands(trackIndex, newBands))
        } else if deltaBars < 0 {
            uiCallbacks?.callSectionUIEvent(.removeBands(trackIndex, abs(deltaBands)))
        }
    }

    func updateRange(samples: [Float32], trackIndex: Int, range: CountableRange<Int>) {

        let howManyBands = sectionArray.sectionArray[trackIndex].sectionBars * Int.beatsPerBar * Int.WAVEVIEWRESOLUTIONPERBEAT
        var arr: [Band] = []
        var samplesArr: [[Float32]] = []
        var bandUpdateRange: CountableRange<Int>!
        let pivot = samples.count / howManyBands
        let start = range.lowerBound
        var startBand: Int! = nil
        var lastBand: Int! = nil

        (0..<howManyBands).forEach{ i in
            let r = ((pivot * i)..<pivot * (i + 1))
            if r.lowerBound <= start && r.upperBound > start {
                for indice in r {
                    if startBand == nil {
                        startBand = i
                    }
                    lastBand = i
                    if samplesArr.count <= i - startBand {
                        samplesArr.append([])
                    }
                    samplesArr[i - startBand].append(samples[indice])
                }
                var maximum: Float = 0
                vDSP_maxmgv(Array(samples[r]), 1, &maximum, vDSP_Length(r.count) )
                arr.append(Band(magnitude: maximum, color: .waveViewRecordingBandColor))
                ////            var rms: Float = 0
                ////            let count = vDSP_Length(samplesArr.count)
                ////            vDSP_rmsqv(newBandSamples, 1, &rms, count)
                ////            arr.append(Band(magnitude: rms, color: .waveViewRecordingBandColor))
            }
        }

        if startBand == nil && lastBand == nil {
            return
        } else {
            bandUpdateRange = startBand!..<lastBand! + 1
        }

        assert(arr.count == bandUpdateRange.upperBound - bandUpdateRange.lowerBound)
        uiCallbacks?.callSectionUIEvent(.updateBands(trackIndex, bandUpdateRange, arr))
    }

    func samplesToBandArray(samples: [Float32], bandCount: Int) -> [Band] {
        var bands: [Band] = []
        let pivot = samples.count / bandCount
        let range = 1
        for i in 0..<bandCount {
            var temp: Float32 = 0
            let r = stride(from: (pivot * i), to: pivot * (i + 1), by: range)
            for sample in r {
                if abs(samples[sample]) > temp {
                    temp = abs(samples[sample])
                }
            }
            bands.append(Band(magnitude: temp, color: .waveViewNotRecordingBandColor))
        }
        return bands
    }
}

extension Playlist: SSPPlaybackDelegate {
    func newTimeInSamples(samples: Int64) {
        self.uiCallbacks?.callUIEvent(.newTimeInSamples(samples, length: activePlayModeLengthInSamples()))
    }

    func play(_ playing: Bool) {
        if playing {
            startSample(self)
        } else {
            stopSample()
        }
        uiCallbacks?.callUIEvent( playing ? .didStartPlaying : .didStartPause)
    }

    func stop() {
        stopSample()
        uiCallbacks?.callUIEvent(.didStartStop)
    }
}

extension Playlist: SSPPlaybackDataSource {
    func activePlayModeLengthInSamples() -> Int64 {
        let playmodeIsSection = playMode.value == .section
        if (playmodeIsSection) {
            return playback.getTimeFor(atWhere: .beat, amount: sectionArray.selectedSection.sectionBars * 4)
        } else {
            return sectionArray.sectionArray.reduce(0, { $0 + playback.getTimeFor(atWhere: .beat, amount: $1.sectionBars * 4) })
        }
    }
}

// handle MainScreen UI Events
extension Playlist: MainScreenDelegate, MainScreenDataSource {

    // handle toolbar events from the toolbar
    func toolbarEvent(event: UIEvents.Toolbar) {
        switch event {
        case .toggleMetronome:
            metronomePlaying.value = !metronomePlaying.value
        case .windWithDelta(let delta):
            playback.windWithDelta(delta: delta)
        case .stop:
            playback.stop()
        case .togglePlay:
            playback.togglePlay()
        case .mode:
            let curTime = playback.getTimeFor(atWhere: .currentTime) as Int64
            if playMode.value == .section {
                playMode.value = .song
                playback.setTime(newCurrentTimeInSamples: getSectionTime(index: sectionArray.selectedIndex()).begin + curTime)
            } else {
                playMode.value = .section
                playback.setTime(newCurrentTimeInSamples: curTime - getSectionTime(index: audioManager.getAffectedTrackIndex(time: Int(curTime))).begin )
            }
        case .addSectionAfter(let afterSectionIndex):
            sectionArray.addSectionAfter(afterSectionIndex: afterSectionIndex)
            let sectionTime = getSectionTime(index: sectionArray.sectionArray.last!.index(sectionArray.sectionArray))
            audioManager.addTrack(sampleSize: Int(sectionTime.end) - Int(sectionTime.begin))
        case .forceTimeUpdate:
            uiCallbacks?.callUIEvent(.newTimeInSamples(playback.getTimeFor(atWhere: .currentTime), length: activePlayModeLengthInSamples()))
        case .liveVoice:
            liveVoiceActive.value = !liveVoiceActive.value
        case .overdubMode:
            switch self.overdubMode.value {
            case .replace:
                overdubMode.value = .add
            case .add:
                overdubMode.value = .replace
            }
        case .changedBPM(let value):
            playback.setBPM(value)
        }
    }

    // handle recording events from the record button
    func recordingWithEvent(event: UIEvents.Recording) {
        var isRecording = true
        switch event {
        case .started:
            wasRunningOnRecordingStarted = !playback.getIsPaused()
            firstPull = 2
            isRecording = true
        case .startedOverdub:
            wasRunningOnRecordingStarted = !playback.getIsPaused()
            firstPull = 2
            if playback.getIsPaused() {
                toolbarEvent(event: .togglePlay)
            }
            isRecording = true
        case .stopped:
            isRecording = false
        case .stoppedOverdub:
            isRecording = false
            if !wasRunningOnRecordingStarted {
                playback.setPaused(paused: true)
            }
        }
        playback.setRecording(isRecording: isRecording)
        uiCallbacks?.callUIEvent(.isRecording(playback.getIsRecording()))
    }

    //handle sectionEvents from the section @ sectionIndex
    func sectionEvent(sectionEvent: SectionEvents.Section, sectionIndex: SectionIndex) {
        switch sectionEvent {
        case .addBarDelta( _, let delta):
            let differenceInBars = sectionArray.barChangeDelta(sectionIndex: sectionIndex, delta: delta)
            uiCallbacks?.callSectionUIEvent(.setBarsAt(sectionIndex, sectionArray.sectionArray[sectionIndex].sectionBars))
            let sectionTime = getSectionTime(index: sectionIndex)
            audioManager
                .updateTrackDuration(
                    index: sectionIndex,
                    newDuration: sectionTime.end - sectionTime.begin,
                    deltaBars: differenceInBars)
        case .removeSection:
            uiCallbacks?.callSectionUIEvent(.removeAt(sectionIndex))
            sectionArray.removeSection(sectionIndex: sectionIndex)
            audioManager.removeTrack(sectionIndex: sectionIndex)
        case .historyBack( _):
            // TODO maybe remove?
            print("historyBack \(sectionIndex)")
        case .historyForward( _):
            // TODO maybe remove?
            print("historyForward \(sectionIndex)")
        case .shareSection( _):
            audioManager.shareSection(sectionIndex, { url in 
                let url: [Any] = [url]
                let avc = UIActivityViewController(activityItems: url, applicationActivities: nil)
                uiCallbacks?.presentThis({
                    $0.present(avc, animated: true)
                })
            })
        }
    }
    
    func sectionTouchEvent(touchEvent: SectionEvents.Touch, sectionIndex: SectionIndex, value: Double) {
        switch touchEvent {
        case .startedTimeline:
            sectionArray.setSelectedSection(index: sectionIndex)
            sectionTouchEvent(touchEvent: .movedTimeline, sectionIndex: sectionIndex, value: value)
        case .movedTimeline:
            sectionArray.setSelectedSection(index: sectionIndex)
            let sTime = getSectionTime(index: sectionIndex)
            let beatParts = 1.0 / Double(sectionArray.sectionArray[sectionIndex].sectionBars * 4)
            let val = round(value / beatParts) / Double(sectionArray.sectionArray[sectionIndex].sectionBars * 4)
            let newTime = Float(sTime.end - sTime.begin) * Float(val)
            playback.setTime(newCurrentTimeInSamples: Int64(newTime) + ((playMode.value == .song) ? sTime.begin : 0))
            uiCallbacks?.callSectionUIEvent(.setScrobbleAt(sectionIndex, val))
            stopSample()
            break
        case .movedWaveView:
            sectionArray.setSelectedSection(index: sectionIndex)
            let sTime = getSectionTime(index: sectionIndex)
            let newTime = Float(sTime.end - sTime.begin) * Float(value)
            playback.setTime(newCurrentTimeInSamples: Int64(newTime) + ((playMode.value == .song) ? sTime.begin : 0))
            uiCallbacks?.callSectionUIEvent(.setScrobbleAt(sectionIndex, value))
            waveIndicatorMoved = true
            stopSample()
        case .endedSection:
            sectionArray.setSelectedSection(index: sectionIndex)
            startSample(self)
        case .endedWaveView:
            sectionArray.setSelectedSection(index: sectionIndex)
            if !waveIndicatorMoved {
                sectionTouchEvent(touchEvent: .movedWaveView, sectionIndex: sectionIndex, value: value)
            }
            waveIndicatorMoved = false
            startSample(self)
        case .endedTimeline:
            startSample(self)
        default:
            break
        }
    }

    func setPlaylistUICallbacks(uiCallback: PlaylistUICallbacks) {
        setupUICallback(uiCallback: uiCallback)
    }

    func getProjectName() -> String {
        return "todo"
    }

    func getProjectBPM() -> Double {
        return playback.getBPM()
    }

    func getProjectSamplingRate() -> Double {
        return playback.getSamplingRate()
    }

    func getProjectSectionCount() -> Int {
        return sectionArray.sectionArray.count
    }

}

enum UIEvents {
    enum Toolbar {
        // the metronome was toggled
        case toggleMetronome
        // playback was winded with the delta (can be positive and negative, in Beats
        case windWithDelta(Int)
        // playback was stopped
        case stop
        // playback was toggled
        case togglePlay
        // the playback mode was changed
        case mode
        // the time label was clicked
        case forceTimeUpdate
        // section was added after the Int
        case addSectionAfter(Int)
        // live voice was toggled
        case liveVoice
        // the overdub mode was toggled
        case overdubMode
        // changed bpm
        case changedBPM(Double)
    }
    enum Recording {
        // recording started (short tap on the record button)
        case started
        // the recording button is held -> starts the "overdub" mode (wrong name but its the hold mode)
        case startedOverdub
        // recording stopped
        case stopped
        // "overdub" recording stopped (recording button was held and then let go)
        case stoppedOverdub
    }
}

public enum PlayMode {
    // the complete song plays, every section after antoher
    case song
    // only the selected sections plays and loops
    case section
}

public enum OverdubMode {
    // when recorded, old recording is deleted and replaced with new
    case replace
    // when recorded, old recording is added with the new one
    case add
}

enum SpeakerOutput: Int32 {
    case
    mute = 0,
    mic = 1,
    recording = 2,
    recordingAndMic = 3
}
enum RecordOutput: Int32 {
    case
    mute = 0,
    mic = 1,
    recording = 2,
    recordingAndMic = 3
}

protocol PlaylistUICallbacks: class {
    func callUIEvent(_ event: UIManipulationEvent.UI)
    func callSectionUIEvent(_ event: UIManipulationEvent.Section)
    func presentThis(_ doThat: (UIViewController) -> Void)
}
