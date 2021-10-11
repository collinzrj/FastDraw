////
////  SegmentDatabase.swift
////  realtimedrawing
////
////  Created by 张睿杰 on 2020/7/11.
////  Copyright © 2020 张睿杰. All rights reserved.
////
//
//import Foundation
//import SQLite
//
//let r_c = Expression<Int>("r")
//let c_c = Expression<Int>("c")
//let curve_uuid_c = Expression<String>("curve_uuid")
//let segment_uuid_c = Expression<String>("segment_uuid")
//let segment_c = Expression<Data>("segment")
//let erased_c = Expression<Bool>("erased")
//let curve_id_c = Expression<Int>("curve_id")
//let curvelist_uuid_c = Expression<String>("curvelist_uuid")
//let curvelist_t = Table("curvelist")
//let segment_index_c = Expression<Int>("segment_index")
//let stroke_c = Expression<Data>("stroke")
//let erased_array_c = Expression<Data?>("erased_array")
//
//// The logic of database and in memory map is different, this is used for the server to check for difference, since memory map is loaded everytime, there is no need to do these things
//// Only read from SegmentDatabase when first used to form the StrokeSegmentMap, then only write to SegmentDatabase but never read from it, SegmentDatabase is not used in calculation, all calculation is done by StrokeSegmentMap, database only do insert and delete row operation
//public class SegmentDatabase {
//    var db: Connection
//    
//    let arrayLength = 10
//    var width: CGFloat
//    var height: CGFloat
//    var tile_width: CGFloat
//    var tile_height: CGFloat
//    
//    // MARK: PUBLIC FUNCTIONS
//    
//    public static func createCurvelist(db: Connection) {
//        do {
//            try db.run(curvelist_t.create(ifNotExists: true) { t in
//                t.column(curve_id_c, primaryKey: .autoincrement)
//                t.column(curvelist_uuid_c, unique: true)
//                t.column(stroke_c)
//                t.column(erased_array_c)
//            })
//            print("create segmentmap table succeeded")
//        } catch {
//            print("unable to create segmentmap")
//        }
//    }
//    
//    public init?(path: String?, size: CGSize) {
//        width = size.width
//        height = size.height
//        tile_width = width / CGFloat(arrayLength)
//        tile_height = height / CGFloat(arrayLength)
//        do {
//            if let path = path {
//                self.db = try Connection("\(path)/db.sqlite3")
//            } else {
//                self.db = try Connection(.temporary)
//            }
//        } catch {
//            print("unable to connect to database")
//            return nil
//        }
//        SegmentDatabase.createCurvelist(db: self.db)
//    }
//    
//    public func removeStroke(uuid: String) {
//        removeStrokes(uuids: [uuid])
//    }
//    
//    public func removeStrokes(uuids: [String]) {
//        try? db.run(curvelist_t.filter(uuids.contains(curvelist_uuid_c)).delete())
//    }
//    
//    public func addStroke(stroke: Stroke) {
//        do {
//            let StrokeData = try JSONEncoder().encode(stroke)
//            let EmptyArray = try JSONEncoder().encode([Int]())
//            try db.run(curvelist_t.insert(or: .ignore, curvelist_uuid_c <- stroke.uuid, stroke_c <- StrokeData, erased_array_c <- EmptyArray))
//        } catch {
//            print("add stroke failed")
//        }
//    }
//    
//    /// Used for lasso action to update stroke location
//    /// - Parameters:
//    ///   - pointDict: a dictionary of points
//    ///   - absolute: whether points are aboslute points or difference between old and new points
//    public func updateStrokes(pointDict: [String: CGPoint], absolute: Bool = true) {
//        do {
//            try db.transaction {
//                for strokeUUID in pointDict.keys {
//                    let rows = try! db.prepare(curvelist_t.filter(curvelist_uuid_c == strokeUUID))
//                    for row in rows {
//                        let stroke = try JSONDecoder().decode(FDStroke.self, from: row[stroke_c])
//                        let firstPoint = stroke.Points.first!.location
//                        let newPoint = pointDict[strokeUUID]!
//                        if absolute {
//                            stroke.move(x: newPoint.x - firstPoint.x,
//                                        y: newPoint.y - firstPoint.y)
//                        } else {
//                            stroke.move(x: newPoint.x, y: newPoint.y)
//                        }
//                        let data = try JSONEncoder().encode(stroke)
//                        try db.run(curvelist_t.filter(curvelist_uuid_c == strokeUUID).update(stroke_c <- data))
//                    }
//                }
//            }
//        } catch {
//        }
//    }
//    
//    
//    /// update segments erased dict
//    /// - Parameters:
//    ///   - erased_dict: uuid and int array dict
//    ///   - erased: whether set erased or not erased
//    ///   - rewrite: set true to use the int array to override the dict
//    public func updateSegmentsErased(erased_dict: [String: [Int]], erased: Bool = true, rewrite: Bool = false) {
//        let decoder = JSONDecoder()
//        let encoder = JSONEncoder()
//        do {
//            try db.transaction {
//                for (curve_uuid, erased_array) in erased_dict {
//                    if let row = try db.pluck(curvelist_t.filter(curvelist_uuid_c == curve_uuid)) {
//                        var current_erased_array = Set<Int>()
//                        if let array_data = row[erased_array_c] {
//                            current_erased_array = try decoder.decode(Set<Int>.self, from: array_data)
//                        }
//                        let erasedSet: Set<Int>
//                        if rewrite {
//                            erasedSet = Set(erased_array)
//                        } else {
//                            if erased {
//                                erasedSet = current_erased_array.union(erased_array)
//                            } else {
//                                erasedSet = current_erased_array.subtracting(erased_array)
//                            }
//                        }
//                        let data = try encoder.encode(erasedSet)
//                        try db.run(curvelist_t.filter(curve_uuid == curvelist_uuid_c).update(erased_array_c <- data))
//                    }
//                }
//            }
//        } catch {
//            print("updated segments failed")
//        }
//    }
//    
//    public func getCurveErasedIndexes() -> [String: [Int]] {
//        var erased_dict = [String: [Int]]()
//        let decoder = JSONDecoder()
//        do {
//            let rows = try db.prepare(curvelist_t)
//            for row in rows {
//                var set = Set<Int>()
//                if let array_data = row[erased_array_c] {
//                    set = try decoder.decode(Set<Int>.self, from: array_data)
//                }
//                let indexes = Array(set)
//                erased_dict[row[curvelist_uuid_c]] = indexes
//            }
//        } catch {
//            print(error)
//        }
//        return erased_dict
//    }
//    
//    public func getCurveErasedIndexes(curves: [String]) -> [String: [Int]] {
//        var erased_dict = [String: [Int]]()
//        let decoder = JSONDecoder()
//        do {
//            let rows = try db.prepare(curvelist_t.filter(curves.contains(curvelist_uuid_c)))
//            for row in rows {
//                var set = Set<Int>()
//                if let array_data = row[erased_array_c] {
//                    set = try decoder.decode(Set<Int>.self, from: array_data)
//                }
//                let indexes = Array(set)
//                erased_dict[row[curvelist_uuid_c]] = indexes
//            }
//        } catch {
//            print(error)
//        }
//        return erased_dict
//    }
//    
//    // MARK: INTERNAL FUNCTIONS
//    
//    internal func getAllStrokes() -> AnySequence<Row>? {
//        let rows = try? db.prepare(curvelist_t)
//        return rows
//    }
//    
//    internal func getStroke(uuid: String) -> FDStroke? {
//        if let row = try? db.pluck(curvelist_t.filter(curvelist_uuid_c == uuid)) {
//            let stroke = try! JSONDecoder().decode(FDStroke.self, from: row[stroke_c])
//            return stroke
//        } else {
//            return nil
//        }
//    }
//}
