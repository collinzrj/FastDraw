//
//  CGMathExtensions.swift
//  realtimedrawing
//
//  Created by 张睿杰 on 2019/11/3.
//  Copyright © 2019 张睿杰. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

// MARK: - CGRect and Size

public extension CGRect {
    var center: CGPoint {
        get {
            return origin + CGVector(dx: width, dy: height) / 2.0
        }
        set {
            origin = newValue - CGVector(dx: width, dy: height) / 2
        }
    }
}

public func +(left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width + right, height: left.height + right)
}

public func -(left: CGSize, right: CGFloat) -> CGSize {
    return left + (-1.0 * right)
}

// MARK: - CGPoint and CGVector math

public func -(left: CGPoint, right: CGPoint) -> CGVector {
    return CGVector(dx: left.x - right.x, dy: left.y - right.y)
}

public func /(left: CGVector, right: CGFloat) -> CGVector {
    return CGVector(dx: left.dx / right, dy: left.dy / right)
}

public func *(left: CGVector, right: CGFloat) -> CGVector {
    return CGVector(dx: left.dx * right, dy: left.dy * right)
}

public func +(left: CGPoint, right: CGVector) -> CGPoint {
    return CGPoint(x: left.x + right.dx, y: left.y + right.dy)
}

public func +(left: CGVector, right: CGVector) -> CGVector {
    return CGVector(dx: left.dx + right.dx, dy: left.dy + right.dy)
}

public func +(left: CGVector?, right: CGVector?) -> CGVector? {
    if let left = left, let right = right {
        return CGVector(dx: left.dx + right.dx, dy: left.dy + right.dy)
    } else {
        return nil
    }
}

public func -(left: CGPoint, right: CGVector) -> CGPoint {
    return CGPoint(x: left.x - right.dx, y: left.y - right.dy)
}

public func calculate_arc_start_radian(start_point: CGPoint, end_point: CGPoint) -> (radian: CGFloat, clockwise: Bool) {
    let stroke_radian = atan((start_point.y - end_point.y) / (end_point.x - start_point.x))
    let radian = stroke_radian + CGFloat.pi / 2
    print(radian)
    if start_point.x < end_point.x {
        return (radian, true)
    } else {
        return (radian, false)
    }
}

public extension CGPoint {
    init(_ vector: CGVector) {
        self.init()
        x = vector.dx
        y = vector.dy
    }
}

public extension CGPoint {
    static func -(left: CGPoint, right: Float) -> CGPoint {
        return CGPoint(x: left.x - CGFloat(right), y: left.y - CGFloat(right))
    }
}

public extension CGPoint {
    mutating func convert(dx: CGFloat, dy: CGFloat) {
        self.x += dx
        self.y += dy
    }
}

public extension CGVector {
    init(_ point: CGPoint) {
        self.init()
        dx = point.x
        dy = point.y
    }
    
    func applying(_ transform: CGAffineTransform) -> CGVector {
        return CGVector(CGPoint(self).applying(transform))
    }
    
    func rounding(toScale scale: CGFloat) -> CGVector {
        return CGVector(dx: CoreGraphics.round(dx * scale) / scale,
                        dy: CoreGraphics.round(dy * scale) / scale)
    }
    
    var quadrance: CGFloat {
        return dx * dx + dy * dy
    }
    
    var normal: CGVector? {
        if !(dx.isZero && dy.isZero) {
            return CGVector(dx: -dy, dy: dx)
        } else {
            return nil
        }
    }
    
    /// CGVector pointing in the same direction as self, with a length of 1.0 - or nil if the length is zero.
    var normalized: CGVector? {
        let quadrance = self.quadrance
        if quadrance > 0.0 {
            return self / sqrt(quadrance)
        } else {
            return nil
        }
    }
}

// QUESTION: MAY THESE TWO FUNCTIONS CRUSH?
public func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    let xDist = a.x - b.x
    let yDist = a.y - b.y
    return CGFloat(sqrt(xDist * xDist + yDist * yDist))
}

public func angle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
    let a_b = distance(a, b)
    let a_c = distance(a, c)
    let b_c = distance(b, c)
    return  acos((a_b * a_b + b_c * b_c - a_c * a_c) / (2 * a_b * b_c))
}

public extension UIBezierPath {
    func addCircle(startPoint: CGPoint, endPoint: CGPoint) {
        let midPoint = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2)
        let radius = distance(startPoint, endPoint) / 2
        self.addArc(withCenter: midPoint,
                    radius: radius,
                    startAngle: 0,
                    endAngle: CGFloat.pi * 2,
                    clockwise: true)
    }
    
    func fillSpace(startPoint: CGPoint, endPoint: CGPoint) {
        let vector = endPoint - startPoint
        let firstPoint = startPoint + vector * 0.1
        let secondPoint = endPoint - vector * 0.1
        self.move(to: firstPoint)
        self.addLine(to: secondPoint)
    }
}

public func check_lines_intersection(firstStart: CGPoint, firstEnd: CGPoint, secondStart: CGPoint, secondEnd: CGPoint) -> Bool {
    let x: CGFloat
    let y: CGFloat
    let k1 = (firstEnd.y - firstStart.y) / (firstEnd.x - firstStart.x)
    let b1 = firstStart.y - k1 * firstStart.x
    let k2 = (secondEnd.y - secondStart.y) / (secondEnd.x - secondStart.x)
    let b2 = secondStart.y - k2 * secondStart.x
    
    if firstStart.x == firstEnd.x && secondStart.x == secondEnd.x {
        if firstStart.x == secondStart.x {
            if min(firstStart.x, firstEnd.x) < min(secondStart.x, secondEnd.x) {
                if max(firstStart.x, firstEnd.x) > min(secondStart.x, secondEnd.x) {
                    return true
                }
            } else {
                if max(secondStart.x, secondEnd.x) > min(firstStart.x, firstEnd.x) {
                    return true
                }
            }
        }
        return false
    } else if firstStart.x == firstEnd.x {
        x = firstStart.x
        y = k2 * x + b2
    } else if secondStart.x == secondEnd.x {
        x = secondStart.x
        y = k1 * x + b1
    } else {
        x = -(b1 - b2) / (k1 - k2)
        y = k1 * x + b1
    }
    
    if ((x >= min(firstStart.x, firstEnd.x) && x <= max(firstStart.x, firstEnd.x)) &&
        (x >= min(secondStart.x, secondEnd.x) && x <= max(secondStart.x, secondEnd.x)) &&
        (y >= min(firstStart.y, firstEnd.y) && y <= max(firstStart.y, firstEnd.y)) &&
        (y >= min(secondStart.y, secondEnd.y) && y <= max(secondStart.y, secondEnd.y))) {
        return true
    }
    return false
}

// solve ternary quadratic function
public func check_line_quadric_bezier_intersection(lineStart: CGPoint, lineEnd: CGPoint, bezierStart: CGPoint, bezierControl: CGPoint, bezierEnd: CGPoint) -> Bool {
    
//    print(lineStart)
//    print(lineEnd)
//    print(bezierStart)
//    print(bezierControl)
//    print(bezierEnd)
//    print("end")
    
    let a = (lineEnd.y - lineStart.y) / (lineEnd.x - lineStart.x)
    let b = lineStart.y - a * lineStart.x
    let k1 = (bezierStart.y - 2 * bezierControl.y + bezierEnd.y) - a * (bezierStart.x - 2 * bezierControl.x + bezierEnd.x)
    let k2 = 2 * (bezierControl.y - bezierStart.y) - 2 * a * (bezierControl.x - bezierStart.x)
    let k3 = bezierStart.y - a * bezierStart.x - b
    let discriminant = k2 * k2 - 4 * k1 * k3
    if discriminant > 0 {
        let root = discriminant.squareRoot()
        let t1 = (-k2 + root) / (2 * k1)
        let t2 = (-k2 - root) / (2 * k1)
        for t in [t1, t2] {
            if t >= 0 && t <= 1 {
                let x = (bezierStart.x - 2 * bezierControl.x + bezierEnd.x) * t * t + 2 * (bezierControl.x - bezierStart.x) * t + bezierStart.x
                let y = (bezierStart.y - 2 * bezierControl.y + bezierEnd.y) * t * t + 2 * (bezierControl.y - bezierStart.y) * t + bezierStart.y
//                print(t, x, y)
//                print(lineStart, lineEnd)
                if x >= min(lineStart.x, lineEnd.x) && x <= max(lineStart.x, lineEnd.x)
                    && y >= min(lineStart.y, lineEnd.y) && y <= max(lineStart.y, lineEnd.y) {
                    return true
                }
            }
        }
    }
    return false
}

public func quadric_bezier_x_to_ts(startPoint: CGPoint, controlPoint: CGPoint, endPoint: CGPoint, x: CGFloat) -> [CGFloat] {
    let a = startPoint.x - 2 * controlPoint.x + endPoint.x
    let b = 2 * (controlPoint.x - startPoint.x)
    let bSquared = b * b
    let c = startPoint.x - x
    var x_ts: [CGFloat] = []
    if a != 0 {
        let discriminant = bSquared - (4 * a * c)
        let isImaginary = discriminant < 0
        let discrimimantAbsSqrt = sqrt(abs(discriminant))
        if !isImaginary {
            let t1 = (-b + discrimimantAbsSqrt) / (2 * a)
            let t2 = (-b - discrimimantAbsSqrt) / (2 * a)
            if 0 < t1 && t1 < 1 {
                x_ts.append(t1)
            }
            if 0 < t2 && t2 < 1 {
                x_ts.append(t2)
            }
        }
    } else {
        let t = -c / b
        x_ts.append(t)
    }
    return x_ts
}

public func quadric_bezier_y_to_ts(startPoint: CGPoint, controlPoint: CGPoint, endPoint: CGPoint, y: CGFloat) -> [CGFloat] {
    let a = startPoint.y - 2 * controlPoint.y + endPoint.y
    let b = 2 * (controlPoint.y - startPoint.y)
    let bSquared = b * b
    let c = startPoint.y - y
    var y_ts: [CGFloat] = []
    if a != 0 {
        let discriminant = bSquared - (4 * a * c)
        let isImaginary = discriminant < 0
        let discrimimantAbsSqrt = sqrt(abs(discriminant))
        if !isImaginary {
            let t1 = (-b + discrimimantAbsSqrt) / (2 * a)
            let t2 = (-b - discrimimantAbsSqrt) / (2 * a)
            if 0 < t1 && t1 < 1 {
                y_ts.append(t1)
            }
            if 0 < t2 && t2 < 1 {
                y_ts.append(t2)
            }
        }
    } else {
        let t = -c / b
        y_ts.append(t)
    }
    return y_ts
}

public func check_point_in_polygon(point: CGPoint, polygon: [(CGPoint, CGPoint)]) -> Bool {
    var count = 0
    for line in polygon {
        let startPoint = line.0
        let endPoint = line.1
        if max(endPoint.x, startPoint.x) < point.x ||
            min(endPoint.x, startPoint.x) > point.x {
            continue
        }
        let bottom = endPoint.x - startPoint.x
        let height = endPoint.y - startPoint.y
        let ratio = height / bottom
        let dx = point.x - startPoint.x
        let dy = dx * ratio
        if startPoint.y + dy > point.y {
            count += 1
        }
    }
    if count % 2 == 1 {
        return true
    }
    return false
}

public func check_clockwise(p: CGPoint, q: CGPoint, r: CGPoint) -> Bool? {
    let k = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
    if (k > 0) {
        return false
    } else if (k < 0) {
        return true
    }
    // ALERT: this mean three points are on a line
    return nil
}

public func getRandians(origin: CGPoint, point: CGPoint) -> CGFloat {
    let y = point.y - origin.y
    let x = point.x - origin.x
    if x > 0 {
        return atan(y / x)
    } else if (x < 0 && y >= 0) {
        return atan(y / x) + CGFloat.pi
    } else if (x < 0 && y < 0) {
        return atan(y / x) - CGFloat.pi
    } else if (x == 0 && y > 0) {
        return CGFloat.pi / 2
    } else if (x == 0 && y < 0) {
        return -CGFloat.pi / 2
    }
    // both zero
    return 0
}

public func getMidPoint(firstPoint: CGPoint, secondPoint: CGPoint) -> CGPoint {
    return CGPoint(x: (firstPoint.x + secondPoint.x) / 2,
                   y: (firstPoint.y + secondPoint.y) / 2)
}
