//
//  Extension.swift
//  FastDraw
//
//  Created by 张睿杰 on 2021/4/4.
//

import Foundation

extension UIColor {
    var hexa: UInt32 {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        var value: UInt32 = 0
        value += UInt32(alpha * 255) << 24
        value += UInt32(red   * 255) << 16
        value += UInt32(green * 255) << 8
        value += UInt32(blue  * 255)
        return value
    }
    convenience init(hexa: UInt32) {
        self.init(red  : CGFloat((hexa & 0xFF0000)   >> 16) / 255,
                  green: CGFloat((hexa & 0xFF00)     >> 8)  / 255,
                  blue : CGFloat( hexa & 0xFF)              / 255,
                  alpha: CGFloat((hexa & 0xFF000000) >> 24) / 255)
    }
}

extension Point {
    /// Convert Point to CGPoint
    var location: CGPoint {
        get {
            return CGPoint(x: CGFloat(x), y: CGFloat(y))
        }
    }
    
    /// Convert Point to actual CGPoint offset by basePoint
    /// - Parameter basePoint: basePoint of the stroke
    /// - Returns: absolute location
    func offsetLocation(basePoint: Point) -> CGPoint {
        return CGPoint(x: CGFloat(x + basePoint.x),
                       y: CGFloat(y + basePoint.y))
    }
}

extension Point: Codable {
    enum CodingKeys: String, CodingKey {
        case x
        case y
        case force
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.x = try values.decode(Float.self, forKey: .x)
        self.y = try values.decode(Float.self, forKey: .y)
        self.force = try values.decode(Float.self, forKey: .force)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(force, forKey: .force)
    }
}
