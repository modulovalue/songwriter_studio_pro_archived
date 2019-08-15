import Foundation
import SSPTimelineIndicator
import SSPWaveView
import RxSwift
import RxCocoa

@IBDesignable class SSPSectionView: UIView {

    @IBOutlet weak var barLabel: UILabel!
    @IBOutlet weak var removeSectionBtn: UIButton!
    @IBOutlet weak var removeBarBtn: UIButton!
    @IBOutlet weak var addBarBtn: UIButton!
    @IBOutlet open var waveView: SSPWaveView!
    @IBOutlet weak var textView: UIView!
    @IBOutlet weak var chordView: UIView!
    @IBOutlet weak var indicator: SSPTimelineIndicator!
    @IBOutlet weak var historyBackBtn: UIButton!
    @IBOutlet weak var historyForwardBtn: UIButton!
    @IBOutlet weak var shareButton: UIButton!

    private let disposeBag = DisposeBag()

    private var event: ((SectionEvents.Section) -> Void)?
    private var touchEvent: ((SectionEvents.Touch, SSPSectionView, Set<UITouch>, UIEvent?) -> Void)?

    private func setCurrentView(currentView: Int) {
        waveView.isHidden = !(currentView <= 6)
        textView.isHidden = !(currentView == 7)
        chordView.isHidden = !(currentView == 8)
        setOtherLayer(layerNumber: currentView)
    }

    private func setOtherLayer(layerNumber: Int) {
        print("other layer \(layerNumber)")
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setup()
    }

    private func setup() {
        let nib = UINib(nibName: "Section", bundle: Bundle(for: type(of: self)))
        guard let view = nib.instantiate(withOwner: self, options: nil)[0] as? UIView else {
            print("failed loading Section nib")
            exit(1)
        }
        
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(view)
        waveView.backgroundColor = .waveViewBackgroundColor
        indicator.backgroundColor = .timelineBackgroundColor
        setCurrentView(currentView: .STARTINGSECTIONSEGMENTVIEW)

        addBarBtn.rx.tap.subscribe(onNext: { btn in
            self.event?(.addBarDelta(self, delta: 1))
        }).disposed(by: disposeBag)

        removeBarBtn.rx.tap.subscribe(onNext: { btn in
            self.event?(.addBarDelta(self, delta: -1))
        }).disposed(by: disposeBag)

        removeSectionBtn.rx.tap.subscribe(onNext: { btn in
            self.event?(.removeSection(self))
        }).disposed(by: disposeBag)

        shareButton.rx.tap.subscribe(onNext: { btn in
            self.event?(.shareSection(self))
        }).disposed(by: disposeBag)

        indicator.delegate = self as SSPTimelineIndicatorDelegate
        indicator.dataSource = self as SSPTimelineIndicatorDataSource
        waveView.delegate = self as SSPWaveViewDelegate
        waveView.dataSource = self as SSPWaveViewDataSource
    }

    public func doThis(_ event: SectionEvents.Public) {
        switch event {
        case .initDelegates(let event, let touch):
            self.event = event
            self.touchEvent = touch
        case .indicatorVisibilityHide(let isHidden):
            indicator.indicatorHidden = isHidden
            waveView.indicatorHidden = isHidden
        case .setWaveViewData(let bands):
            waveView.setBandData(bands: bands)
        case .appendBands(let bands):
            waveView.appendBands(bands: bands)
        case .removeBands(let bands):
            waveView.removeBands(amount: bands)
        case .updateBands(let range, let bands):
            waveView.updateBands(range: range, bands: bands)
        case .setBars(let bars):
            if bars == 1 {
                removeBarBtn.alpha = 0.10
                addBarBtn.isEnabled = true
                removeBarBtn.isEnabled = false
            } else if bars == .MAXBARS {
                addBarBtn.alpha = 0.10
                addBarBtn.isEnabled = false
                removeBarBtn.isEnabled = true
            } else {
                addBarBtn.alpha = 1
                removeBarBtn.alpha = 1
                addBarBtn.isEnabled = true
                removeBarBtn.isEnabled = true
            }
            barLabel.text = "\(bars)"
            indicator.bars = bars
        case .setRemovable(let canRemove):
            removeSectionBtn.isHidden = !canRemove
            removeSectionBtn.isEnabled = canRemove
        case .setScrobbleAt(let value):
            waveView.setScrobbleAt(value: value)
            indicator.setScrobbleAt(value: value)
        }
    }

    private func drawSectionOutline(selected: Bool) {
        let shadowAnim = CABasicAnimation()
        shadowAnim.keyPath = "shadowOpacity"
        shadowAnim.duration = 0.3
        shadowAnim.fromValue = 0

        layer.masksToBounds = false
        layer.shadowColor = #colorLiteral(red: 0.09802811593, green: 0.09804544598, blue: 0.09802217036, alpha: 1).cgColor
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shadowOffset = CGSize(width: 0.0, height: 8)
        layer.shadowRadius = 7

        let selectedOpacity: Float = 1
        let notselectedOpacity: Float = 0.1

        if selected {
            layer.shadowOpacity = selectedOpacity
            shadowAnim.fromValue = notselectedOpacity
            shadowAnim.toValue = selectedOpacity
        } else {
            layer.shadowOpacity = notselectedOpacity
            shadowAnim.fromValue = selectedOpacity
            shadowAnim.toValue = notselectedOpacity
        }

        layer.add(shadowAnim, forKey: "shadowOpacity")
    }

    @IBAction func sectionChooser(_ sender: UISegmentedControl) {
        setCurrentView(currentView: sender.selectedSegmentIndex)
    }

    @IBAction func historyBackAction(_ sender: Any) {
        event?(.historyBack(self))
    }

    @IBAction func historyForwardAction(_ sender: Any) {
        event?(.historyForward(self))
    }

    // to not redraw unselected everything it is marked as not selected
    var isSelected = false
    public func setSelected(selected: Bool) {
        if selected != isSelected {
            drawSectionOutline(selected: selected)
        }
        isSelected = selected
    }

    public func moveInSuperViewY(_ amount: CGFloat) {
        UIView.animate(withDuration: 0.5,
                       delay: 0.0,
                       options: [.curveEaseOut, .allowUserInteraction, .allowAnimatedContent],
                       animations: { self.frame.origin.y += amount },
                       completion: nil)
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchEvent?(.startedSection, self, touches, event)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchEvent?(.endedSection, self, touches, event)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchEvent?(.movedSection, self, touches, event)
    }
}

extension SSPSectionView: SSPWaveViewDelegate, SSPTimelineIndicatorDelegate {
    func waveViewTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, viewSize: CGSize) {
        touchEvent?(.endedWaveView, self, touches, event)
    }
    func waveViewTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, viewSize: CGSize) {
        touchEvent?(.movedWaveView, self, touches, event)
    }
    func waveViewTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, viewSize: CGSize) {
        touchEvent?(.startedWaveView, self, touches, event)
    }
    func timelineIndicatorTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, viewSize: CGSize) {
        touchEvent?(.endedTimeline, self, touches, event)
    }
    func timelineIndicatorTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, viewSize: CGSize) {
        touchEvent?(.movedTimeline, self, touches, event)
    }
    func timelineIndicatorTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, viewSize: CGSize) {
        touchEvent?(.startedTimeline, self, touches, event)
    }
}

extension SSPSectionView: SSPTimelineIndicatorDataSource, SSPWaveViewDataSource {
    func timelineIndicatorBeatsPerBar() -> Int { return .beatsPerBar }
    func timelineIndicatorRollingBarColor() -> UIColor { return .timelineIndicatorColor }
    func timelineIndicatorBarLineColor() -> UIColor { return .timelineIndicatorBarLineColor }
    func timelineIndicatorBeatLineColor() -> UIColor { return .timelineIndicatorBeatLineColor }
    func timelineIndicatorWidth() -> Double { return .timelineIndicatorWidth }
    func waveViewIndicatorColor() -> UIColor { return .waveViewIndicatorColor }
    func waveViewPadding() -> Double { return .waveViewBandPadding }
    func waveViewIndicatorWidth() -> Double { return .waveViewIndicatorWidth }
    func waveViewWaveViewStyle() -> Int { return WAVEVIEWSTYLE.style.rawValue }
}

public enum SectionEvents {
    enum Section {
        case addBarDelta(SSPSectionView, delta: Int)
        case removeSection(SSPSectionView)
        case historyBack(SSPSectionView)
        case historyForward(SSPSectionView)
        case shareSection(SSPSectionView)
    }
    enum Public {
        case initDelegates(((SectionEvents.Section) -> Void)?, ((SectionEvents.Touch, SSPSectionView, Set<UITouch>, UIEvent?) -> Void)?)
        case indicatorVisibilityHide(Bool)
        case setWaveViewData([Band])
        case appendBands([Band])
        case removeBands(Int)
        case updateBands(CountableRange<Int>, [Band])
        case setBars(Int)
        case setRemovable(Bool)
        case setScrobbleAt(Double)
    }
    enum Touch {
        case startedSection
        case startedTimeline
        case startedWaveView
        case movedSection
        case movedTimeline
        case movedWaveView
        case endedSection
        case endedTimeline
        case endedWaveView
    }
}
