//
//  StrokeModel.swift
//  realtimedrawing
//
//  Created by 张睿杰 on 2019/11/11.
//  Copyright © 2019 张睿杰. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

/// FastDrawPoint
public struct FDPoint: Codable {
    public var location: CGPoint
    public var force: CGFloat
    public var predicted: Bool
    
    public init(location: CGPoint,
         force: CGFloat,
         predicted: Bool) {
        self.location = location
        self.force = force
        self.predicted = predicted
    }
}


/// FastDrawStroke
public class FDStroke: Codable {
    
    public var uuid: String
    public var color: Color
    public var width: CGFloat
    public var type: BrushType
    
    public init(color: UIColor, width: CGFloat, type: BrushType) {
        self.uuid = UUID().uuidString
        self.color = Color(uiColor: color)
        self.width = width
        self.type = type
    }
    
    public init(uuid: String, color: Color, width: CGFloat, type: BrushType) {
        self.uuid = uuid
        self.color = color
        self.width = width
        self.type = type
    }
    
    public var Points: [FDPoint] = []
    public var predictedPoints: [FDPoint] = []
    
    func add(point: FDPoint) -> Int {
        Points.append(point)
        predictedPoints.removeAll()
        return Points.count - 1
    }
    
    func update(point: FDPoint, index: Int) {
        Points[index] = point
    }
    
    func addPredicted(point: FDPoint) {
        predictedPoints.append(point)
    }
    
    // Double, Float or CGFloat here?
    func move(x: CGFloat, y: CGFloat) {
        for index in 0..<Points.count {
            Points[index].location = Points[index].location + CGVector(dx: x, dy: y)
        }
    }
}

public struct Color: Codable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat?
    
    public init(uiColor: UIColor) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    var uiColor: UIColor {
        return UIColor(red: red, green: green, blue: blue, alpha: alpha ?? 1)
    }
}

public extension UIColor {
  static func == (l: UIColor, r: UIColor) -> Bool {
    var r1: CGFloat = 0
    var g1: CGFloat = 0
    var b1: CGFloat = 0
    var a1: CGFloat = 0
    l.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
    var r2: CGFloat = 0
    var g2: CGFloat = 0
    var b2: CGFloat = 0
    var a2: CGFloat = 0
    r.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
    return r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2
  }
}

//MARK: INTERNAL FUNCTIONS

// has made gesture model to check if two consecutive points are the same, so point index can represent segment index
internal func StrokeToCurve(stroke: Stroke) -> Curve {
    var curve = Curve(id: stroke.id, color: UIColor(hexa: stroke.color))
    // if use count as index of segment, it is the position of point in the stroke points array, but point may be same, segment_index is actually the number of segment in all segments
    var segment_index = 0
    if stroke.type == .pen {
        if stroke.offsetPoints.count < 3 {
            // just for test, make the an optional function in future
            return curve
        }
        var firstPoint = stroke.offsetPoints[0]
        var secondPoint = stroke.offsetPoints[1]
        let basePoint = stroke.basePoint
        let width = CGFloat(stroke.width)
        var increase_normal: CGVector?
        var count = 1
        while increase_normal == nil && count < stroke.offsetPoints.count {
            secondPoint = stroke.offsetPoints[count]
            increase_normal = CGVector(dx: CGFloat(secondPoint.x - firstPoint.x),
                                       dy: CGFloat(secondPoint.y - firstPoint.y)).normalized?.normal
            count += 1
            if count >= stroke.offsetPoints.count {
                return curve
            }
        }
        let firstVector = increase_normal! * CGFloat(firstPoint.force) * width / 2
        var secondVector = increase_normal! * CGFloat(secondPoint.force) * width / 2
        var A = firstPoint.offsetLocation(basePoint: basePoint) + firstVector
        var B = secondPoint.offsetLocation(basePoint: basePoint) + secondVector
        var C = firstPoint.offsetLocation(basePoint: basePoint) - firstVector
        var D = secondPoint.offsetLocation(basePoint: basePoint) - secondVector
        var current_upper = A
        var current_lower = C
        
        while count < stroke.offsetPoints.count {
            firstPoint = secondPoint
            var increase_normal: CGVector?
            increase_normal = CGVector(dx: secondPoint.location.x - firstPoint.location.x,
                                       dy: secondPoint.location.y - firstPoint.location.y).normalized?.normal
            while increase_normal == nil && count < stroke.offsetPoints.count {
                secondPoint = stroke.offsetPoints[count]
                increase_normal = CGVector(dx: secondPoint.location.x - firstPoint.location.x,
                                           dy: secondPoint.location.y - firstPoint.location.y).normalized?.normal
                count += 1
                if count >= stroke.offsetPoints.count && increase_normal == nil {
                    return curve
                }
            }
            A = B
            C = D
            
            secondVector = increase_normal! * CGFloat(secondPoint.force) * width / 2
            B = secondPoint.offsetLocation(basePoint: basePoint) + secondVector
            D = secondPoint.offsetLocation(basePoint: basePoint) - secondVector
            var mid_upper: CGPoint
            var mid_lower: CGPoint
            if count != stroke.offsetPoints.count {
                mid_upper = CGPoint(x: (A.x + B.x) / 2,
                                    y: (A.y + B.y) / 2)
                mid_lower = CGPoint(x: (C.x + D.x) / 2,
                                    y: (C.y + D.y) / 2)
            } else {
                mid_upper = B
                mid_lower = D
            }
            curve.segments.append(StrokeSegment(index: segment_index,
                                                start_upper_point: current_upper,
                                                control_upper_point: A,
                                                end_upper_point: mid_upper,
                                                start_lower_point: current_lower,
                                                control_lower_point: C,
                                                end_lower_point: mid_lower,
                                                parentStrokeId: stroke.id,
                                                color: UIColor(hexa: stroke.color)))
            segment_index += 1
            current_upper = mid_upper
            current_lower = mid_lower
        }
    } else if stroke.type == .highlighter {
        let count = stroke.offsetPoints.count
        let points = stroke.offsetPoints.map { $0.offsetLocation(basePoint: stroke.basePoint) }
        for index in 0..<(count - 1) {
            let firstPoint = points[index]
            let secondPoint = points[index + 1]
            if let increase_normal = CGVector(dx: secondPoint.x - firstPoint.x,
                                              dy: secondPoint.y - firstPoint.y).normalized?.normal {
                let increaseVector = increase_normal * CGFloat(stroke.width) / 2
                let A = firstPoint + increaseVector
                let B = secondPoint + increaseVector
                let C = secondPoint - increaseVector
                let D = firstPoint - increaseVector
                let E = getMidPoint(firstPoint: A, secondPoint: B)
                let F = getMidPoint(firstPoint: C, secondPoint: D)
                let segment = StrokeSegment(index: segment_index,
                                            start_upper_point: A,
                                            control_upper_point: E,
                                            end_upper_point: B,
                                            start_lower_point: D,
                                            control_lower_point: F,
                                            end_lower_point: C,
                                            parentStrokeId: stroke.id,
                                            color: UIColor(hexa: stroke.color))
                segment_index += 1
                curve.segments.append(segment)
            }
        }
    }
    
    return curve
}


