import Foundation
import CoreText

public typealias Band = (magnitude: Float32, color: UIColor)

@IBDesignable public class SSPWaveView: UIView {

    public var delegate: SSPWaveViewDelegate!
    public var dataSource: SSPWaveViewDataSource!
    public var startMiddle = true

    public var indicatorHidden = false {
        didSet {
            if indicatorHidden != oldValue {
                setNeedsDisplay()
            }
        }
    }

    fileprivate var bandData: [Band] = []

    var indicatorPosition: Double = 0 {
        didSet {
            if indicatorPosition != oldValue {
                let block = { self.setNeedsDisplay() }
                Thread.isMainThread ? block() : DispatchQueue.main.async { block() }
            }
        }
    }

    override public func draw(_ rect: CGRect) {
        let fHeight = frame.size.height
        let fWidth = frame.size.width


        guard let data = dataSource else {
            print("no datasource set")
            return
        }

        let singleBandWidth = frame.size.width / CGFloat(bandData.count)

        for i in 0 ..< bandData.count {
            drawBand(index: i, band: bandData[i], singleBandWidth: singleBandWidth)
        }

        let context = UIGraphicsGetCurrentContext()
        if !indicatorHidden {
        let valToMoveTo = CGFloat(indicatorPosition)
            data.waveViewIndicatorColor().set()
            context!.addRect(CGRect(
                x: fWidth * valToMoveTo - CGFloat(data.waveViewIndicatorWidth() / 2) * valToMoveTo,
                y: CGFloat(0),
                width: CGFloat(data.waveViewIndicatorWidth()),
                height: fHeight))
        }
        context!.fillPath()
    }

    public func setScrobbleAt(value: Double) {
        self.indicatorPosition = value
    }

    public func setBandData(bands: [Band]) {
        self.bandData = bands
        setNeedsDisplay()

        if !startMiddle {
            var higherIndex = 0
            for (index, band) in bands.enumerated() {
                if band.magnitude > bands[higherIndex].magnitude {
                    higherIndex = index
                }
            }
        }
    }

    public func appendBands(bands: [Band]) {
        bandData.append(contentsOf: bands)
        setNeedsDisplay()
    }

    public func removeBands(amount: Int) {
        bandData.removeLast(amount)
        setNeedsDisplay()
    }


    public func updateBands(range: CountableRange<Int>, bands: [Band]) {
        if range.overlaps(0..<bandData.count) {
            for i in range {
                let color = bands[i - range.lowerBound].color
                let mag = bands[i - range.lowerBound].magnitude
                bandData[i] = Band(magnitude: mag, color: color )
            }
            setNeedsDisplay()
        }
    }

    func drawBand(index: Int, band: Band, singleBandWidth: CGFloat) {
        let context = UIGraphicsGetCurrentContext()!
        let magnitudeConverted = convertMagnitude(magnitude: band.magnitude)
        // maybe to-do warning
        //((magnitudeConverted > 0.99) ? UIColor.red : band.color).set()
        band.color.set()
        let frameHeight = frame.size.height
        let bandPosX = singleBandWidth * CGFloat(index)
        let bandHeight = frameHeight * (1 - CGFloat(magnitudeConverted))

        context.addRect(CGRect(x: bandPosX,
                               y: startMiddle ? (bandHeight / 2) + (frameHeight * 0.01) : bandHeight,
                                    width: singleBandWidth, // * CGFloat((dataSource?.waveViewPadding())!),
                                    height: (frameHeight - bandHeight) - (frameHeight * 0.01)))
        context.fillPath()
    }

    func convertMagnitude(magnitude: Float32) -> Float32 {
        switch dataSource.waveViewWaveViewStyle() {
        case WAVEVIEWWAVEVIEWSTYLE.magnitude.rawValue:
            return magnitude
        case WAVEVIEWWAVEVIEWSTYLE.db.rawValue:
            var temp = 20 * log10(magnitude)
            temp = temp > 0 ? 0 : temp
            temp = Float32(1.0) + (temp / 120.0)
            return temp
        case WAVEVIEWWAVEVIEWSTYLE.secondRoot.rawValue:
            let temp = pow(magnitude, (1 / 2))
            return temp
        case WAVEVIEWWAVEVIEWSTYLE.secondRootMega.rawValue:
            let temp = pow(magnitude, (1 / 2)) * 3
            return temp
        case WAVEVIEWWAVEVIEWSTYLE.thirdroot.rawValue:
            let temp = pow(magnitude, (1 / 3))
            return temp
        case WAVEVIEWWAVEVIEWSTYLE.fourthroot.rawValue:
            let temp = pow(magnitude, (1 / 4))
            return temp
        case WAVEVIEWWAVEVIEWSTYLE.squared.rawValue:
            let temp = pow(magnitude, 2)
            return temp
        case WAVEVIEWWAVEVIEWSTYLE.cubed.rawValue:
            let temp = pow(magnitude, 3)
            return temp
        default:
            fatalError("WAVE VIEW BAND STYLE NOT AVAILABLE")
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate.waveViewTouchesBegan(touches, with: event, viewSize: frame.size)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate.waveViewTouchesEnded(touches, with: event, viewSize: frame.size)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate.waveViewTouchesMoved(touches, with: event, viewSize: frame.size)
    }
}

public enum WAVEVIEWWAVEVIEWSTYLE: Int {
    case magnitude = 0
    case db = 1
    case secondRoot = 2
    case thirdroot = 3
    case fourthroot = 4
    case squared = 5
    case cubed = 6
    case secondRootMega = 7
}

public protocol SSPWaveViewDelegate: class {
    func waveViewTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, viewSize: CGSize)
    func waveViewTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, viewSize: CGSize)
    func waveViewTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, viewSize: CGSize)
}

public protocol SSPWaveViewDataSource {
    func waveViewIndicatorColor() -> UIColor
    func waveViewPadding() -> Double
    func waveViewIndicatorWidth() -> Double
    func waveViewWaveViewStyle() -> Int
}
