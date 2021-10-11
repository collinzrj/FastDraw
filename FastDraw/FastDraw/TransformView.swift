//
//  TransformView.swift
//  realtimedrawing
//
//  Created by 张睿杰 on 2020/4/3.
//  Copyright © 2020 张睿杰. All rights reserved.
//

import UIKit

class TransformView: UIView {
    var curves: [Curve] = []
    var lasso: [CGPoint] = []
    
    func drawLasso() {
        if let lastPoint = lasso.last {
            let path = UIBezierPath()
            path.move(to: lastPoint)
            for point in lasso {
                path.addLine(to: point)
            }
            
            let layer = CAShapeLayer()
            layer.strokeColor = UIColor.gray.cgColor
            layer.fillColor = UIColor.clear.cgColor
            layer.path = path.cgPath
            layer.lineDashPattern = [5, 3]
            layer.lineWidth = 2
            layer.lineCap = .round
            self.layer.addSublayer(layer)
        }
    }
    
    override func draw(_ rect: CGRect) {
        print(curves.map {$0.segments.count}, "curves exist")
        for curve in curves {
            
            let segments = curve.segments
            
            if !segments.isEmpty {
                let color = segments[0].color
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                
                if alpha < 1 {
                    let path = UIBezierPath()
                    let firstSegment = segments[0]
                    let width = distance(firstSegment.start_lower_point,
                                            firstSegment.start_upper_point)
                    let firstPoint = getMidPoint(firstPoint: firstSegment.start_lower_point,
                                                 secondPoint: firstSegment.start_upper_point)
                    for segment in curve.segments {
                        let startPoint = getMidPoint(firstPoint: segment.start_upper_point,
                                                     secondPoint: segment.start_lower_point)
                        let endPoint = getMidPoint(firstPoint: segment.end_lower_point,
                                                secondPoint: segment.end_upper_point)
                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                    }
                    path.lineWidth = width
                    path.lineCapStyle = .round
                    path.lineJoinStyle = .round
                    color.setStroke()
                    path.stroke()
                } else {
                    for segment in curve.segments {
                        segment.color.setFill()
                        for path in segment.paths {
                            path.fill()
                        }
                    }
                }
            }
        }
    }

}
