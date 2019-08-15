import Foundation
import RxSwift
import RxCocoa

class SSPPlayback {

    weak var delegate: SSPPlaybackDelegate!
    public var dataSource: SSPPlaybackDataSource!

    private let disposeBag = DisposeBag()
    var timeAtPlayInSamples: Int64 = 0 {
        didSet {
            delegate.newTimeInSamples(samples: timeAtPlayInSamples)
        }
    }
    private var bpm: Variable<Double> = Variable(.INITBPM)
    private var samplingRate: Variable<Double> = Variable(.SAMPLERATE)
    private var paused: Variable<Bool> = Variable(true)
    private var isRecording: Variable<Bool> = Variable(false)

    public init (delegate: SSPPlaybackDelegate, dataSource: SSPPlaybackDataSource) {
        self.delegate = delegate
        self.dataSource = dataSource
    }

    public func setupPlayback() {
        paused
            .asObservable()
            .subscribe(onNext: { pause in self.delegate.play(!pause)})
            .disposed(by: disposeBag)

        isRecording
            .asObservable()
            .subscribe(onNext: { isRecording in print("is now recording: \(isRecording)") })
            .disposed(by: disposeBag)

        bpm.asObservable()
            .subscribe(onNext: { bpm in print("new BPM \(bpm)") })
            .disposed(by: disposeBag)

        stop()
    }

    func setTime(newCurrentTimeInSamples: Int64) {
        self.timeAtPlayInSamples = newCurrentTimeInSamples >= dataSource.activePlayModeLengthInSamples() ? 0 : newCurrentTimeInSamples
    }

    func togglePlay() {
        paused.value = !paused.value
    }

    func stop() {
        timeAtPlayInSamples = 0
        paused.value = true
        delegate.play(false)
        delegate.stop()
    }

    func windWithDelta(delta: Int) {
        let tempTime = timeAtPlayInSamples + (windingStepSizeToSampleSpeed() * Int64(delta))
        let estimatedNumber = round(Double(tempTime) / Double(windingStepSizeToSampleSpeed() * abs(Int64(delta))))
        let newTime = Int64(round(60 / bpm.value * samplingRate.value * estimatedNumber))
        if delta < 0 {
            timeAtPlayInSamples = tempTime <= 0 ? 0 : newTime
        } else if delta > 0 {
            timeAtPlayInSamples = tempTime >= dataSource.activePlayModeLengthInSamples() * Int64(delta) ? 0 : newTime
        }
    }

    func pushSamples(size: Int) {
        if !paused.value {
            let tempTime = self.timeAtPlayInSamples + Int64(size)
            let length = self.dataSource.activePlayModeLengthInSamples()
            if tempTime > length {
                let newTime = tempTime % length
                self.timeAtPlayInSamples = newTime
            } else {
                self.timeAtPlayInSamples = tempTime
            }
        }
    }

    func windingStepSizeToSampleSpeed() -> Int64 {
        return Int64(round(60.0 / bpm.value * samplingRate.value * .WINDINGSTEPSIZEINQUARTERS))
    }

    public func getTimeFor(atWhere: AtWhere, amount: Int = 0) -> Int64 {
        switch atWhere {
        case .beat:
            return Int64(round(60.0 / bpm.value * samplingRate.value * Double(amount)))
        case .currentTime:
            if timeAtPlayInSamples >= dataSource.activePlayModeLengthInSamples() {
                timeAtPlayInSamples = 0
            }
            return timeAtPlayInSamples
        case .endOfCurrentPlayMode:
            return dataSource.activePlayModeLengthInSamples()
        }
    }

    func setRecording(isRecording: Bool) {
        self.isRecording.value = isRecording
    }

    func setPaused(paused: Bool) {
        self.paused.value = paused
    }

    func getBPM() -> Double {
        return bpm.value
    }

    func setBPM(_ bpm: Double) {
        self.bpm.value = bpm
    }

    func getBPMObservable() -> Variable<Double> {
        return bpm
    }

    func getIsRecording() -> Bool {
        return isRecording.value
    }

    func getIsPaused() -> Bool {
        return paused.value
    }

    func getSamplingRate() -> Double {
        return samplingRate.value
    }

    func getSamplingRateObservable() -> Variable<Double> {
        return samplingRate
    }
}

public protocol SSPPlaybackDataSource: class {
    func activePlayModeLengthInSamples() -> Int64
}

public protocol SSPPlaybackDelegate: class {
    func newTimeInSamples(samples: Int64)
    func play(_ playing: Bool)
    func stop()
}

public enum AtWhere {
    case endOfCurrentPlayMode
    case currentTime
    case beat
}
