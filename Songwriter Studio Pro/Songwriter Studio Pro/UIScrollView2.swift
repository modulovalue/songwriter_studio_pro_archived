import Foundation
import UIKit

class UIScrollView2: UIScrollView {

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        let tripleTap = UITapGestureRecognizer(target: self, action: #selector(UIScrollView2.scrollToTop))
        tripleTap.numberOfTapsRequired = 3
        self.gestureRecognizers?.append(tripleTap)
        backgroundColor = .bgColorWhenNotRecording
        superview?.sendSubview(toBack: self)
        contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 100, right: 0.0)
        indicatorStyle = UIScrollViewIndicatorStyle.white
        mode(isRecording: false)
    }

    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        setContentSize()
    }

    func setContentSize() {
        contentSize.height = subviews
            .filter({ $0 is SSPSectionView })
            .reduce(0, { $0 + ($1.frame.height + .HEIGHTBETWEENSECTIONS) })
    }

    @objc func scrollToTop() {
        setContentOffset(CGPoint(x: contentOffset.x, y: 0), animated: true)
    }

    override func willRemoveSubview(_ subview: UIView) {
        contentSize.height = subviews
            .filter({ $0 is SSPSectionView })
            .reduce(0, { $0 + ($1.frame.height + .HEIGHTBETWEENSECTIONS) })
            - (.HEIGHTBETWEENSECTIONS + subview.frame.height)
    }

    func mode(isRecording: Bool) {
        UIView.animate(withDuration: 0.05, animations: {
            self.backgroundColor = isRecording ? .bgColorWhenRecording : .bgColorWhenNotRecording
        })
    }
}
