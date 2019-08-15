import Foundation
import AudioKit

class AudioManager {

    var trackss: [[Float32]] = []
    let name: String = NSUUID().uuidString.lowercased()
    let callback: AudioManagerTrackUpdateCallback

    init(callback: AudioManagerTrackUpdateCallback) {
        self.callback = callback
    }

    func appendTo(index: Int, samples: [Float32], deltaBars: Int) {
        trackss[index].append(contentsOf: samples)
        callback.updateBandsLast(trackIndex: index, deltaBars: deltaBars)
    }

    func removeLast(index: Int, nnn: Int, deltaBars: Int) {
        trackss[index].removeLast(nnn)
        callback.updateBandsLast(trackIndex: index, deltaBars: deltaBars)
    }

    func addTrack(sampleSize: Int) {
        trackss.append(Array(repeating: 0, count: sampleSize))
        callback.update(samples: trackss[trackss.count - 1], trackIndex: trackss.count - 1)
    }
    
    func removeTrack(sectionIndex: SectionIndex) {
        trackss.remove(at: sectionIndex)
    }

    func replace(_ range: CountableRange<Int>, _ samples: [Float32], _ index: Int) {
        if range.upperBound <= trackss[index].count {
            trackss[index].replaceSubrange(range, with: samples)
            callback.updateRange(samples: trackss[index], trackIndex: index, range: range)
        }
    }

    func updateTrackDuration(index: SectionIndex, newDuration: Int64, deltaBars: Int) {
        let trackDur = Int64(trackss[index].count)
        if trackDur > newDuration {
            removeLast(index: index, nnn: Int(trackDur - newDuration), deltaBars: deltaBars)
        } else if trackDur < newDuration {
            appendTo(index: index, samples: Array(repeatElement(Float32(0), count: Int(newDuration - trackDur))), deltaBars: deltaBars)
        }
    }

    func pushSamples(samples: [Float32], currentTime: Int64, playMode: PlayMode, index: SectionIndex) {

        let size = samples.count
        let curTime = Int(currentTime)
        let recTime = curTime - size

        var curTrack: (index: SectionIndex, length: Int, begin: Int, end: Int)
        var atRecTrack: (index: SectionIndex, length: Int, begin: Int, end: Int)

        if playMode == .section {
            curTrack = (index: index, length: trackss[index].count, begin: 0, end: trackss[index].count)
            atRecTrack = curTrack
        } else {
            curTrack = timeToTrackInfo(time: currentTime)
            atRecTrack = timeToTrackInfo(time: currentTime - Int64(size))
        }

        var samplePivot: Int! = nil
        var firstRange: CountableRange<Int>!
        var secondRange: CountableRange<Int>!

        if curTrack.index == atRecTrack.index { // only called if 1 section repeats itself
            if recTime - curTrack.begin < 0 {
                samplePivot = abs(recTime)
                firstRange = atRecTrack.length + recTime..<atRecTrack.length
                secondRange = 0..<curTime
            } else {
                samplePivot = size
                firstRange = recTime - curTrack.begin..<curTime - curTrack.begin
                secondRange = nil
            }
        } else if curTrack.index > atRecTrack.index {
            samplePivot = atRecTrack.end - recTime
            firstRange = recTime - atRecTrack.begin..<atRecTrack.length
            secondRange = 0..<curTime - curTrack.begin
        } else if curTrack.index < atRecTrack.index {
            samplePivot = abs(recTime)
            firstRange = atRecTrack.length + recTime..<atRecTrack.length
            secondRange = 0..<curTime
        }

        replace(firstRange, Array(samples[0..<samplePivot]), atRecTrack.index)
        if secondRange != nil {
            replace(secondRange, Array(samples[samplePivot..<size]), curTrack.index)
        }

    }

    func getSamplesForNext(size: Int, currentTime: Int64, playMode: PlayMode, index: SectionIndex ) -> [Float32] {

        let curTime = Int(currentTime)
        let recTime = curTime + size

        switch playMode {
        case .section:
            let trackLength = trackss[index].count
            if recTime <= trackLength {
                return Array(trackss[index][curTime..<recTime])
            } else {
                var arr: [Float32] = []
                // todo crashes if bar removed and time in that bar
                if trackLength >= curTime {
                    arr.append(contentsOf: trackss[index][curTime..<trackLength])
                    arr.append(contentsOf: trackss[index][0..<trackLength - curTime])
                } else {
                    arr = Array(repeatElement(Float32(0), count: size))
                }
                return arr
            }
        case .song:
            let curTrack = timeToTrackInfo(time: currentTime)
            let atRecTrack = timeToTrackInfo(time: currentTime + Int64(size))

            var arr: [Float32] = []
            if curTrack.index == atRecTrack.index { // only called if songmode and 1 section repeats itself
                if curTrack.length < curTime - curTrack.begin {
                    return Array(repeatElement(Float32(0), count: size))
                } else if recTime > curTrack.end { // first section repeats itself
                    arr.append(contentsOf: trackss[curTrack.index][curTime - curTrack.begin..<curTrack.length])
                    arr.append(contentsOf: trackss[curTrack.index][0..<recTime - curTrack.end])
                } else {
                    return Array(trackss[curTrack.index][curTime - curTrack.begin..<recTime - curTrack.begin])
                }
            } else if curTrack.index < atRecTrack.index {
                arr.append(contentsOf: trackss[curTrack.index][curTime - curTrack.begin..<curTrack.length])
                arr.append(contentsOf: trackss[atRecTrack.index][0..<recTime - curTrack.end])
            } else if curTrack.index > atRecTrack.index {
                arr.append(contentsOf: trackss[curTrack.index][curTime - curTrack.begin..<curTrack.length])
                arr.append(contentsOf: trackss[atRecTrack.index][0..<recTime - curTrack.end])
            }
            return arr
        }
    }

    func timeToTrackInfo(time: Int64) -> (index: SectionIndex, length: Int, begin: Int, end: Int) {  // swiftlint:disable:this large_tuple
        let timeTrackIndex = getAffectedTrackIndex(time: Int(time))!
        let trackTime = getTrackTime(index: timeTrackIndex)
        return (index: timeTrackIndex, length: trackTime.end - trackTime.begin, begin: trackTime.begin, end: trackTime.end)
    }

    func getTrackTime(index: Int) -> (begin: Int, end: Int) {
        var last = 0..<0
        for i in 0..<trackss.count {
            last = last.upperBound..<last.upperBound + trackss[i].count
            if i == index {
                return (begin: last.lowerBound, end: last.upperBound)
            }
        }
        fatalError("cant get track time for \(index)")
    }


    func getAffectedTrackIndex(time: Int) -> Int! {
        var last = 0..<0
        for i in 0..<trackss.count {
            last = last.upperBound..<last.upperBound + trackss[i].count
            if last ~= time {
                return i
            }
        }
        if time < 0 {
            return trackss.count - 1
        } else if time > getTrackTime(index: trackss.count - 1).end {
            return 0
        }
        fatalError(" get affected track for time \(time) not found")
    }

//    func p() {
//        save()
//        print("tdebug audiomanager count \(trackss.count)")
//        trackss.forEach({ track in print("\( track.count )") })
//    }

    func save() {
        var arr: [Float32] = []
        //save arr as audio
        "appending samples".measure {
            trackss.forEach({ track in arr.append(contentsOf: track) })
        }
        "Saving with \(arr.count) and Size \(arr.count)".measure({
            do {
                let arr = [arr, arr]
                _ = try AKAudioFile(createFileFromFloats: arr, baseDir: .documents, name: "\(name)")
            } catch let err as NSError { print("saving file \(err.localizedDescription)") }
        })
    }

    func addLayer(_ sectionIndex: SectionIndex) {
        // TODO sowohl hier als auch @ Playlist where this is called to change the ui
    }

    func shareSection(_ sectionIndex: SectionIndex, _ share: (URL) -> Void) {
        do {
            let arr = [trackss[sectionIndex], trackss[sectionIndex]]
            let file = try AKAudioFile(createFileFromFloats: arr, baseDir: .documents, name: "audioSnippet")

            // Get the document directory url
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let audioFileURL = documentsUrl.appendingPathComponent("audioSnippet.caf")

            do {
                let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let documentDirectory = URL(fileURLWithPath: path)
                let destinationPath = documentDirectory.appendingPathComponent("audioSnippet.aiff")
                if FileManager.default.fileExists(atPath: destinationPath.path) {
                    try FileManager.default.removeItem(at: destinationPath)
                }
                try FileManager.default.moveItem(at: audioFileURL, to: destinationPath)
                share(destinationPath)
            } catch {
                print(error)
            }

//            do {
//                // Get the directory contents urls (including subfolders urls)
//                let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
//                print(directoryContents)
//
////                // if you want to filter the directory contents you can do like this:
////                let mp3Files = directoryContents.filter{ $0.pathExtension == "mp3" }
////                print("mp3 urls:",mp3Files)
////                let mp3FileNames = mp3Files.map{ $0.deletingPathExtension().lastPathComponent }
////                print("mp3 list:", mp3FileNames)
//
//            } catch {
//                print(error.localizedDescription)
//            }

//            let file = try AKAudioFile(createFileFromFloats: arr)
            print(file)
        } catch let err as NSError { print("\(err.localizedDescription)") }
    }

}

protocol AudioManagerTrackUpdateCallback {
    func update(samples: [Float32], trackIndex: Int)
    func updateRange(samples: [Float32], trackIndex: Int, range: CountableRange<Int>)
    func updateBandsLast(trackIndex: Int, deltaBars: Int)
}
