import XCTest
import CoreAudio


@testable import SongwriterStudioPro


class AudioManagerTest: XCTestCase {

    var manager: AudioManager! = nil

    override func setUp() {
        super.setUp()
        manager = AudioManager(callback: self as AudioManagerTrackUpdateCallback)
        manager.addTrack(sampleSize: 44100)
        manager.addTrack(sampleSize: 44100)
    }

    func testAddTrackRemoveTrack() {
        manager.addTrack(sampleSize: 44100)
        XCTAssert(manager.trackss.count == 3)
        manager.removeTrack(sectionIndex: 2)
        manager.removeTrack(sectionIndex: 0)
        XCTAssert(manager.trackss.count == 1)
        manager.removeTrack(sectionIndex: 0)
        XCTAssert(manager.trackss.isEmpty)
    }

    func testRemoveSamplesAddSamples() {
        //delta bars dont matter here
        manager.removeLast(index: 1, nnn: 100, deltaBars: 1)
        XCTAssert(manager.trackss[1].count == 44000)
        manager.removeLast(index: 0, nnn: 44000, deltaBars: 1)
        XCTAssert(manager.trackss[0].count == 100)
        manager.appendTo(index: 1, samples: Array(repeatElement(Float32(0), count: 10000)), deltaBars: 1)
        XCTAssert(manager.trackss[1].count == 54000)
        manager.appendTo(index: 0, samples: Array(repeatElement(Float32(0), count: 10000)), deltaBars: 1)
        XCTAssert(manager.trackss[0].count == 10100)
    }

    func testReplaceSubrange() {
        manager.replace(0..<100, Array(repeatElement(Float32(1), count: 100)), 0)
        manager.replace(44000..<44100, Array(repeatElement(Float32(1), count: 100)), 1)
        XCTAssert(Array(manager.trackss[1][44000..<44100]) == Array(repeatElement(Float32(1), count: 100)))
        XCTAssert(Array(manager.trackss[0][0..<100]) == Array(repeatElement(Float32(1), count: 100)))
        XCTAssert(manager.trackss[0].count == 44100)
        XCTAssert(manager.trackss[1].count == 44100)
    }

    func testUpdateTrackDuration() {
        // deltabars dont matter here
        manager.updateTrackDuration(index: 0, newDuration: 100, deltaBars: 1)
        manager.updateTrackDuration(index: 1, newDuration: 88200, deltaBars: 1)
        XCTAssert(manager.trackss[0].count == 100)
        XCTAssert(manager.trackss[1].count == 88200)
    }

    func testPushSamplesSection() {
        manager = AudioManager(callback: self as AudioManagerTrackUpdateCallback)
        manager.addTrack(sampleSize: 100)
        manager.addTrack(sampleSize: 100)
        manager.pushSamples(samples: Array(repeatElement(Float32(0.1), count: 40)), currentTime: 40, playMode: .section, index: 0)
        manager.pushSamples(samples: Array(repeatElement(Float32(0.1), count: 40)), currentTime: 80, playMode: .section, index: 0)
        manager.pushSamples(samples: Array(repeatElement(Float32(1), count: 40)), currentTime: 20, playMode: .section, index: 0)
        XCTAssertEqual(Array(manager.trackss[0][0..<20]), Array(repeatElement(Float32(1), count: 20)))
        XCTAssertEqual(Array(manager.trackss[0][80..<100]), Array(repeatElement(Float32(1), count: 20)))
        XCTAssertEqual(Array(manager.trackss[0][20..<80]), Array(repeatElement(Float32(0.1), count: 60)))
    }

    func testPushSamplesSong() {
        manager = AudioManager(callback: self as AudioManagerTrackUpdateCallback)
        manager.addTrack(sampleSize: 100)
        manager.addTrack(sampleSize: 100)
        manager.pushSamples(samples: Array(repeatElement(Float32(0.1), count: 60)), currentTime: 60, playMode: .song, index: 0)
        XCTAssertEqual(Array(manager.trackss[0][0..<60]), Array(repeatElement(Float32(0.1), count: 60)))
        manager.pushSamples(samples: Array(repeatElement(Float32(1), count: 60)), currentTime: 120, playMode: .song, index: 0)
        XCTAssertEqual(Array(manager.trackss[0][60..<100]), Array(repeatElement(Float32(1), count: 40)))
        XCTAssertEqual(Array(manager.trackss[1][0..<20]), Array(repeatElement(Float32(1), count: 20)))
        manager.pushSamples(samples: Array(repeatElement(Float32(0.2), count: 60)), currentTime: 180, playMode: .song, index: 0)
        XCTAssertEqual(Array(manager.trackss[1][20..<80]), Array(repeatElement(Float32(0.2), count: 60)))
        manager.pushSamples(samples: Array(repeatElement(Float32(-1), count: 60)), currentTime: 40, playMode: .song, index: 0)
        XCTAssertEqual(Array(manager.trackss[1][80..<100]), Array(repeatElement(Float32(-1), count: 20)))
        XCTAssertEqual(Array(manager.trackss[0][0..<40]), Array(repeatElement(Float32(-1), count: 40)))
    }

    func testGetAffectedTrackIndex() {
        XCTAssert(manager.getAffectedTrackIndex(time: 0) == 0)
        XCTAssertEqual(manager.getAffectedTrackIndex(time: 45000), 1)
        XCTAssertEqual(manager.getAffectedTrackIndex(time: 44100), 1)
        XCTAssertEqual(manager.getAffectedTrackIndex(time: 44099), 0)
       //  XCTAssertThrowsError(manager.getAffectedTrackIndex(time: 88200)) fatalerror should crash cant test
        XCTAssertEqual(manager.getAffectedTrackIndex(time: 88199), 1)
    }

    func testTrackTime() {
        XCTAssertEqual(manager.getTrackTime(index: 0).begin, 0)
        XCTAssertEqual(manager.getTrackTime(index: 0).end, 44100)
        XCTAssertEqual(manager.getTrackTime(index: 1).begin, 44100)
        XCTAssertEqual(manager.getTrackTime(index: 1).end, 88200)
    }
}

extension AudioManagerTest: AudioManagerTrackUpdateCallback {
    func update(samples: [Float32], trackIndex: Int) {
        // nothing updates wave bands
    }

    func updateRange(samples: [Float32], trackIndex: Int, range: CountableRange<Int>) {

    }

    func updateBandsLast(trackIndex: Int, deltaBars: Int) {

    }
}


class SSPlaybackTest: XCTestCase {

    var playback: SSPPlayback!

    override func setUp() {
        super.setUp()
    }

    func testPlayback() {
        for i in 60...240 {
            withBpm(BPM: Double(i))
        }
        for i in 70...200 {
            withBpm(BPM: Double(i) - 0.4139)
        }
        withBpm(BPM: 110)
    }

    func withBpm(BPM: Double) {

        let dataSource = self as SSPPlaybackDataSource
        let delegate = SpyPlaybackDelegate()

        self.playback = SSPPlayback(delegate: delegate as SSPPlaybackDelegate, dataSource: dataSource as SSPPlaybackDataSource)

        self.playback.setupPlayback()

        XCTAssertEqual(playback.getTimeFor(atWhere: .currentTime), 0)
        XCTAssertEqual(playback.getTimeFor(atWhere: .endOfCurrentPlayMode), Int64(1000000000))
        XCTAssertEqual(playback.getTimeFor(atWhere: .currentTime), 0)

        let fifteenbeats = playback.getTimeFor(atWhere: .beat, amount: 15)
        playback.setTime(newCurrentTimeInSamples: fifteenbeats)

            //- Int64(arc4random_uniform(80)) - Int64(40)))
        for j in 1...15 {
            let i = 15 - j
            playback.windWithDelta(delta: -1)
            let shouldBe = 60.0 / playback.getBPM() * playback.getSamplingRate() * Double(i)

            //print(" I \(i) CurrentTime \(playback.getTimeFor(atWhere: .currentTime))  should be \( shouldBe)")
            XCTAssertEqual(playback.getTimeFor(atWhere: .currentTime), Int64(round(shouldBe)) )
        }
        playback.setTime(newCurrentTimeInSamples: 0)

        for _ in 1...1 {
            playback.windWithDelta(delta: 1)
        }

        XCTAssertEqual(playback.timeAtPlayInSamples, (playback.getTimeFor(atWhere: .beat, amount: 1) ) % playback.dataSource.activePlayModeLengthInSamples() )
        playback.stop()

        XCTAssert(playback.timeAtPlayInSamples == Int64(0))
        playback.togglePlay()
        XCTAssertEqual(playback.timeAtPlayInSamples as Int64, 0)

        for _ in 0..<101 {
            playback.pushSamples(size: 1024)
        }
        XCTAssertEqual(playback.timeAtPlayInSamples, (1024 * 101) % playback.dataSource.activePlayModeLengthInSamples())
        playback.stop()
        XCTAssert(playback.getIsPaused() == true)

        playback.togglePlay()

        for _ in 0..<100 {
            playback.pushSamples(size: 10)
        }
        XCTAssertEqual(playback.timeAtPlayInSamples, Int64(1000))

        playback.setTime(newCurrentTimeInSamples: 0)

        playback.pushSamples(size: Int(playback.dataSource.activePlayModeLengthInSamples() * 1000))

        XCTAssert(playback.timeAtPlayInSamples == Int64(0))
        playback.pushSamples(size: Int(playback.dataSource.activePlayModeLengthInSamples()) / 3)
        XCTAssertEqual(playback.timeAtPlayInSamples, playback.dataSource.activePlayModeLengthInSamples() / 3)
        playback.stop()

    }
}

extension SSPlaybackTest: SSPPlaybackDataSource {
    func activePlayModeLengthInSamples() -> Int64 {
        return Int64(1000000000)
    }
}


class SpyPlaybackDelegate: SSPPlaybackDelegate {
    func newTimeInSamples(samples: Int64) {}
    func play(_ playing: Bool) {}
    func stop() {}

}
