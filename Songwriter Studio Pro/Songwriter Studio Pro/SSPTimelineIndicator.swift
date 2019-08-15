import UIKit

public class SSPTimelineIndicator: UIView {

    public weak var delegate: SSPTimelineIndicatorDelegate?
    public weak var dataSource: SSPTimelineIndicatorDataSource?

    public var bars = 4 {
        didSet {
            if bars != oldValue {
                setNeedsDisplay()
            }
        }
    }
    public var indicatorHidden = false {
        didSet {
            if indicatorHidden != oldValue {
                setNeedsDisplay()
            }
        }
    }
    var indicatorPosition: Double = 0 {
        didSet {
            if indicatorPosition != oldValue {
                let block = { self.setNeedsDisplay() }
                Thread.isMainThread ? block() : DispatchQueue.main.async { block() }
            }
        }
    }
    override public func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let fHeight = frame.size.height
        let fWidth = frame.size.width

        if let data = dataSource {
            draw(bars: bars, context: context!)
            if !indicatorHidden {
                dataSource?.timelineIndicatorRollingBarColor().set()
                context!.addRect(CGRect(
                    x: fWidth * CGFloat(indicatorPosition) - CGFloat(data.timelineIndicatorWidth() / 2) * CGFloat(indicatorPosition),
                    y: CGFloat(0),
                    width: CGFloat(data.timelineIndicatorWidth()),
                    height: fHeight))
            }
            context?.fillPath()
        }
    }

    func draw(bars: Int, context: CGContext) {
        let superwidth = superview?.frame.size.width
        for index in 0..<bars * 4 {
            let divider = CGFloat(index) / CGFloat(bars * 4)
            drawBeat(xPosition: CGFloat(superwidth! * divider), context: context)
            if (index % 4) == 0 {
                let divider = CGFloat(index) / CGFloat(bars * 4)
                drawBar(xPosition: CGFloat(superwidth! * divider), context: context)
            }
        }
    }
    func drawBar(xPosition: CGFloat, context: CGContext) {
        dataSource?.timelineIndicatorBarLineColor().set()
        let lineWidth: CGFloat = 2
        let fHeight = frame.size.height
        context.addRect(CGRect(x: xPosition, y: fHeight * 0.45, width: lineWidth, height: fHeight * 0.75))
        context.fillPath()

    }

    func drawBeat(xPosition: CGFloat, context: CGContext) {
        dataSource?.timelineIndicatorBeatLineColor().set()
        let lineWidth: CGFloat = 1
        let fHeight = frame.size.height
        _ = frame.size.width
        context.addRect(CGRect(x: xPosition, y: fHeight / 4 * 3, width: lineWidth, height: fHeight / 4 * 3))
        context.fillPath()
    }

    public func setScrobbleAt(value: Double) {
        self.indicatorPosition = value
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.timelineIndicatorTouchesBegan(touches, with: event, viewSize: frame.size)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.timelineIndicatorTouchesEnded(touches, with: event, viewSize: frame.size)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.timelineIndicatorTouchesMoved(touches, with: event, viewSize: frame.size)
    }
}

@objc public protocol SSPTimelineIndicatorDelegate: class {
    func timelineIndicatorTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, viewSize: CGSize)
    func timelineIndicatorTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, viewSize: CGSize)
    func timelineIndicatorTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, viewSize: CGSize)
}

public protocol SSPTimelineIndicatorDataSource: class {
    func timelineIndicatorBeatsPerBar() -> Int
    func timelineIndicatorRollingBarColor() -> UIColor
    func timelineIndicatorBarLineColor() -> UIColor
    func timelineIndicatorBeatLineColor() -> UIColor
    func timelineIndicatorWidth() -> Double
}
