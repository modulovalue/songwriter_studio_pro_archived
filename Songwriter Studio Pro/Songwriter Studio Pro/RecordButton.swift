import Foundation
import UIKit

class RecordButton: UIButton {

    private var tapBool: Bool = false
    private var recording: Bool = false
    private var timer: Timer!

    var executeEvent: ((UIEvents.Recording) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if recording == false {
            tapBool = true
            startTapTimer()
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if recording == false {
            if tapBool { // TAP Ended
                executeEvent?(.started)
                recordingWithEvent(event: .started)
                recording = true
            } else { // OD Ended
                executeEvent?(.stoppedOverdub)
                recordingWithEvent(event: .stoppedOverdub)
            }
        } else {
            executeEvent?(.stopped)
            recordingWithEvent(event: .stopped)
            recording = false
        }
        tapBool = false
        timer.invalidate()
    }

    fileprivate func startTapTimer() {
        self.timer = Timer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(RecordButton.calculate),
            userInfo: nil,
            repeats: false)
        RunLoop.current.add(self.timer, forMode: RunLoopMode.commonModes)
    }

    @objc
    func calculate() {
        if tapBool == true {
            executeEvent?(.startedOverdub)
            recordingWithEvent(event: .startedOverdub)
        }
        tapBool = false
    }

    func recordingWithEvent(event: UIEvents.Recording) {
        self.transform = CGAffineTransform(scaleX: 0, y: 0)
        let animationDuration: Double!
        let transitionDuration: Double!
        let transitionImage: UIImage!
        let scale: CGFloat!
        switch event {
        case .started:
            animationDuration = 0.13
            transitionDuration = 0.15
            transitionImage = #imageLiteral(resourceName: "recordingstart")
            scale = 1.0
        case .startedOverdub:
            animationDuration = 0.13
            transitionDuration = 0.15
            transitionImage = #imageLiteral(resourceName: "overdub")
            scale = 1.0
        case .stopped:
            animationDuration = 0.2
            transitionDuration = 0.15
            transitionImage = #imageLiteral(resourceName: "record")
            scale = 1.0
        case .stoppedOverdub:
            animationDuration = 0.2
            transitionDuration = 0.15
            transitionImage = #imageLiteral(resourceName: "record")
            scale = 1.0
        }

        UIView.animate(withDuration: animationDuration,
                       delay: 0.0,
                       options: [.curveEaseOut, .allowUserInteraction, .allowAnimatedContent],
                       animations: { self.transform = CGAffineTransform(scaleX: scale, y: scale) },
                       completion: nil)
        UIView.transition(with: imageView!,
                          duration: transitionDuration,
                          options: .transitionCrossDissolve,
                          animations: { self.setImage(transitionImage, for: UIControlState()) },
                          completion: nil)
    }
}
