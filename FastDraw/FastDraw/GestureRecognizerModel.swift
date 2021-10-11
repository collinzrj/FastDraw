//
//  GestureRecognizerModel.swift
//  realtimedrawing
//
//  Created by 张睿杰 on 2019/11/11.
//  Copyright © 2019 张睿杰. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizer

typealias Rectangle = (minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat)

public protocol GestureRecognizerModelDelegate: class {
    func firstTouchDetected()
}

public class GestureRecognizerModel: UIGestureRecognizer {
    
    public var brush: Brush!
    public var stroke: Stroke!
    public weak var scrollView: UIScrollView?
    public weak var gestureDelegate: GestureRecognizerModelDelegate?
    
    private var adjustForce: CGFloat = 0.4
    private var adjustTime: CGFloat = 10000
    private var previousTime: CGFloat?
    private var previousPoint: CGPoint?
    private var previousForce: CGFloat?
    private var strokecolor: UIColor = .black
    private var rect: Rectangle?
    private var width: CGFloat = 3.2
    private var coordinateSpaceView: UIView?
    private var ensuredReferenceView: UIView {
        if let view = coordinateSpaceView {
            return view
        } else {
            return view!
        }
    }
    
    private func append(touches: Set<UITouch>, event: UIEvent?) {
        guard let touch = touches.first else {return}
        savePoint(touch: touch, predicted: false)
    }
    
    private func savePoint(touch: UITouch, predicted: Bool) {
        var touchForce: CGFloat
        if touch.type == .direct {
            touchForce = 1
        } else {
            touchForce = touch.force
        }
        let currentPoint = touch.preciseLocation(in: ensuredReferenceView)
        if rect != nil {
            if rect!.minX > currentPoint.x {
                rect!.minX = currentPoint.x
            }
            if rect!.minY > currentPoint.y {
                rect!.minY = currentPoint.y
            }
            if rect!.maxX < currentPoint.x {
                rect!.maxX = currentPoint.x
            }
            if rect!.maxY < currentPoint.y {
                rect!.maxY = currentPoint.y
            }
        } else {
            rect = (minX: currentPoint.x, minY: currentPoint.y, maxX: currentPoint.x, maxY: currentPoint.y)
        }
        if touch.type == .direct {
            if let previousTime = self.previousTime,
                let previousPoint = self.previousPoint {
                let currentTime = CGFloat(touch.timestamp)
                let interval = currentTime - previousTime
                let move = distance(previousPoint, currentPoint)
                let speed = move / interval
                var scale: CGFloat = 1.0
                if scrollView != nil {
                    scale = scrollView!.zoomScale
                }
                if let previousForce = previousForce {
                    if speed > 1000 / scale && previousForce > 0.5 {
                        touchForce = previousForce - 0.1
                    } else if speed < 500 / scale && previousForce < 1.5 {
                        touchForce = previousForce + 0.1
                    } else {
                        touchForce = previousForce
                    }
                }
                self.previousTime = currentTime
                self.previousPoint = currentPoint
                self.previousForce = touchForce
            } else {
                self.previousPoint = currentPoint
                self.previousTime = CGFloat(touch.timestamp)
            }
        }
        touchForce = (touchForce + adjustForce) / 2
        if brush.type == .eraser {
            touchForce = 1
        }
        var point = Point()
        point.force = Float(touchForce)
        point.x = Float(currentPoint.x)
        point.y = Float(currentPoint.y)
        if point.x == stroke.offsetPoints.last?.x && point.y == stroke.offsetPoints.last?.y {
            return
        }
        if stroke.offsetPoints.count == 0 {
            stroke.basePoint = point
        }
        stroke.offsetPoints.append(Point.with{
                                    $0.x = point.x - stroke.basePoint.x
                                    $0.y = point.y - stroke.basePoint.y
                                    $0.force = point.force
        })
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        stroke = Stroke()
        stroke.id = Int64.random(in: Int64.min ... Int64.max)
        stroke.color = brush.color.hexa
        stroke.width = Float(brush.width)
        switch brush.type {
        case .pen:
            stroke.type = .pen
        case .highlighter:
            stroke.type = .highlighter
        default:
            stroke.type = .unknown
        }
        append(touches: touches, event: event)
        state = .began
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if numberOfTouches == 1 {
            gestureDelegate?.firstTouchDetected()
            append(touches: touches, event: event)
            state = .changed
        } else {
            state = .failed
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        append(touches: touches, event: event)
        state = .ended
        self.previousPoint = nil
        self.previousTime = nil
        self.previousForce = nil
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        append(touches: touches, event: event)
    }
}
