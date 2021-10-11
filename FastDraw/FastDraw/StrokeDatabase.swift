//
//  SegmentDatabaseV2.swift
//  FastDraw
//
//  Created by 张睿杰 on 2021/4/5.
//

import Foundation
import SQLite

let strokeTable = Table("strokeTable")
let strokeId = Expression<Int64>("strokeId")
let strokeWidth = Expression<Double>("strokeWidth")
let strokeColor = Expression<Int64>("strokeColor")
let strokeType = Expression<Int>("strokeType")
let basePoint = Expression<Data>("basePoint")
let erasedOffsets = Expression<Data>("erasedOffsets")
let offsetPoints = Expression<Data>("offsetPoints")

public class StrokeDatabase {
    var connection: Connection
    
    // MARK: PUBLIC FUNCTIONS
    
    public func createCurvelist() {
        do {
            try connection.run(strokeTable.create(ifNotExists: true) { t in
                t.column(strokeId, unique: true)
                t.column(strokeWidth)
                t.column(strokeType)
                t.column(basePoint)
                t.column(erasedOffsets)
                t.column(offsetPoints)
                t.column(strokeColor)
            })
            print("create segmentmap table succeeded")
        } catch {
            print("unable to create segmentmap")
        }
    }
    
    public init?(path: String?) {
        do {
            if let path = path {
                self.connection = try Connection("\(path)/db.sqlite3")
            } else {
                self.connection = try Connection(.temporary)
            }
        } catch {
            print("unable to connect to database")
            return nil
        }
        createCurvelist()
    }
    
    public func removeStroke(strokeId: Int64) {
        removeStrokes(strokeIds: [strokeId])
    }
    
    public func removeStrokes(strokeIds: [Int64]) {
        try? connection.run(strokeTable.filter(strokeIds.contains(strokeId)).delete())
    }
    
    public func addStrokes(strokes: [Stroke]) {
        do {
            let encoder = JSONEncoder()
            try connection.transaction {
                for stroke in strokes {
                    try connection.run(strokeTable.insert(or: .ignore,
                                                  strokeId <- Int64(stroke.id),
                                                  strokeColor <- Int64(stroke.color),
                                                  strokeWidth <- Double(stroke.width),
                                                  strokeType <- stroke.type.rawValue,
                                                  basePoint <- try! stroke.basePoint.serializedData(),
                                                  erasedOffsets <- encoder.encode(stroke.erasedOffsets),
                                                  offsetPoints <- encoder.encode(stroke.offsetPoints)))
                }
            }
        } catch {
            print("add strokes failed")
        }
    }
    
    public func addStroke(stroke: Stroke) {
        do {
            let encoder = JSONEncoder()
            try connection.run(strokeTable.insert(or: .ignore,
                                          strokeId <- Int64(stroke.id),
                                          strokeColor <- Int64(stroke.color),
                                          strokeWidth <- Double(stroke.width),
                                          strokeType <- stroke.type.rawValue,
                                          basePoint <- try! stroke.basePoint.serializedData(),
                                          erasedOffsets <- encoder.encode(stroke.erasedOffsets),
                                          offsetPoints <- encoder.encode(stroke.offsetPoints)))
        } catch {
            print("add stroke failed")
        }
    }
    
    /// Used for lasso action to update stroke location
    /// - Parameters:
    ///   - pointDict: a dictionary of points
    public func updateStrokes(pointDict: [Int64: Point]) {
        do {
            try connection.transaction {
                for (id, point) in pointDict {
                    let data = try point.serializedData()
                    try connection.run(strokeTable.filter(strokeId == Int64(id)).update(basePoint <- data))
                }
            }
        } catch {
            print("update Strokes failed \(error)")
        }
    }
    
    
    /// update segments erased dict
    /// - Parameters:
    ///   - erased_dict: uuid and int array dict
    ///   - erased: whether set erased or not erased
    ///   - rewrite: set true to use the int array to override the dict
    public func updateSegmentsErased(erased_dict: [Int64: [UInt64]], erased: Bool = true, rewrite: Bool = false) {
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        do {
            try connection.transaction {
                for (id, erased_array) in erased_dict {
                    if let row = try connection.pluck(strokeTable.filter(strokeId == Int64(id))) {
                        let offsets = try! decoder.decode([UInt64].self, from: row[erasedOffsets])
                        var current_erased_array = Set(offsets)
                        let erasedSet: Set<UInt64>
                        if rewrite {
                            erasedSet = current_erased_array
                        } else {
                            if erased {
                                erasedSet = current_erased_array.union(erased_array)
                            } else {
                                erasedSet = current_erased_array.subtracting(erased_array)
                            }
                        }
                        let data = try encoder.encode(Array(erasedSet))
                        try connection.run(strokeTable.filter(strokeId == Int64(id)).update(erasedOffsets <- data))
                    }
                }
            }
        } catch {
            print("updated segments failed")
        }
    }
    
    public func getCurveErasedIndexes() -> [Int64: [UInt64]] {
        var erased_dict = [Int64: [UInt64]]()
        let decoder = JSONDecoder()
        do {
            let rows = try connection.prepare(strokeTable)
            for row in rows {
                let indexes = try decoder.decode([UInt64].self, from: row[erasedOffsets])
                erased_dict[row[strokeId]] = indexes
            }
        } catch {
            print(error)
        }
        return erased_dict
    }
    
    public func getCurveErasedIndexes(curves: [Int64]) -> [Int64: [UInt64]] {
        var erased_dict = [Int64: [UInt64]]()
        let decoder = JSONDecoder()
        do {
            let rows = try connection.prepare(strokeTable.filter(curves.map{Int64($0)}.contains(strokeId)))
            for row in rows {
                let indexes = try decoder.decode([UInt64].self, from: row[erasedOffsets])
                erased_dict[row[strokeId]] = indexes
            }
        } catch {
            print(error)
        }
        return erased_dict
    }
    
    // MARK: INTERNAL FUNCTIONS
    
    internal func getAllStrokes() -> [Stroke] {
        var strokes = [Stroke]()
        if let rows = try? connection.prepare(strokeTable) {
            for row in rows {
                if let stroke = rowToStroke(row: row) {
                    strokes.append(stroke)
                }
            }
        }
        return strokes
    }
    
    internal func getStroke(id: Int64) -> Stroke? {
        if let row = try? connection.pluck(strokeTable.filter(strokeId == id)) {
            var stroke = Stroke()
            stroke.width = Float(row[strokeWidth])
            stroke.color = UInt32(row[strokeColor])
            stroke.type = Stroke.TypeEnum(rawValue: row[strokeType])!
            stroke.basePoint = try! Point(serializedData: row[basePoint])
            stroke.erasedOffsets = try! JSONDecoder().decode([UInt64].self, from: row[erasedOffsets])
            stroke.offsetPoints = try! JSONDecoder().decode([Point].self, from: row[offsetPoints])
            return stroke
        }
        return nil
    }
    
    func rowToStroke(row: Row) -> Stroke? {
        var stroke = Stroke()
        stroke.width = Float(row[strokeWidth])
        stroke.color = UInt32(row[strokeColor])
        stroke.id = row[strokeId]
        if let type = Stroke.TypeEnum(rawValue: row[strokeType]),
           let basePoint = try? Point(serializedData: row[basePoint]),
           let erasedOffsets = try? JSONDecoder().decode([UInt64].self, from: row[erasedOffsets]),
           let offsetPoints = try? JSONDecoder().decode([Point].self, from: row[offsetPoints]) {
            stroke.type = type
            stroke.basePoint = basePoint
            stroke.erasedOffsets = erasedOffsets
            stroke.offsetPoints = offsetPoints
            return stroke
        }
        return nil
    }
}
