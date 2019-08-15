import UIKit
import SSPWaveView
import RxCocoa
import RxSwift


// To add new keys a a new DefaultKey and add an extension like bolow. to add default with enum add new subscript extension for that enum below, make enum inherit from Int or so plus make the enum (pulic)
extension DefaultsKeys {
    static let beatsPerBar = DefaultsKey<Int?>("beatsperbar")

    static let maxBars = DefaultsKey<Int?>("MAXBARS")
    static let startBars = DefaultsKey<Int?>("STARTBARS")
    static let STARTINGSECTIONSEGMENTVIEW = DefaultsKey<Int?>("STARTINGSECTIONSEGMENTVIEW")
    static let sectionBarSteps = DefaultsKey<BarSteps?>("barstepskeys")

    static let windingStepSizeInQuarters = DefaultsKey<Double?>("windingStepSizeInQuarters")
    static let sampleRate = DefaultsKey<Double?>("SAMPLERATE")
    static let initBPM = DefaultsKey<Double?>("INITBPM")

    static let initPlayMode = DefaultsKey<PlayMode?>("INITPLAYMODE")
    static let initOverdubMode = DefaultsKey<OverdubMode?>("INITOVERDUBMODE")
    static let initMetronomePlaying = DefaultsKey<Bool?>("INITMETRONOMEPLAYING")
    static let initLiveVoiceActive = DefaultsKey<Bool?>("INITLIVEVOICEACTIVE")

    static let bgColorWhenRecording = DefaultsKey<UIColor?>("BGCOLORWHENRECORDING")
    static let bgColorWhenNotRecording = DefaultsKey<UIColor?>("BGCOLORWHENNOTRECORDING")
    static let heightBetweenSections = DefaultsKey<CGFloat?>("HEIHGTBETWEENSECTIONS")
    static let initTimeLabelStyle = DefaultsKey<Int?>("INITTIMELABELSTYLE")

    static let waveViewWaveStyle = DefaultsKey<WAVEVIEWWAVEVIEWSTYLE?>("WAVEVIEWWAVEVIEWSTYLE")
    static let waveViewIndicatorColor = DefaultsKey<UIColor?>("WAVEVIEWINDICATORCOLOR")
    static let waveViewBGColor = DefaultsKey<UIColor?>("WAVEVIEBGCOLOR")
    static let waveViewReocordingBandColor = DefaultsKey<UIColor?>("WAVEVIEWRECORDINGBANDCOLOR")
    static let waveViewNotRecordingBandColor = DefaultsKey<UIColor?>("WAVEVIEWNOTRECORDINGBANDCOLOR")
    static let waveViewResolutionPerBeat = DefaultsKey<Int?>("WAVEVIEWRESOLUTIONPERBEAT")
    static let waveViewBandPadding = DefaultsKey<Double?>("WAVEVIEWBANDPADDING")
    static let waveViewIndicatorWIdth = DefaultsKey<Double?>("WAVEVIEWINDICATORWIDTH")

    static let timelineIndicatorColor = DefaultsKey<UIColor?>("TIMELINEINDICATORCOLOR")
    static let timelineIndicatorBarLineColor = DefaultsKey<UIColor?>("TIMELINEINDICATORBARLINECOLOR")
    static let timelineIndicatorBeatLineColor = DefaultsKey<UIColor?>("TIMELINEINDICATORBEATLINECOLOR")
    static let timelineBGColor = DefaultsKey<UIColor?>("TIMELINEBGCOLOR")
    static let timelineIndicatorWidth = DefaultsKey<Double?>("TIMELINEINDICATORWIDTH")

    static let convenienceTripleTap = DefaultsKey<Bool?>("convecienceTripleTap")
}

extension UserDefaults {
    subscript(key: DefaultsKey<UIColor?>) -> UIColor? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
    subscript(key: DefaultsKey<CGFloat?>) -> CGFloat? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
    subscript(key: DefaultsKey<PlayMode?>) -> PlayMode? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
    subscript(key: DefaultsKey<OverdubMode?>) -> OverdubMode? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
    subscript(key: DefaultsKey<WAVEVIEWWAVEVIEWSTYLE?>) -> WAVEVIEWWAVEVIEWSTYLE? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
    subscript(key: DefaultsKey<BarSteps?>) -> BarSteps? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
}

// -------------- BEATS -------------------------
extension Int {
    static var beatsPerBar: Int { return Defaults[DefaultsKeys.beatsPerBar] ?? 4 }
}
// ---------------------------------------------


// ------------------SECTION----------------------
extension Int {
    static var MAXBARS: Int { return Defaults[DefaultsKeys.maxBars] ?? 16 }
    static var STARTBARS: Int { return Defaults[DefaultsKeys.startBars] ?? 1 }
    static var STARTINGSECTIONSEGMENTVIEW: Int { return Defaults[DefaultsKeys.STARTINGSECTIONSEGMENTVIEW] ?? 0 }
}
extension BarSteps {
    static var defaultBarStep: BarSteps { return Defaults[DefaultsKeys.sectionBarSteps] ?? BarSteps.double } // Settings
}
// -----------------------------------------------


// -------------------PLAYBACK-----------------------
extension Double {
    static var WINDINGSTEPSIZEINQUARTERS: Double { return Defaults[DefaultsKeys.windingStepSizeInQuarters] ?? 1.0 }
    static var SAMPLERATE: Double { return Defaults[DefaultsKeys.sampleRate] ?? 44100.0 }
    static var INITBPM: Double { return Defaults[DefaultsKeys.initBPM] ?? 110.0 } // Settings
}
// -------------------------------------------------


// -------------------PLAYLIST-----------------------
extension PlayMode {
    static var INITPLAYMODE: PlayMode { return Defaults[DefaultsKeys.initPlayMode] ?? PlayMode.section }
}

extension OverdubMode {
    static var INITOVERDUBMODE: OverdubMode { return Defaults[DefaultsKeys.initOverdubMode] ?? OverdubMode.replace }
}
extension Bool {
    static var INITMETRONOMEPLAYING: Bool { return Defaults[DefaultsKeys.initMetronomePlaying] ?? false }
    static var LIVEVOICEACTIVE: Bool { return Defaults[DefaultsKeys.initLiveVoiceActive] ?? false }
}
// -------------------------------------------------


//  ------------ MAINVIEW ----------------
extension UIColor {
    static var bgColorWhenRecording: UIColor { return Defaults[DefaultsKeys.bgColorWhenRecording] ?? #colorLiteral(red: 0.2482861578, green: 0.2468155622, blue: 0.2494205534, alpha: 1) }
    static var bgColorWhenNotRecording: UIColor { return Defaults[DefaultsKeys.bgColorWhenNotRecording] ?? #colorLiteral(red: 0.2303370833, green: 0.2303822339, blue: 0.2303311527, alpha: 1) }
    // UIColor.init(patternImage: #imageLiteral(resourceName: "scrollbg1"))
}
extension CGFloat {
    static var HEIGHTBETWEENSECTIONS: CGFloat { return Defaults[DefaultsKeys.heightBetweenSections] ?? 30 }
}
extension Int {
    static var INITTIMELABELSTYLE: Int { return Defaults[DefaultsKeys.initTimeLabelStyle] ?? 0 }
}
// ---------------------------------------------


//  ----------------- WAVEVIEW --------------------
public class WAVEVIEWSTYLE {
    public static var style: WAVEVIEWWAVEVIEWSTYLE { return Defaults[DefaultsKeys.waveViewWaveStyle] ?? .secondRoot }
}
extension UIColor {
    static var waveViewIndicatorColor: UIColor { return Defaults[DefaultsKeys.waveViewIndicatorColor] ?? #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1) } // Settings
    static var waveViewBackgroundColor: UIColor { return Defaults[DefaultsKeys.waveViewBGColor] ?? #colorLiteral(red: 0.3905254006, green: 0.388207972, blue: 0.3923099637, alpha: 1) } // Settings
    static var waveViewRecordingBandColor: UIColor { return Defaults[DefaultsKeys.waveViewReocordingBandColor] ?? #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1) } // Settings
    static var waveViewNotRecordingBandColor: UIColor { return Defaults[DefaultsKeys.waveViewNotRecordingBandColor] ?? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) } // Settings

}
extension Int {
    static var WAVEVIEWRESOLUTIONPERBEAT: Int { return Defaults[DefaultsKeys.waveViewResolutionPerBeat] ?? 8 } // Settings
}
extension Double {
    static var waveViewBandPadding: Double { return Defaults[DefaultsKeys.waveViewBandPadding] ?? 1 }
    static var waveViewIndicatorWidth: Double { return Defaults[DefaultsKeys.waveViewIndicatorWIdth] ?? 2 }
}
// ---------------------------------------------


//  ------------ TIMELINE ----------------
extension UIColor {
    static var timelineIndicatorColor: UIColor { return Defaults[DefaultsKeys.timelineIndicatorColor] ?? #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1) } // Settings
    static var timelineBackgroundColor: UIColor { return Defaults[DefaultsKeys.timelineBGColor] ??  #colorLiteral(red: 0.2627221346, green: 0.2627580762, blue: 0.2627098262, alpha: 1) } // Settings
    static var timelineIndicatorBeatLineColor: UIColor { return Defaults[DefaultsKeys.timelineIndicatorBeatLineColor] ??  #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) } // Settings
    static var timelineIndicatorBarLineColor: UIColor { return Defaults[DefaultsKeys.timelineIndicatorBarLineColor] ?? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) } // Settings
}
extension Double {
    static var timelineIndicatorWidth: Double { return Defaults[DefaultsKeys.timelineIndicatorWidth] ?? 2 }
}
// ---------------------------------------------

//  ------------ CONVENIENCE ----------------
extension Bool {
    static var convenienceTripleTapEnabled: Bool { return Defaults[DefaultsKeys.convenienceTripleTap] ?? true } // Settings
}
// ---------------------------------------------

