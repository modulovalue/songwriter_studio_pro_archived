import UIKit
import SSPWaveView
import RxSwift
import RxCocoa

class MainScreen: UIViewController {

    @IBOutlet weak var bpmLbl: UILabel!
    @IBOutlet weak var timeLbl: UIButton!
    @IBOutlet weak var timeDescriptionLabel: UILabel!
    @IBOutlet weak var scrollViewMain: UIScrollView2!
    @IBOutlet weak var section: SSPSectionView!
    @IBOutlet weak var recordButton: RecordButton!
    @IBOutlet weak var playPauseBarButtonitem: UIButton!
    @IBOutlet weak var sectionBarButton: UIButton!
    @IBOutlet weak var menuBtn: UIButton!
    @IBOutlet weak var barInfo: UIView!
    @IBOutlet weak var addSectionBtn: UIButton!
    @IBOutlet weak var liveVoiceBtn: UIButton!
    @IBOutlet weak var overdubModeBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var metronomeBarBtn: UIButton!
    @IBOutlet weak var projectSettingsBtn: UIButton!

    private let disposeBag = DisposeBag()
    private var sections: Variable<[SSPSectionView]> = Variable([])
    private var timeLabelStyle: Int = .INITTIMELABELSTYLE

    var dataSource: MainScreenDataSource?

    var delegate: MainScreenDelegate? {
        didSet {
            recordButton.executeEvent = delegate!.recordingWithEvent
            delegate?.setPlaylistUICallbacks(uiCallback: self)

            liveVoiceBtn.rx.tap.subscribe(onNext: { btn in
                self.delegate?.toolbarEvent(event: .liveVoice)
            }).disposed(by: disposeBag)

            overdubModeBtn.rx.tap.subscribe(onNext: { btn in
                self.delegate?.toolbarEvent(event: .overdubMode)
            }).disposed(by: disposeBag)

            timeLbl.rx.tap.subscribe(onNext: { btn in
                self.timeLabelStyle = (self.timeLabelStyle + 1) % 2
                self.delegate?.toolbarEvent(event: .forceTimeUpdate)
            }).disposed(by: disposeBag)

            playPauseBarButtonitem.rx.tap.subscribe(onNext: { btn in
                self.delegate?.toolbarEvent(event: .togglePlay)
            }).disposed(by: disposeBag)

            addSectionBtn.rx.tap.subscribe(onNext: { btn in
                self.delegate?.toolbarEvent(event: .addSectionAfter(self.sections.value.count - 1))
            }).disposed(by: disposeBag)

            stopBtn.rx.tap.subscribe(onNext: { btn in
                self.delegate?.toolbarEvent(event: .stop)
            }).disposed(by: disposeBag)

            sectionBarButton.rx.tap.subscribe(onNext: { btn in
                self.delegate?.toolbarEvent(event: .mode)
            }).disposed(by: disposeBag)

            metronomeBarBtn.rx.tap.subscribe(onNext: { btn in
                self.delegate?.toolbarEvent(event: .toggleMetronome)
            }).disposed(by: disposeBag)

            updateUI()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeMainScreen()
    }

    func initializeMainScreen() {
        addSectionBtn.layer.cornerRadius = 8
        section.doThis(.initDelegates(sectionEvent, sectionTouchEvent))
        sections.value.append(section)

        menuBtn.rx.tap.subscribe(onNext: { btn in
            (self.navigationController as? NavigationController)?.showMenu()
        }).disposed(by: disposeBag)

        projectSettingsBtn.rx.tap.subscribe(onNext: { btn in
            self.performSegue(withIdentifier: "showProjectSettings", sender: nil)
        }).disposed(by: disposeBag)
    }

    func updateUI() {
        let sectionCount = dataSource?.getProjectSectionCount() ?? 0
        self.addSectionBtn.setTitle(sectionCount <= 1 ? "+" : "\(sectionCount)", for: .normal)
    }

    func sectionEvent(sectionEvent: SectionEvents.Section) {
        let temp: SSPSectionView!
        switch sectionEvent {
        case .addBarDelta(let section, _):
            temp = section
        case .removeSection(let section):
            callSectionUIEvent(
                .setIsRemovableAt(
                    sections.value.index(where: { $0 === section })!,
                    false))
            temp = section
        case .historyForward(let sectionView):
            temp = sectionView
        case .historyBack(let sectionView):
            temp = sectionView
        case .shareSection(let sectionView):
            temp = sectionView
            break
        }
        delegate?.sectionEvent(
                sectionEvent: sectionEvent,
                sectionIndex: sections.value.index(where: { $0 === temp })!)
    }
    
    func sectionTouchEvent(touchEvent: SectionEvents.Touch, sender: SSPSectionView, _ touches: Set<UITouch>, with event: UIEvent?) {
        let sectionIndex = sections.value.index(where: { $0 === sender })!
        switch touchEvent {
        case .startedSection:
            callUIEvent(.allowedToScroll(true))
        case .startedTimeline:
            callUIEvent(.allowedToScroll(false))
            callUIEvent(.setSelectedSection(sectionIndex))
        case .startedWaveView:
            callUIEvent(.allowedToScroll(false))
        case .movedSection:
            callUIEvent(.allowedToScroll(true))
        case .movedTimeline:
            callUIEvent(.setSelectedSection(sectionIndex))
        case .movedWaveView:
            callUIEvent(.setSelectedSection(sectionIndex))
        case .endedSection:
            callUIEvent(.setSelectedSection(sectionIndex))
        case .endedTimeline:
            callUIEvent(.allowedToScroll(true))
        case .endedWaveView:
            callUIEvent(.allowedToScroll(true))
            callUIEvent(.setSelectedSection(sectionIndex))
        }
        var valTouched: Double = 0
        if touchEvent == .endedWaveView || touchEvent == .movedWaveView || touchEvent == .startedWaveView {
            for touch in touches {
                let toouch = touch
                valTouched = Double(toouch.location(in: nil).x / sections.value[sectionIndex].waveView.frame.width)
            }
        } else if touchEvent == .endedTimeline || touchEvent == .movedTimeline || touchEvent == .startedTimeline {
            for touch in touches {
                let toouch = touch
                valTouched = Double(toouch.location(in: nil).x / sections.value[sectionIndex].indicator.frame.width)
            }
        }
        delegate?.sectionTouchEvent(touchEvent: touchEvent, sectionIndex: sectionIndex, value: valTouched)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showProjectSettings") {
            let navVC = segue.destination as? UINavigationController
            let vc = navVC?.viewControllers.first as! OtherOptionsViewController
            vc.mainScreen = self
        }
    }
}


// Callbacks coming back from the Playlist to change the UI
extension MainScreen: PlaylistUICallbacks {

    // Called from Playlist to manipulate UI
    func callUIEvent(_ event: UIManipulationEvent.UI) {
        DispatchQueue.main.async(){
            switch event {
            case .newTimeInSamples(let samples, let length):
                switch self.timeLabelStyle {
                case 0:
                    self.timeLbl.setTitle(samples.mmssSS, for: .normal)
                    self.timeDescriptionLabel.text = .mmssSS
                case 1:
                    self.timeLbl.setTitle(samples.mmssSSRemaining(totalLength: length), for: .normal)
                    self.timeDescriptionLabel.text = String.mmssSSRemaining
                default:
                    break
                }
            case .newBPM(let bpm):
                self.bpmLbl.text = "\(bpm)"
            case .newSamplerate( _): // samplerate
            break // FUTURE todo
            case .didStartPlaying:
                self.playPauseBarButtonitem.setImage(#imageLiteral(resourceName: "pause"), for: UIControlState())
            case .didStartPause:
                self.playPauseBarButtonitem.setImage(#imageLiteral(resourceName: "play"), for: UIControlState())
            case .didStartStop:
                self.callSectionUIEvent(.resetScrobbleAtAll)
            case .addSectionAfter( _):
                let preView = self.sections.value[self.sections.value.count - 1]
                let rect = self.scrollViewMain.convert((preView.frame), from: self.scrollViewMain)
                var newSRect = preView.frame
                newSRect.origin.y = rect.origin.y + rect.height + .HEIGHTBETWEENSECTIONS
                let newSection = SSPSectionView(frame: newSRect)
                newSection.doThis(.initDelegates(self.sectionEvent, self.sectionTouchEvent))
                self.sections.value.append(newSection)
                newSection.alpha = 0
                self.scrollViewMain.addSubview(newSection)
                UIView.animate(withDuration: 0.1, animations: {
                    newSection.alpha = 1
                })
            case .allowedToScroll(let allowed):
                self.scrollViewMain.isScrollEnabled = allowed
            case .metronomeSetTo(let metronome):
                if metronome {
                    self.metronomeBarBtn.setImage(#imageLiteral(resourceName: "metronome"), for: UIControlState())
                } else {
                    self.metronomeBarBtn.setImage(#imageLiteral(resourceName: "notmetronome"), for: UIControlState())
                }


                // TODO


                break
            case .isRecording(let isRecording):
                self.scrollViewMain.mode(isRecording: isRecording)
            case .modeSetTo(let mode):
                switch mode {
                case .section:
                    self.sectionBarButton.setImage(#imageLiteral(resourceName: "notloopmode"), for: UIControlState())
                case .song:
                    self.sectionBarButton.setImage(#imageLiteral(resourceName: "songmode"), for: UIControlState())
                }
            case .setSelectedSection(let index):
                self.callSectionUIEvent(.setSelectedAndOthersNotAt(index))
                self.callUIEvent(.setRemovableSections(index))
            case .setRemovableSections(let index):
                if self.sections.value.count > 1 {
                    for section in self.sections.value {
                        self.callSectionUIEvent(.setIsRemovableAt(self.sections.value.index(where: { $0 === section })!, self.sections.value.index(where: { $0 === section })! == index))
                    }
                } else {
                    self.callSectionUIEvent(.setIsRemovableAt(0, false))
                }
            case .setLiveVoiceActive(let bool):
                if bool {
                    self.liveVoiceBtn.setImage(nil, for: UIControlState())
                    self.liveVoiceBtn.setTitle("Playback On", for: UIControlState())
                } else {
                    self.liveVoiceBtn.setImage(nil, for: UIControlState())
                    self.liveVoiceBtn.setTitle("Playback off", for: UIControlState())
                }
            case .setOverdubMode(let mode):
                switch mode {
                case .add:
                    self.overdubModeBtn.setImage(#imageLiteral(resourceName: "modeoverdub"), for: UIControlState())
                case .replace:
                    self.overdubModeBtn.setImage(#imageLiteral(resourceName: "modereplace"), for: UIControlState())
                }
            }
        }
    }

    func callSectionUIEvent(_ event: UIManipulationEvent.Section) {
        DispatchQueue.main.async() {
            switch event {
            case .removeAt(let index):
                let moveAmount: CGFloat = .HEIGHTBETWEENSECTIONS + self.sections.value[index].frame.height
                for i in index..<self.sections.value.count {
                    self.sections.value[i].moveInSuperViewY(-moveAmount)
                }
                let section = self.sections.value[index]
                self.sections.value.remove(at: index)
                UIView.animate(withDuration: 0.4, delay: 0.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                                section.alpha = 0
                }, completion: {(_: Bool) in
                    self.callUIEvent(.setRemovableSections(0))
                    section.removeFromSuperview()
                })
            case .showIndicatorsHideInOthersAt(let index):
                for i in 0..<self.sections.value.count {
                    self.sections.value[i].doThis(.indicatorVisibilityHide(i != index))
                }
            case .setIsRemovableAt(let index, let isRemovable):
                self.sections.value[index].doThis(.setRemovable(isRemovable))
            case .setWaveViewBands(let index, let bands):
                self.sections.value[index].doThis(.setWaveViewData(bands))
            case .updateBands(let index, let range, let bands):
                self.sections.value[index].doThis(.updateBands(range, bands))
            case .addEmptyBands(let index, let bands):
                self.sections.value[index].doThis(.appendBands(bands))
            case .removeBands(let index, let amount):
                self.sections.value[index].doThis(.removeBands(amount))
            case .setScrobbleAt(let index, let value):
                self.sections.value[index].doThis(.setScrobbleAt(value))
            case .resetScrobbleAtAll:
                self.sections.value.forEach { section in
                    section.doThis(.setScrobbleAt(0.0))
                }
            case .setBarsAt(let index, let bars):
                self.sections.value[index].doThis(.setBars(bars))
            case .setSelectedAndOthersNotAt(let index):
                for i in 0..<self.sections.value.count {
                    let isSelectedSection = i == index
                    self.sections.value[i].setSelected(selected: isSelectedSection)
                    // Reset scrobble indicator if changed section
                    if !isSelectedSection {
                        self.callSectionUIEvent(.setScrobbleAt(i, 0.0))
                    }
                }
            }
        }
    }

    func presentThis(_ doThat: (UIViewController) -> Void) {
        doThat(self)
    }
}

enum UIManipulationEvent {
    enum UI {
        case newTimeInSamples(Int64, length: Int64)
        case newBPM(Double)
        case newSamplerate(Double)
        case didStartPlaying
        case didStartPause
        case didStartStop
        case addSectionAfter(Int)
        case allowedToScroll(Bool)
        case metronomeSetTo(Bool)
        case isRecording(Bool)
        case modeSetTo(PlayMode)
        case setSelectedSection(SectionIndex)
        case setRemovableSections(SectionIndex)
        case setLiveVoiceActive(Bool)
        case setOverdubMode(OverdubMode)
    }
    enum Section {
        case removeAt(Int)
        case showIndicatorsHideInOthersAt(Int)
        case setIsRemovableAt(Int, Bool)
        case setWaveViewBands(SectionIndex, [Band])
        case updateBands(SectionIndex, CountableRange<Int>, [Band])
        case addEmptyBands(SectionIndex, [Band])
        case removeBands(SectionIndex, Int)
        case setScrobbleAt(SectionIndex, Double)
        case resetScrobbleAtAll
        case setBarsAt(SectionIndex, Bars)
        case setSelectedAndOthersNotAt(SectionIndex)
    }
}


protocol MainScreenDelegate: class {
    // all toolbar events are handled
    func toolbarEvent(event: UIEvents.Toolbar)
    // all recording button events are handled
    func recordingWithEvent(event: UIEvents.Recording)
    // all section events are handled here
    func sectionEvent(sectionEvent: SectionEvents.Section, sectionIndex: SectionIndex)
    // when sections are interacted with this is called
    func sectionTouchEvent(touchEvent: SectionEvents.Touch, sectionIndex: SectionIndex, value: Double)
    // set playlist PlaylistUICallbacks variable when delegate set
    func setPlaylistUICallbacks(uiCallback: PlaylistUICallbacks)
}

protocol MainScreenDataSource {
    func getProjectName() -> String
    func getProjectBPM() -> Double
    func getProjectSamplingRate() -> Double
    func getProjectSectionCount() -> Int
}
