import Foundation

class Formatter {
    var userDateFormatter: DateFormatter {
        struct Static {
            static let instance: DateFormatter = {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "mm:ss:SS"
                return dateFormatter
            }()
        }
        return Static.instance
    }
}



extension Int64 {
    var mmssSS: String {
        let date = Date(timeIntervalSince1970: Double(self) / 1_000 / 44.100)
        return Formatter().userDateFormatter.string(from: date)
    }

    func mmssSSRemaining(totalLength: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(totalLength - self) / 1_000 / 44.100)
        return Formatter().userDateFormatter.string(from: date)
    }
}

extension String {
    static var mmssSS: String {
        return "Current Time"
    }
    static var mmssSSRemaining: String {
        return "Remaining Time"
    }
}
