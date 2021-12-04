//
//  StrokeSegmentMap.swift
//  realtimedrawing
//
//  Created by 张睿杰 on 2020/3/10.
//  Copyright © 2020 张睿杰. All rights reserved.
//

import Foundation
import UIKit
import os.log

public struct Tile: Hashable {
    let r: Int
    let c: Int
    
    init(r: Int, c: Int) {
        self.r = r
        self.c = c
    }
}

public struct Line: Codable {
    var startPoint: CGPoint
    var endPoint: CGPoint
}

public enum IntersectionType {
    case intersected
    case covered
    case empty
}

struct Curve {
    var id: Int64
    var color: UIColor
    var segments: [StrokeSegment] = []
    
    init(id: Int64) {
        self.id = id
        self.color = UIColor.black
    }
    
    init(id: Int64, color: UIColor) {
        self.id = id
        self.color = color
    }
    
    mutating func convert(dx: CGFloat, dy: CGFloat) {
        for index in 0..<segments.count {
            segments[index].convert(dx: dx, dy: dy)
        }
    }
    
    func getFirstPoint() -> CGPoint? {
        if let firstSegment = segments.first {
            return CGPoint(x: (firstSegment.start_upper_point.x + firstSegment.start_lower_point.x) / 2,
                           y: (firstSegment.start_upper_point.y + firstSegment.start_lower_point.y) / 2)
        }
        return nil
    }
}

public struct MapRow {
    var tile: Tile
    var segment: StrokeSegment
    var curveId: Int64
    var erased: Bool
    
    public init(tile: Tile, segment: StrokeSegment, curveId: Int64, erased: Bool) {
        self.tile = tile
        self.segment = segment
        self.curveId = curveId
        self.erased = erased
    }
}

public struct MapTable {
    private var table: [Int: MapRow]
    private var index: Int
    
    public init() {
        self.table = [:]
        self.index = 0
    }
    
    func get(index: Int) -> MapRow? {
        return table[index]
    }
    
    func getAll() -> [Int: MapRow] {
        return table
    }
    
    func countRows() -> Int {
        return index
    }
    
    mutating func add(row: MapRow) -> Int {
        let currentIndex = index
        table[currentIndex] = row
        index += 1
        return currentIndex
    }
    
    mutating func remove(index: Int) {
        table.removeValue(forKey: index)
    }
    
    mutating func updateErased(index: Int, erased: Bool) {
        table[index]?.erased = erased
    }
}

/// index property should only be used to determine first point and identify which point to erase, it does not represent a mapping relationship between stroke to curve
public struct StrokeSegment {
    public var paths: [UIBezierPath]
    public var index: Int
    public var start_upper_point: CGPoint
    public var control_upper_point: CGPoint
    public var end_upper_point: CGPoint
    public var start_lower_point: CGPoint
    public var control_lower_point: CGPoint
    public var end_lower_point: CGPoint
    public var parentStrokeId: Int64
    public var segment_uuid: String
    public var color: UIColor
    
    public init(index: Int, start_upper_point: CGPoint, control_upper_point: CGPoint, end_upper_point: CGPoint, start_lower_point: CGPoint, control_lower_point: CGPoint, end_lower_point: CGPoint, parentStrokeId: Int64, color: UIColor) {
        self.index = index
        self.start_upper_point = start_upper_point
        self.control_upper_point = control_upper_point
        self.end_upper_point = end_upper_point
        self.start_lower_point = start_lower_point
        self.control_lower_point = control_lower_point
        self.end_lower_point = end_lower_point
        self.parentStrokeId = parentStrokeId
        self.segment_uuid = UUID().uuidString
        self.color = color
        
        let isClockWise = check_clockwise(p: start_upper_point, q: end_upper_point, r: end_lower_point) ?? true
        
        let path = UIBezierPath()
        path.move(to: start_upper_point)
        path.addQuadCurve(to: end_upper_point, controlPoint: control_upper_point)
        
        let midPoint = CGPoint(x: (end_upper_point.x + end_lower_point.x) / 2,
                               y: (end_upper_point.y + end_lower_point.y) / 2)
        let radius = distance(end_upper_point, end_lower_point) / 2
        let startAngle = getRandians(origin: midPoint, point: end_upper_point)
        let endAngle = getRandians(origin: midPoint, point: end_lower_point)
        path.addArc(withCenter: midPoint, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: isClockWise)
        
        path.addQuadCurve(to: start_lower_point, controlPoint: control_lower_point)
        
        let midPoint2 = CGPoint(x: (start_lower_point.x + start_upper_point.x) / 2,
                               y: (start_lower_point.y + start_upper_point.y) / 2)
        let radius2 = distance(start_lower_point, start_upper_point) / 2
        let startAngle2 = getRandians(origin: midPoint2, point: start_lower_point)
        let endAngle2 = getRandians(origin: midPoint2, point: start_upper_point)
        path.addArc(withCenter: midPoint2, radius: radius2, startAngle: startAngle2, endAngle: endAngle2, clockwise: isClockWise)
        
        paths = [path]
    }
    
    func getRect() -> CGRect {
        var rect = paths[0].bounds
        return rect
    }
    
    mutating func convert(dx: CGFloat, dy: CGFloat) {
        self.start_upper_point.convert(dx: dx, dy: dy)
        self.control_upper_point.convert(dx: dx, dy: dy)
        self.end_upper_point.convert(dx: dx, dy: dy)
        self.end_lower_point.convert(dx: dx, dy: dy)
        self.control_lower_point.convert(dx: dx, dy: dy)
        self.start_lower_point.convert(dx: dx, dy: dy)
        self.segment_uuid = UUID().uuidString
        
        let isClockWise = check_clockwise(p: start_upper_point, q: end_upper_point, r: end_lower_point) ?? true
        
        let path = UIBezierPath()
        path.move(to: start_upper_point)
        path.addQuadCurve(to: end_upper_point, controlPoint: control_upper_point)
        
        let midPoint = CGPoint(x: (end_upper_point.x + end_lower_point.x) / 2,
                               y: (end_upper_point.y + end_lower_point.y) / 2)
        let radius = distance(end_upper_point, end_lower_point) / 2
        let startAngle = getRandians(origin: midPoint, point: end_upper_point)
        let endAngle = getRandians(origin: midPoint, point: end_lower_point)
        path.addArc(withCenter: midPoint, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: isClockWise)
        
        path.addQuadCurve(to: start_lower_point, controlPoint: control_lower_point)
        
        let midPoint2 = CGPoint(x: (start_lower_point.x + start_upper_point.x) / 2,
                               y: (start_lower_point.y + start_upper_point.y) / 2)
        let radius2 = distance(start_lower_point, start_upper_point) / 2
        let startAngle2 = getRandians(origin: midPoint2, point: start_lower_point)
        let endAngle2 = getRandians(origin: midPoint2, point: start_upper_point)
        path.addArc(withCenter: midPoint2, radius: radius2, startAngle: startAngle2, endAngle: endAngle2, clockwise: isClockWise)
        
        paths = [path]
    }
}

private struct StrokeInCurveArray: Codable {
    
    var id: Int64
    var number: Int
    
    init(id: Int64, index: Int) {
        self.id = id
        self.number = index
    }
}

internal struct CurveArray {
    private var array: [Int: StrokeInCurveArray]
    private var dict: [Int64: Int]
    private var _index: Int
    var index: Int {
        return _index
    }
    
    init() {
        self.array = [:]
        self.dict = [:]
        self._index = 0
    }
    
    mutating func addCurve(id: Int64) {
        let stroke = StrokeInCurveArray(id: id, index: _index)
        dict[id] = _index
        array[_index] = stroke
        _index += 1
    }
    
    mutating func getIndex(id: Int64) -> Int {
        return dict[id] ?? 0
    }
    
    mutating func getAllCurves() -> [Int64] {
        var curves: [Int64] = []
        for i in 0..._index {
            if let curve = array[i] {
                curves.append(curve.id)
            }
        }
        return curves
    }
    
    mutating func removeCurve(id: Int64) {
        if let index = dict[id] {
            dict.removeValue(forKey: id)
            array.removeValue(forKey: index)
        }
    }
}

class StrokeSegmentMap {
    
    // CurveSegmentDict {CurveUUID : Segments Index in Curve : Rows Indexes in Table}
    var CurveSegmentDict: [Int64: [Int: [Int]]] = [:]
    var curveArray = CurveArray()
    var tileDict: [Tile: [Int]] = [:]
    var segmentDict: [String: [Int]] = [:]
    var table: MapTable = MapTable()
    
    private var arrayLength = 10
    private var width: CGFloat
    private var height: CGFloat
    private var tile_width: CGFloat
    private var tile_height: CGFloat
    
    var segmentdatabase: StrokeDatabase?
    
    init(segmentdatabase: StrokeDatabase, size: CGSize) {
        self.segmentdatabase = segmentdatabase
        tile_width = size.width / CGFloat(arrayLength)
        tile_height = size.height / CGFloat(arrayLength)
        width = size.width
        height = size.height
        let strokes = segmentdatabase.getAllStrokes()
        for stroke in strokes {
            let curve = StrokeToCurve(stroke: stroke)
            addCurve(curve: curve, erasedArray: Set(stroke.erasedOffsets.map{Int($0)}))
        }
    }
    
    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
        self.tile_width = width / CGFloat(arrayLength)
        self.tile_height = height / CGFloat(arrayLength)
    }
    
    //MARK: PUBLIC FUNCTIONS
    
    //MARK: edit methods
    
    func updateStrokes(pointDict: [Int64: Point]) {
        let curves = [Int64] (pointDict.keys)
        let erasedDict = segmentdatabase?.getCurveErasedIndexes(curves: curves)
        for (id, point) in pointDict {
            if var stroke = segmentdatabase?.getStroke(id: id) {
                stroke.basePoint = point
                self.removeStroke(id: id)
                self.addStroke(stroke: stroke)
            }
        }
    }
    
    @discardableResult
    func addStroke(stroke: Stroke) -> [MapRow] {
        let curve = StrokeToCurve(stroke: stroke)
        return addCurve(curve: curve, erasedArray: Set(stroke.erasedOffsets.map { Int($0) }))
    }
    
    func removeStroke(id: Int64) {
        if let IndexDict = CurveSegmentDict[id] {
            for TableIndexes in IndexDict.values {
                for index in TableIndexes {
                    if let maprow = table.get(index: index) {
                        segmentDict.removeValue(forKey: maprow.segment.segment_uuid)
                    }
                    table.remove(index: index)
                }
            }
            CurveSegmentDict.removeValue(forKey: id)
            curveArray.removeCurve(id: id)
        }
    }
    
    func updateSegmentErased(erasedDict: [Int64: [UInt64]], erased: Bool) {
        for strokeUUID in erasedDict.keys {
            for erasedIndex in erasedDict[strokeUUID]! {
                if let TableIndexes = CurveSegmentDict[strokeUUID]?[Int(erasedIndex)] {
                    for index in TableIndexes {
                        table.updateErased(index: index, erased: erased)
                    }
                }
            }
        }
    }
    
    func eraseSegments(A: CGPoint, B: CGPoint, width: CGFloat) -> ([StrokeSegment], CGRect?) {
        var minX: CGFloat?
        var maxX: CGFloat?
        var minY: CGFloat?
        var maxY: CGFloat?
        var erased_segments: [StrokeSegment] = []
        let tiles = checkLineIntersection(A: A, B: B)
        for tile in tiles {
            for (_, maprow) in getRowFromTable(tile: tile) {
                if checkEraserSegmentIntersection(A: A, B: B, width: width, segment: maprow.segment) {
                    var count = 1
                    if let RowIndexes = segmentDict[maprow.segment.segment_uuid] {
                        for RowIndex in RowIndexes {
                            table.updateErased(index: RowIndex, erased: true)
                            count += 1
                        }
                    }
                    erased_segments.append(maprow.segment)
                    let rect = maprow.segment.getRect()
                    if minX == nil || minX! > rect.minX {
                        minX = rect.minX
                    }
                    if maxX == nil || maxX! < rect.maxX {
                        maxX = rect.maxX
                    }
                    if minY == nil || minY! > rect.minY {
                        minY = rect.minY
                    }
                    if maxY == nil || maxY! < rect.maxY {
                        maxY = rect.maxY
                    }
                }
            }
        }
        var minRect: CGRect?
        if minX != nil {
            minRect = CGRect(x: minX!, y: minY!, width: (maxX! - minX!), height: maxY! - minY!)
        }
        return (erased_segments, minRect)
    }
    
    // MARK: get info methods
    
    func getAllStrokes() -> [Int64] {
        return curveArray.getAllCurves()
    }
    
    func getIndex(id: Int64) -> Int {
        return curveArray.getIndex(id: id)
    }
    
    func drawImage(pdfpage: CGPDFPage, url: URL) {
        let pageFrame = pdfpage.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageFrame.size)
        let image = renderer.image { context in
            let ctx = context.cgContext
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: pageFrame.size))
            ctx.saveGState()
            ctx.scaleBy(x: 1, y: -1)
            ctx.translateBy(x: 0, y: -pageFrame.size.height)
            ctx.drawPDFPage(pdfpage)
            ctx.restoreGState()
            contextDrawStrokes()
        }
        let data = image.pngData()
        try? data?.write(to: url)
    }
    
    func drawImage(frame: CGRect, url: URL) {
        let renderer = UIGraphicsImageRenderer(size: frame.size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: frame.size))
            contextDrawStrokes()
        }
        let data = image.pngData()
        try? data?.write(to: url)
    }
    
    func drawPDF(pdfpage: CGPDFPage, url: URL) {
        UIGraphicsBeginPDFContextToFile(url.path, CGRect.zero, nil)
        let pageFrame = pdfpage.getBoxRect(.mediaBox)
        UIGraphicsBeginPDFPageWithInfo(pageFrame, nil)
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()
        ctx.scaleBy(x: 1, y: -1)
        ctx.translateBy(x: 0, y: -pageFrame.size.height)
        ctx.drawPDFPage(pdfpage)
        ctx.restoreGState()
        contextDrawStrokes()
        UIGraphicsEndPDFContext()
    }
    
    func drawPDF(frame: CGRect, url: URL) {
        UIGraphicsBeginPDFContextToFile(url.path, CGRect.zero, nil)
        UIGraphicsBeginPDFPageWithInfo(frame, nil)
        contextDrawStrokes()
        UIGraphicsEndPDFContext()
    }

    // backward compatibility
    func drawPDF(pdfpage: CGPDFPage, path: String) {
        if let url = URL(string: path) {
            drawPDF(pdfpage: pdfpage, url: url)
        }
    }
    
    //MARK: INTERNAL FUNCTIONS
    
    @discardableResult
    internal func addCurve(curve: Curve, erasedArray: Set<Int> = Set<Int>()) -> [MapRow] {
        let t1 = CFAbsoluteTimeGetCurrent()
        var all_rows: [MapRow] = []
        for (index, segment) in curve.segments.enumerated() {
            var erased = false
            if erasedArray.contains(index) {
                erased = true
                continue
            }
            let rows = addSegment(segment: segment, erased: erased)
            all_rows.append(contentsOf: rows)
        }
        let t2 = CFAbsoluteTimeGetCurrent()
        print("add one curve time \(t2 - t1), \(all_rows.count)")
        return all_rows
    }
    
    internal func getTiles(rect: CGRect) -> [Tile] {
        var numbers: [Int] = []
        // start_row
        numbers.append(Int((rect.minY / tile_height).rounded(.down)))
        // start_column
        numbers.append(Int((rect.minX / tile_width).rounded(.down)))
        // end_row
        var end_row = rect.maxY / tile_height
        let end_row_rounded = end_row.rounded(.down)
        if end_row == end_row_rounded {
            end_row = end_row_rounded - 1
        } else {
            end_row = end_row_rounded
        }
        numbers.append(Int(end_row))
        // end_column
        var end_column = rect.maxX / tile_width
        let end_column_rounded = end_column.rounded(.down)
        if end_column == end_column_rounded {
            end_column = end_column_rounded - 1
        } else {
            end_column = end_column_rounded
        }
        numbers.append(Int(end_column))
        for index in 0 ..< numbers.count {
            if numbers[index] > arrayLength {
                numbers[index] = arrayLength
            } else if numbers[index] < 0 {
                numbers[index] = 0
            }
        }
        var tiles: [Tile] = []
        for row in numbers[0] ... numbers[2] {
            for column in numbers[1] ... numbers[3] {
                tiles.append(Tile(r: row, c: column))
            }
        }
        return tiles
    }
    
    internal func addRow(segment: StrokeSegment, tile: Tile, erased: Bool) -> MapRow {
        let maprow = MapRow(tile: tile,
                            segment: segment,
                            curveId: segment.parentStrokeId,
                            erased: erased)
        let index = table.add(row: maprow)
        if CurveSegmentDict[segment.parentStrokeId] == nil {
            CurveSegmentDict[segment.parentStrokeId] = [segment.index: [index]]
            curveArray.addCurve(id: segment.parentStrokeId)
        } else {
            if CurveSegmentDict[segment.parentStrokeId]![segment.index] == nil {
                CurveSegmentDict[segment.parentStrokeId]![segment.index] = [index]
            } else {
                CurveSegmentDict[segment.parentStrokeId]![segment.index]?.append(index)
            }
        }
        if tileDict[tile] == nil {
            tileDict[tile] = [index]
        } else {
            tileDict[tile]?.append(index)
        }
        if segmentDict[segment.segment_uuid] == nil {
            segmentDict[segment.segment_uuid] = [index]
        } else {
            segmentDict[segment.segment_uuid]?.append(index)
        }
        return maprow
    }
    
    internal func getRowFromTable(tile: Tile) -> [(Int, MapRow)] {
        var maprows: [(Int, MapRow)] = []
        if let indexes = tileDict[tile] {
            for index in indexes {
                // the row may have been deleted, in that case, clear the row to save memory
                if let maprow = table.get(index: index) {
                    if !maprow.erased {
                        maprows.append((index, maprow))
                    }
                } else {
                    tileDict[tile] = tileDict[tile]!.filter { $0 != index}
                }
            }
        }
        return maprows
    }
    
    internal func checkPointInLasso(point: CGPoint, lasso: [CGPoint]) -> Bool {
        let lines = createLines(points: lasso)
        let formatted_lines = formatLines(lines: lines)
        let line_dict = mapLines(formatted_lines: formatted_lines)
        let formatted_point = CGPoint(x: point.x / tile_width, y: point.y / tile_height)
        let column = Int(formatted_point.x.rounded(.down))
        var count = 0
        var ok = false
        if let column_lines = line_dict[column] {
            for line in column_lines {
                // skip if not between the line
                let startPoint = CGPoint(x: line.startPoint.x * tile_width,
                                         y: line.startPoint.y * tile_height)
                let endPoint = CGPoint(x: line.endPoint.x * tile_width,
                                       y: line.endPoint.y * tile_height)
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
                ok = true
            }
        }
        return ok
    }
    
    /// It is another version of the find_covered_sqaures
    /// - Parameter lasso: CGPoints describe the lasso
    internal func findCurvesInLasso(lasso: [CGPoint]) -> Set<Int64> {
        var curves_uuid = Set<Int64>()
        
        let lines = createLines(points: lasso)
        let formatted_lines = formatLines(lines: lines)
        let line_dict = mapLines(formatted_lines: formatted_lines)
        let covered_sqaures = lineDictToSquare(line_dict: line_dict)
        for covered in covered_sqaures.covered {
            if let indexes = tileDict[covered] {
                for index in indexes {
                    if let maprow = table.get(index: index) {
                        if maprow.erased {
                            continue
                        }
                        curves_uuid.insert(maprow.curveId)
                    }
                }
            }
        }
        for intersected in covered_sqaures.intersected {
            if let indexes = tileDict[intersected] {
                for index in indexes {
                    if let maprow = table.get(index: index) {
                        if maprow.erased {
                            continue
                        }
                        let segment = maprow.segment
                        if curves_uuid.contains(segment.parentStrokeId) {
                            continue
                        }
                        if let lines = line_dict[intersected.c] {
                            if checkSegment(segment: segment, lines: lines, column: intersected.c) {
                                curves_uuid.insert(segment.parentStrokeId)
                            }
                        }
                    }
                }
            }
        }
        return curves_uuid
    }
    
    // should remove repetitive segments to avoid being converted twice
    internal func getSegmentsFromTable(id: Int64) -> [StrokeSegment] {
        var segment_uuids: [String] = []
        var segments: [StrokeSegment] = []
        if let indexes = CurveSegmentDict[id]?.values {
            for TableIndexes in indexes {
                for index in TableIndexes {
                    if let maprow = table.get(index: index) {
                        if !segment_uuids.contains(maprow.segment.segment_uuid) && !maprow.erased {
                            segments.append(maprow.segment)
                            segment_uuids.append(maprow.segment.segment_uuid)
                        }
                    } else {
                        CurveSegmentDict[id] = CurveSegmentDict[id]!.filter { !$0.value.contains(index) }
                    }
                }
            }
        }
        return segments
    }
    
    //MARK: PRIVATE FUNCTIONS
    
    /// This is actually an approximation, since a small line can not be too long can cross many tiles,
    /// so use the rectangle of it does not make too much waste of calculation
    private func checkLineIntersection(A: CGPoint, B: CGPoint) -> Set<Tile> {
        let x1 = min(A.x, B.x)
        let x2 = max(A.x, B.x)
        let y1 = min(A.y, B.y)
        let y2 = max(A.y, B.y)
        let c1 = Int((x1 / self.tile_width).rounded(.down))
        let c2 = Int((x2 / self.tile_width).rounded(.down))
        let r1 = Int((y1 / self.tile_height).rounded(.down))
        let r2 = Int((y2 / self.tile_height).rounded(.down))
        var tiles: Set<Tile> = []
        for c in c1 ... c2 {
            for r in r1 ... r2 {
                tiles.insert(Tile(r: r, c: c))
            }
        }
        return tiles
    }
    
    // ALERT: MAY CONSIDER CHECK BEZIER CURVE IN FUTURE
    private func checkEraserSegmentIntersection(A: CGPoint, B: CGPoint, width: CGFloat, segment: StrokeSegment) -> Bool {
        if let increase_normal = CGVector(dx: B.x - A.x,
                                          dy: B.y - A.y).normalized?.normal {
            let increase_vector = increase_normal * width / 2
            let firstUpper = A + increase_vector
            let firstLower = A - increase_vector
            let secondUpper = B + increase_vector
            let secondLower = B - increase_vector
            let eraser_lines = [(firstUpper, secondUpper), (secondUpper, secondLower),
                                (secondLower, firstLower), (firstLower, firstUpper)]
            let segment_lines = [(segment.start_upper_point, segment.end_upper_point),
                                 (segment.end_upper_point, segment.end_lower_point),
                                 (segment.end_lower_point, segment.start_lower_point),
                                 (segment.start_lower_point, segment.start_upper_point)]
            for eraser_line in eraser_lines {
                for segment_line in segment_lines {
                    if check_lines_intersection(firstStart: eraser_line.0, firstEnd: eraser_line.1,
                                                secondStart: segment_line.0, secondEnd: segment_line.1) {
                        return true
                    }
                }
            }
            if check_point_in_polygon(point: A, polygon: segment_lines) {
                return true
            }
            if check_point_in_polygon(point: segment.start_upper_point, polygon: eraser_lines) {
                return true
            }
        }
        return false
    }
    
    /// check tiles covered by segment and add segment
    private func addSegment(segment: StrokeSegment, erased: Bool = false) -> [MapRow] {
        let points1 = divideQuadricBezier(A: segment.start_upper_point,
                                            B: segment.control_upper_point,
                                            C: segment.end_upper_point)
        let points2 = divideQuadricBezier(A: segment.end_lower_point,
                                            B: segment.control_lower_point,
                                            C: segment.start_lower_point)
        let polygon = points1 + points2
        let tiles = findCoveredSquares(polygon: polygon)
        var rows: [MapRow] = []
        for tile in tiles.covered {
            let row = addRow(segment: segment, tile: tile, erased: erased)
            rows.append(row)
        }
        for tile in tiles.intersected {
            if tile.c <= arrayLength && tile.r <= arrayLength
                && tile.c >= 0 && tile.r >= 0 {
                let row = addRow(segment: segment, tile: tile, erased: erased)
                rows.append(row)
            }
        }
        return rows
    }
    
    
    // get intersections of column lines with the segment
    private func divideQuadricBezier(A: CGPoint, B: CGPoint, C: CGPoint) -> [CGPoint] {
        var minX: CGFloat
        var maxX: CGFloat
        var minC: Int
        var maxC: Int
        let X = [A.x, B.x, C.x]
        let Y = [A.y, B.y, C.y]
        // create array to store points and append first point
        var points: [CGPoint] = [CGPoint(x: X[0], y: Y[0])]
        // check for upper point
        minX = min(X[0], X[1], X[2])
        maxX = max(X[0], X[1], X[2])
        // find possible columns
        minC = Int((minX / self.tile_width).rounded(.down))
        maxC = Int((maxX / self.tile_width).rounded(.up))
        // solve equation for (x,t) pairs
        let a = X[0] - 2 * X[1] + X[2]
        let b = 2 * (X[1] - X[0])
        let bSquared = b * b
        var x_t: [(x: CGFloat, t: CGFloat)] = []
        for column in (minC + 1) ..< maxC {
            let x = CGFloat(column) * self.tile_width
            let c = X[0] - x
            // a can be zero when equation of x is linear
            if a != 0 {
                let discriminant = bSquared - (4 * a * c)
                let isImaginary = discriminant < 0
                let discrimimantAbsSqrt = sqrt(abs(discriminant))
                if !isImaginary {
                    let t1 = (-b + discrimimantAbsSqrt) / (2 * a)
                    let t2 = (-b - discrimimantAbsSqrt) / (2 * a)
                    if 0 < t1 && t1 < 1 {
                        x_t.append((x: x, t: t1))
                    }
                    if 0 < t2 && t2 < 1 {
                        x_t.append((x: x, t: t2))
                    }
                }
            } else {
                let t = -c / b
                x_t.append((x: x, t: t))
            }
        }
        // sort pairs to get correct order of pairs
        // ALERT: CRUSH HERE OCCASIONALLY BUT DID NOT KNOW WHY
        x_t.sort {
            $0.t < $1.t
        }
        for pair in x_t {
            let t = pair.t
            let x = pair.x
            let y = (Y[0] - 2 * Y[1] + Y[2]) * (t * t) + 2 * (Y[1] - Y[0]) * t + Y[0]
            points.append(CGPoint(x: x, y: y))
        }
        points.append(CGPoint(x: X[2], y: Y[2]))
        return points
    }
    
    // ALERT: IF LASSO IS TOO SMALL (SMALLER THAN A TILE), PROBLEM MAY OCCUR
    private func checkSegment(segment: StrokeSegment, lines: [Line], column: Int) -> Bool {
        let points: [CGPoint] = [segment.start_lower_point, segment.control_lower_point, segment.end_lower_point,
                                 segment.start_upper_point, segment.control_upper_point, segment.end_upper_point]
        var ok = false
        for point in points {
            let point_column = Int((point.x / tile_width).rounded(.down))
            if point_column != column {
                continue
            }
            var count = 0
            for line in lines {
                // skip if not between the line
                let startPoint = CGPoint(x: line.startPoint.x * tile_width,
                                         y: line.startPoint.y * tile_height)
                let endPoint = CGPoint(x: line.endPoint.x * tile_width,
                                       y: line.endPoint.y * tile_height)
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
                ok = true
                break
            }
        }
        return ok
    }
    
    private func findCoveredSquares(polygon: [CGPoint]) -> (covered: Set<Tile>, intersected: Set<Tile>) {
        let lines = createLines(points: polygon)
        let formatted_lines = formatLines(lines: lines)
        let line_dict = mapLines(formatted_lines: formatted_lines)
        let covered_sqaures = lineDictToSquare(line_dict: line_dict)
        return covered_sqaures
    }
    
    /// find squares covered by the polygon
    /// - Parameter polygon: points describe a polygon
    private func lineDictToSquare(line_dict: [Int: [Line]]) -> (covered: Set<Tile>, intersected: Set<Tile>) {
        var covered_sqaures: (covered: Set<Tile>, intersected: Set<Tile>) = (covered: Set<Tile>(), intersected: Set<Tile>())
        for (column, lines) in line_dict {
            var lower_bound = lines[0].startPoint.y
            var upper_bound = lines[0].startPoint.y
            for line in lines {
                if line.startPoint.y < lower_bound {
                    lower_bound = line.startPoint.y
                }
                if line.endPoint.y < lower_bound {
                    lower_bound = line.endPoint.y
                }
                if line.startPoint.y > upper_bound {
                    upper_bound = line.startPoint.y
                }
                if line.endPoint.y > upper_bound {
                    upper_bound = line.endPoint.y
                }
            }
            let minRow = Int(lower_bound.rounded(.down))
            let maxRow = Int(upper_bound.rounded(.down))
            let range = maxRow - minRow + 1
            var row_range = Array(repeating: IntersectionType.empty, count: range)
            var horizontal_lines: [Int] = []
            for line in lines {
                // line on grid does not intersect
                if line.startPoint.x == line.endPoint.x && line.startPoint.x == CGFloat(column) {
                    continue
                }
                if line.startPoint.y == line.endPoint.y && line.startPoint.y.rounded(.down) == line.startPoint.y {
                    horizontal_lines.append(Int(line.startPoint.y))
                }
                let lower_row = Int(min(line.startPoint.y, line.endPoint.y).rounded(.down))
                let upper_row: Int
                // not include the upper bound
                if max(line.startPoint.y, line.endPoint.y).rounded(.down) == max(line.startPoint.y, line.endPoint.y) {
                    upper_row = Int(max(line.startPoint.y, line.endPoint.y).rounded(.down)) - 1
                } else {
                    upper_row = Int(max(line.startPoint.y, line.endPoint.y).rounded(.down))
                }
                if lower_row <= upper_row {
                    for row in lower_row ... upper_row {
                        row_range[row - minRow] = .intersected
                    }
                }
            }
            var row = 0
            while row < range {
                var next_row = row + 1
                if row_range[row] == .empty {
                    var count = 0
                    let sqaure_corner_y = CGFloat(row + minRow)
                    for line in lines {
                        // skip horizontal line
                        if line.startPoint.x == line.endPoint.x {
                            continue
                        }
                        if line.startPoint.x == CGFloat(column) && line.startPoint.y > sqaure_corner_y {
                            count += 1
                        }
                        if line.endPoint.x == CGFloat(column) && line.endPoint.y > sqaure_corner_y {
                            count += 1
                        }
                    }
                    while next_row < range - 1 && row_range[next_row] == row_range[row] {
                        // horizontal lines on grid can also seperate sqaures
                        if horizontal_lines.contains(next_row + minRow) {
                            break
                        }
                        next_row += 1
                    }
                    if count % 2 == 1 {
                        for index in row ..< next_row {
                            row_range[index] = .covered
                        }
                    }
                }
                row = next_row
            }
            for (row, type) in row_range.enumerated() {
                if type == .intersected {
                    covered_sqaures.intersected.insert(Tile(r: row + minRow, c: column))
                } else if type == .covered {
                    covered_sqaures.covered.insert(Tile(r: row + minRow, c: column))
                }
            }
        }
        return covered_sqaures
    }
    
    
    /// should not include first point as last point
    private func createLines(points: [CGPoint]) -> [Line] {
        let converted_points = points.map {
            CGPoint(x: $0.x / self.tile_width,
                    y: $0.y / self.tile_height)
        }
        var lines = [Line(startPoint: converted_points.last!, endPoint: converted_points.first!)]
        for index in 0 ..< converted_points.count - 1 {
            lines.append(Line(startPoint: converted_points[index], endPoint: converted_points[index + 1]))
        }
        return lines
    }
    
    private func formatLines(lines: [Line]) -> [Line] {
        var formatted_lines: [Line] = []
        for line in lines {
            let startPoint: CGPoint
            let endPoint: CGPoint
            if line.startPoint.x < line.endPoint.x {
                startPoint = line.startPoint
                endPoint = line.endPoint
            } else {
                startPoint = line.endPoint
                endPoint = line.startPoint
            }
            let left_grid = startPoint.x.rounded(.down)
            let right_grid = endPoint.x.rounded(.up)
            if abs(right_grid - left_grid) > 1 {
                let trig_width = endPoint.x - startPoint.x
                let trig_height = endPoint.y - startPoint.y
                let ratio = trig_height / trig_width
                var sub_points = [startPoint]
                for grid in Int(left_grid) + 1 ... Int(right_grid) - 1 {
                    let sub_width = CGFloat(grid) - startPoint.x
                    let sub_height = ratio * sub_width
                    let sub_point = CGPoint(x: startPoint.x + sub_width,
                                            y: startPoint.y + sub_height)
                    sub_points.append(sub_point)
                }
                sub_points.append(endPoint)
                for index in 0 ..< sub_points.count - 1 {
                    formatted_lines.append(Line(startPoint: sub_points[index],
                                                endPoint: sub_points[index + 1]))
                }
            } else {
                formatted_lines.append(line)
            }
        }
        return formatted_lines
    }
    
    private func mapLines(formatted_lines: [Line]) -> [Int: [Line]] {
        var line_dict: [Int: [Line]] = [:]
        for line in formatted_lines {
            let current_row = Int(line.startPoint.x.rounded(.down))
            if line_dict[current_row] == nil {
                line_dict[current_row] = [line]
            } else {
                line_dict[current_row]?.append(line)
            }
        }
        return line_dict
    }
    
    private func contextDrawStrokes() {
        for stroke in getAllStrokes() {
            let segments = getSegmentsFromTable(id: stroke)
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
                    for segment in segments {
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
                    for segment in segments {
                        color.setFill()
                        segment.paths[0].fill()
                    }
                }
            }
        }
    }
}
