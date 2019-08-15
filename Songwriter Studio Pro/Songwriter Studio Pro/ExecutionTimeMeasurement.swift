import Foundation

extension String {
    func measure(_ operation:() -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("\(self): elapsed \(timeElapsed) \(1 / timeElapsed)/s")
    }
    func timeElapsedInSecondsWhenRunningCode(operation:() -> Void) -> Double {
        let startTime = CFAbsoluteTimeGetCurrent()
        operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return Double(timeElapsed)
    }
}
