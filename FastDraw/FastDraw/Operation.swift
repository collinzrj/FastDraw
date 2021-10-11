//
//  Operation.swift
//  realtimedrawing
//
//  Created by 张睿杰 on 2020/4/18.
//  Copyright © 2020 张睿杰. All rights reserved.
//

import Foundation
import CoreGraphics

public enum OperationType: String, Codable {
    case draw = "Draw"
    case erase = "Erase"
    case lasso = "Lasso"
}

public class FastOperation: NSObject, Codable {
    public let type: OperationType
    public var isUndo: Bool = false
    
    init(type: OperationType) {
        self.type = type
    }
}

public class DrawOperation: FastOperation {
    public var stroke: Stroke
    
    public init(stroke: Stroke) {
        self.stroke = stroke
        super.init(type: .draw)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

public class EraseOperation: FastOperation {
    public var erasedDict: [Int64: [UInt64]]
    
    public init(erasedDict: [Int64: [UInt64]]) {
        self.erasedDict = erasedDict
        super.init(type: .erase)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

public class LassoOperation: FastOperation {
    public var newDict: [Int64: Point]
    public var removedDict: [Int64: Point]

    public init(newDict: [Int64: Point], removedDict: [Int64: Point]) {
        self.newDict = newDict
        self.removedDict = removedDict
        super.init(type: .lasso)
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

