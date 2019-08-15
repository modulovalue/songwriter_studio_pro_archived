//
//  EdgeShadowLayer.swift
//  SongwriterStudioPro
//
//  Created by Modestas Valauskas on 03.04.17.
//  Copyright © 2017 MV. All rights reserved.
//

import Foundation
import UIKit

public class EdgeShadowLayer: CAGradientLayer {

    public enum Edge {
        case top
        case left
        case bottom
        case right
    }

    public init(forView view: UIView,
                edge: Edge = Edge.top,
                shadowRadius radius: CGFloat = 20.0,
                toColor: UIColor = UIColor.white,
                fromColor: UIColor = UIColor.black) {
        super.init()
        self.colors = [fromColor.cgColor, toColor.cgColor]
        self.shadowRadius = radius

        let viewFrame = view.frame

        switch edge {
        case .top:
            startPoint = CGPoint(x: 0.5, y: 0.0)
            endPoint = CGPoint(x: 0.5, y: 1.0)
            self.frame = CGRect(x: 0.0, y: 0.0, width: viewFrame.width, height: shadowRadius)
        case .bottom:
            startPoint = CGPoint(x: 0.5, y: 1.0)
            endPoint = CGPoint(x: 0.5, y: 0.0)
            self.frame = CGRect(x: 0.0, y: viewFrame.height - shadowRadius, width: viewFrame.width, height: shadowRadius)
        case .left:
            startPoint = CGPoint(x: 0.0, y: 0.5)
            endPoint = CGPoint(x: 1.0, y: 0.5)
            self.frame = CGRect(x: 0.0, y: 0.0, width: shadowRadius, height: viewFrame.height)
        case .right:
            startPoint = CGPoint(x: 1.0, y: 0.5)
            endPoint = CGPoint(x: 0.0, y: 0.5)
            self.frame = CGRect(x: viewFrame.width - shadowRadius, y: 0.0, width: shadowRadius, height: viewFrame.height)
        }

//        let topShadow = EdgeShadowLayer(forView: scrollViewMain, edge: .top, shadowRadius: CGFloat(20.0), toColor: UIColor.clear, fromColor: UIColor.black)
//
//        scrollViewMain.layer.insertSublayer(topShadow, below: section.layer)

    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
