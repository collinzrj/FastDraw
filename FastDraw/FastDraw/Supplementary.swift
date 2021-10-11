//
//  Supplementary.swift
//  FastDraw
//
//  Created by 张睿杰 on 2021/2/11.
//

import Foundation
import UIKit

public let PenColors: [UIColor] = [#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), #colorLiteral(red: 0.9994240403, green: 0.9855536819, blue: 0, alpha: 1), #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1), #colorLiteral(red: 0.6679978967, green: 0.4751212597, blue: 0.2586010993, alpha: 1), #colorLiteral(red: 0.8321695924, green: 0.985483706, blue: 0.4733308554, alpha: 1), #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1), #colorLiteral(red: 1, green: 0.2527923882, blue: 1, alpha: 1), #colorLiteral(red: 1, green: 0.1857388616, blue: 0.5733950138, alpha: 1), #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 1), #colorLiteral(red: 0.5791940689, green: 0.1280144453, blue: 0.5726861358, alpha: 1), #colorLiteral(red: 1, green: 0.5409764051, blue: 0.8473142982, alpha: 1), #colorLiteral(red: 0.4513868093, green: 0.9930960536, blue: 1, alpha: 1), #colorLiteral(red: 0.4620226622, green: 0.8382837176, blue: 1, alpha: 1), #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1), #colorLiteral(red: 0.8321695924, green: 0.985483706, blue: 0.4733308554, alpha: 1)]

public enum NotebookType: String {
    case client = "client"
    case server = "server"
    case market = "market"
}

public func check_alpha(color: UIColor) -> CGFloat {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return alpha
}

public enum BrushType: String, Codable {
    case pen = "pen"
    case highlighter = "highlighter"
    case eraser = "eraser"
    case lasso = "lasso"
}

public class Brush {
    public static let shared = Brush()
    
    public var type: BrushType
    public var colorIndex: Int?
    public var color: UIColor = .black
    public var width: CGFloat = 3.2
    
    private init() {
        self.type = .pen
        self.colorIndex = 0
        self.color = PenColors[0]
        self.width = 5
    }
}


public class NewBrush {
    public static let shared = NewBrush()
    
    public var type: BrushType
    public var colorIndex: Int?
    public var color: UIColor = .black
    public var width: CGFloat = 3.2
    
    init() {
        self.type = .pen
        self.colorIndex = 0
        self.color = .black
        self.width = 10
    }
}

