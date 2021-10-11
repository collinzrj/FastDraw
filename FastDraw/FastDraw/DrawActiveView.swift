//
//  DrawActiveView.swift
//  realtimedrawing
//
//  Created by 张睿杰 on 2020/2/29.
//  Copyright © 2020 张睿杰. All rights reserved.
//

import UIKit

internal protocol DrawActiveViewDelegate: class {
    func lastDrawFinish()
}

class DrawActiveView: UIView {

    var activeStroke: Stroke?
    var state: UIGestureRecognizer.State?
    weak var delegate: DrawActiveViewDelegate?
    var brush: Brush!
    
    override func draw(_ rect: CGRect) {
        if let activeStroke = self.activeStroke {
            let color = UIColor(hexa: activeStroke.color)
            if brush.type == .eraser {
                if let point = activeStroke.offsetPoints.last?.offsetLocation(basePoint: activeStroke.basePoint) {
                    let halfWidth = brush.width / 2
                    let rect = CGRect(x: point.x - halfWidth, y: point.y - halfWidth,
                                      width: brush.width, height: brush.width)
                    let circle = UIBezierPath(ovalIn: rect)
                    UIColor.blue.setFill()
                    circle.fill()
                }
            } else if brush.type == .lasso {
                if let firstPoint = activeStroke.offsetPoints.first {
                    let path = UIBezierPath()
                    path.move(to: firstPoint.offsetLocation(basePoint: activeStroke.basePoint))
                    for point in activeStroke.offsetPoints.dropFirst() {
                        path.addLine(to: point.offsetLocation(basePoint: activeStroke.basePoint))
                    }
                    path.setLineDash([5, 3], count: 2, phase: 0.0)
                    path.lineWidth = 2
                    path.lineCapStyle = .round
                    UIColor.gray.setStroke()
                    path.stroke()
                }
            } else if brush.type == .highlighter {
                let path = UIBezierPath()
                let points = activeStroke.offsetPoints.map { $0.offsetLocation(basePoint: activeStroke.basePoint) }
                if !points.isEmpty {
                    path.move(to: points[0])
                    for point in points[1...] {
                        path.addLine(to: point)
                    }
                    color.setStroke()
                    path.lineWidth = brush.width
                    path.lineCapStyle = .round
                    path.lineJoinStyle = .round
                    path.stroke()
                }
            } else {
                let curve = StrokeToCurve(stroke: activeStroke)
                for segment in curve.segments {
                    color.setFill()
                    segment.paths[0].fill()
                }
            }
        }
        if state == UIGestureRecognizer.State.ended {
            DispatchQueue.main.async {
                self.delegate?.lastDrawFinish()
            }
        }
    }
}
