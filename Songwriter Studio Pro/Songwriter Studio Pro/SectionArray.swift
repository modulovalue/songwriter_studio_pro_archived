import Foundation

class SectionArray {

    var sectionArray: [SectionModel] = []
    var selectedSection: SectionModel!
    var playlist: Playlist

    init(playlist: Playlist, firstSectionBars: Int) {
        self.playlist = playlist
        sectionArray.append(SectionModel(initBars: firstSectionBars))
        setSelectedSection(index: 0)
    }

    func setSelectedSection(index: SectionIndex) {
        selectedSection = sectionArray[index]
        playlist.uiCallbacks?.callUIEvent(.setSelectedSection(index))
    }

    func removeSection(sectionIndex: Int) {
        if selectedSection === sectionArray[sectionIndex] {
            if sectionArray.count > 1 {
                self.sectionArray.remove(at: sectionIndex)
                setSelectedSection(index: 0)
            }
        }
    }

    func barChangeDelta(sectionIndex: SectionIndex, delta: Int) -> Int {
        let section = sectionArray[sectionIndex]
        var newDelta = delta

        if (section.sectionBars > 1) || (section.sectionBars < .MAXBARS) {
            if delta > 0 {
                newDelta = section.sectionBars
                section.sectionBars *= 2

            } else if delta < 0 {
                newDelta = section.sectionBars / -2
                section.sectionBars /= 2
            }
            //sound?.removeBar(samplesInBar: Int(dataSource.getTimeFor(atWhere: .bar, amount: 1, type: .samples)))
            let sTime = playlist.getSectionTime(index: sectionIndex)
            let curTime = playlist.playback.getTimeFor(atWhere: .currentTime)
            if playlist.playMode.value == .song && sTime.begin <= curTime && sTime.end > curTime {
                playlist.playback.windWithDelta(delta: delta)
            }
        }
        return newDelta
    }

    func addSectionAfter(afterSectionIndex: Int) {
        let model = SectionModel(initBars: .STARTBARS)
        sectionArray.append(model)
        playlist.uiCallbacks?.callUIEvent(.addSectionAfter(afterSectionIndex))
        playlist.uiCallbacks?.callSectionUIEvent(.setBarsAt(afterSectionIndex + 1, .STARTBARS))
        playlist.uiCallbacks?.callUIEvent(.setRemovableSections(selectedIndex()))
    }

    func selectedIndex() -> Int {
        return selectedSection.index(sectionArray)
    }

}


class SectionModel {

    var sectionBars: Int

    init(initBars: Int) {
        self.sectionBars = initBars
    }

    func index(_ array: [SectionModel]) -> Int {
        return array.index(where: { $0 === self })!
    }
}
