//
//  ProjectManager.swift
//  SongwriterStudioPro
//
//  Created by Modestas Valauskas on 17.12.17.
//  Copyright © 2017 MV. All rights reserved.
//

import Foundation
import UIKit
import Disk

class ProjectManager {
    var playlist: Playlist?
    var PROJECTSFILE = "projects.json"
}

extension ProjectManager: ProjectManagerProtocol {

    func getProjectList() throws -> [ProjectInformation] {
        if Disk.exists(PROJECTSFILE, in: .documents) {
            return try Disk.retrieve(PROJECTSFILE, from: .documents, as: [ProjectInformation].self)
        } else {
            return [ProjectInformation]()
        }
    }

    func deleteProject(project: ProjectInformation) throws {
        print("atempting deletion")
        var projects = try getProjectList()
        projects = projects.filter { $0.name != project.name }
        try Disk.save(projects, to: .documents, as: PROJECTSFILE)
        print("should be deleted")
        // todo delete audioprojectfile, data projectfile
    }

    func loadProject(projectInfo: ProjectInformation, playlistUICallbacks: PlaylistUICallbacks, doAfter: () -> Unit) {
        // todo load project to playlist
//        playlist = Playlist()
    }

    func createNewProject(name: String, bpm: Double) throws {
        let newProjectInformation = ProjectInformation(name: name, initBPM: bpm, audioPath: nil, projectDataPath: nil)
        try Disk.append(newProjectInformation, to: PROJECTSFILE, in: .documents)
        // todo create audioprojectfile, data projectfile
    }

    func getPlaylist() -> Playlist {
        return playlist!
    }

    func nameIsValid(_ name: String?) -> Bool {
        if name == nil {
            return false
        } else if name == "" {
            return false
        } else {
            // todo check if name exists
            return true
        }
    }

    func isProjectLoaded() -> Bool {
        return playlist != nil
    }

    func globalSettings(_ value: SettingsEnum) {
        switch value {
        case .waveformIndicatorColor(let toColor):
            Defaults[DefaultsKeys.waveViewIndicatorColor] = toColor
        case .waveformBackgroundColor(let toColor):
            Defaults[DefaultsKeys.waveViewBGColor] = toColor
        case .waveformRecordingBandColor(let toColor):
            Defaults[DefaultsKeys.waveViewReocordingBandColor] = toColor
        case .waveformNotRecordingBandColor(let toColor):
            Defaults[DefaultsKeys.waveViewNotRecordingBandColor] = toColor
        case .waveformbandsPerBeat(let bandsCount):
            Defaults[DefaultsKeys.waveViewResolutionPerBeat] = bandsCount
        case .timelineIndicatorColor(let toColor):
            Defaults[DefaultsKeys.waveViewIndicatorColor] = toColor
        case .timelineBackgroundColor(let toColor):
            Defaults[DefaultsKeys.timelineBGColor] = toColor
        case .timelineBeatTickColor(let toColor):
            Defaults[DefaultsKeys.timelineIndicatorBeatLineColor] = toColor
        case .timelineBarTickColor(let toColor):
            Defaults[DefaultsKeys.timelineIndicatorBarLineColor] = toColor
        case .resetAppearance:
            // todo resetAppearance to default values
            print("reset")

        case .convenienceTripleTap(let on):
            Defaults[DefaultsKeys.convenienceTripleTap] = on

        case .sectionBarSteps(let barsteps):
            Defaults[DefaultsKeys.sectionBarSteps] = barsteps

        case .audioDefaultBPM(let bpm):
            Defaults[DefaultsKeys.initBPM] = bpm

        }
    }
}

extension ProjectManager {
    func waveformIndicatorColor() -> UIColor {
        return .waveViewIndicatorColor
    }

    func waveformBackgroundColor() -> UIColor {
        return .waveViewBackgroundColor
    }

    func waveformRecordingBandColor() -> UIColor {
        return .waveViewRecordingBandColor
    }

    func waveformNotRecordingBandColor() -> UIColor {
        return .waveViewNotRecordingBandColor
    }

    func waveformbandsPerBeat() -> Int {
        return .WAVEVIEWRESOLUTIONPERBEAT
    }

    func timelineIndicatorColor() -> UIColor {
        return .timelineIndicatorColor
    }

    func timelineBackgroundColor() -> UIColor {
        return .timelineBackgroundColor
    }

    func timelineBeatTickColor() -> UIColor {
        return .timelineIndicatorBeatLineColor
    }

    func timelineBarTickColor() -> UIColor {
        return .timelineIndicatorBarLineColor
    }

    func convenienceTripleTap() -> Bool {
        return .convenienceTripleTapEnabled
    }

    func sectionBarSteps() -> BarSteps {
        return .defaultBarStep
    }

    func audioDefaultBPM() -> Double {
        return .INITBPM
    }
}

protocol ProjectManagerProtocol: SettingsEnumDefault {
    func isProjectLoaded() -> Bool
    func getProjectList() throws -> [ProjectInformation]
    func deleteProject(project: ProjectInformation) throws
    func getPlaylist() -> Playlist
    func createNewProject(name: String, bpm: Double) throws
    func nameIsValid(_ name: String?) -> Bool
    func globalSettings(_ value: SettingsEnum)
}

protocol SettingsEnumDefault {
    func waveformIndicatorColor() -> UIColor
    func waveformBackgroundColor() -> UIColor
    func waveformRecordingBandColor() -> UIColor
    func waveformNotRecordingBandColor() -> UIColor
    func waveformbandsPerBeat() -> Int
    func timelineIndicatorColor() -> UIColor
    func timelineBackgroundColor() -> UIColor
    func timelineBeatTickColor() -> UIColor
    func timelineBarTickColor() -> UIColor

    func convenienceTripleTap() -> Bool
    
    func sectionBarSteps() -> BarSteps

    func audioDefaultBPM() -> Double
}

enum SettingsEnum {
    case waveformIndicatorColor(UIColor),
    waveformBackgroundColor(UIColor),
    waveformRecordingBandColor(UIColor),
    waveformNotRecordingBandColor(UIColor),
    waveformbandsPerBeat(Int),
    timelineIndicatorColor(UIColor),
    timelineBackgroundColor(UIColor),
    timelineBeatTickColor(UIColor),
    timelineBarTickColor(UIColor),
    resetAppearance(),

    convenienceTripleTap(Bool),

    sectionBarSteps(BarSteps),

    audioDefaultBPM(Double)
}

public enum BarSteps: Int {
    case incremental = 1
    case double = 2
}
