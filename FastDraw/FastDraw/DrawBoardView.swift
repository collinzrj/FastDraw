//
//  DrawBoardView.swift
//  realtimedrawing
//
//  Created by 张睿杰 on 2019/11/13.
//  Copyright © 2019 张睿杰. All rights reserved.
//

import UIKit
import CoreGraphics

public protocol DrawBoardViewDelegate: class {
    func operationEnded(operation: FastOperation)
}

public class DrawBoardView: UIView {
    
    private var drawactiveview: DrawActiveView
    private var strokeGesture: GestureRecognizerModel
    private var brush = Brush.shared
    private var touchTypes = [UITouch.TouchType.pencil.rawValue as NSNumber, UITouch.TouchType.direct.rawValue as NSNumber]
    private var segmentmap: StrokeSegmentMap?
    private var transformview: TransformView!
    private var all_erased_segments: [StrokeSegment]!
    
    public weak var delegate: DrawBoardViewDelegate?
    public var segmentdatabase: StrokeDatabase?
    public var scrollview: UIScrollView?
    public var isLoaded: Bool
    
    //MARK: Init Functions
    
    public override init(frame: CGRect) {
        drawactiveview = DrawActiveView(frame: CGRect(origin: CGPoint.zero,
                                                      size: frame.size))
        strokeGesture = GestureRecognizerModel()
        isLoaded = false
        super.init(frame: frame)
        drawactiveview.backgroundColor = .clear
        self.backgroundColor = .clear
        self.addSubview(drawactiveview)
        strokeGesture.addTarget(self, action: #selector(strokeUpdated(_:)))
        strokeGesture.brush = brush
        strokeGesture.delegate = self
        strokeGesture.gestureDelegate = self
        drawactiveview.brush = brush
        drawactiveview.delegate = self
        self.addGestureRecognizer(strokeGesture)
        
        print("test good")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Setup Functions
    
    public func setupDrawing(path: String? = nil) {
        if let segmentdatabase = StrokeDatabase(path: path) {
            self.segmentdatabase = segmentdatabase
            self.segmentmap = StrokeSegmentMap(segmentdatabase: segmentdatabase, size: frame.size)
            isLoaded = true
        }
    }
    
    public func setupDrawing(segmentdatabase: StrokeDatabase) {
        self.segmentdatabase = segmentdatabase
        self.segmentmap = StrokeSegmentMap(segmentdatabase: segmentdatabase, size: frame.size)
        isLoaded = true
    }
    
    public func setupBrush(brush: Brush) {
        self.brush = brush
        self.drawactiveview.brush = brush
        self.strokeGesture.brush = brush
    }
    
    //MARK: Edit Functions
    
    public func addOperation(operation: FastOperation) {
        switch operation.type {
        case .draw:
            let drawOperation = operation as! DrawOperation
            segmentmap?.addStroke(stroke: drawOperation.stroke)
            segmentdatabase?.addStroke(stroke: drawOperation.stroke)
        case .erase:
            let eraseOperation = operation as! EraseOperation
            segmentmap?.updateSegmentErased(erasedDict: eraseOperation.erasedDict,
                                            erased: true)
            segmentdatabase?.updateSegmentsErased(erased_dict: eraseOperation.erasedDict,
                                                  erased: true)
        case .lasso:
            let lassoOperation = operation as! LassoOperation
            segmentmap?.updateStrokes(pointDict: lassoOperation.newDict)
            segmentdatabase?.updateStrokes(pointDict: lassoOperation.newDict)
        }
        self.setNeedsDisplay()
    }
    
    //MARK: Export Functions
    
    public func drawPDF(pdfpage: CGPDFPage, path: String) {
        segmentmap?.drawPDF(pdfpage: pdfpage, path: path)
    }
    
    public func drawPDF(url: URL) {
        segmentmap?.drawPDF(frame: frame, url: url)
    }
    
    public func drawImage(pdfpage: CGPDFPage, url: URL) {
        segmentmap?.drawImage(pdfpage: pdfpage, url: url)
    }
    
    public func drawImage(url: URL) {
        segmentmap?.drawImage(frame: frame, url: url)
    }
    
    //MARK: Override Functions
    
    public override func layerWillDraw(_ layer: CALayer) {
        layer.contentsFormat = .RGBA8Uint
    }
    
    // draw with path collection test performance
    public override func draw(_ rect: CGRect) {
        let start = CFAbsoluteTimeGetCurrent()
        guard let segmentmap = segmentmap else { return }
        
        // check if is eraser situation
        if rect.width < self.frame.width || rect.height < self.frame.height {
            // seperate into pen or highlighter, if highlighter, get all segments from segmentmap since it should be in correct order
            let tiles = segmentmap.getTiles(rect: rect)
            var segments_dict = [Int64: [StrokeSegment]]()
            var type_dict = [Int64: String]()
            for tile in tiles {
                let rows = segmentmap.getRowFromTable(tile: tile)
                for row in rows {
                    if type_dict[row.1.curveId] == nil {
                        if check_alpha(color: row.1.segment.color) < 1 {
                            type_dict[row.1.curveId] = "highlighter"
                            segments_dict[row.1.curveId] = segmentmap.getSegmentsFromTable(id: row.1.curveId)
                        } else {
                            type_dict[row.1.curveId] = "pen"
                            segments_dict[row.1.curveId] = [row.1.segment]
                        }
                    } else {
                        if type_dict[row.1.curveId] == "highlighter" {
                            continue
                        } else {
                            segments_dict[row.1.curveId]?.append(row.1.segment)
                        }
                    }
                }
            }
            var curves = [Int64] (segments_dict.keys)
            curves.sort {
                segmentmap.curveArray.getIndex(id: $0) < segmentmap.curveArray.getIndex(id: $1)
            }
            for curve in curves {
                if type_dict[curve] == "highlighter" {
                    if let segments = segments_dict[curve] {
                        if !segments.isEmpty {
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
                            segments[0].color.setStroke()
                            print("the color is \(segments[0].color)")
                            path.stroke()
                        }
                    }
                } else {
                    for segment in segments_dict[curve]! {
                        segment.color.setFill()
                        segment.paths[0].fill()
                    }
                }
            }
        } else {
            for id in segmentmap.getAllStrokes() {
                let segments = segmentmap.getSegmentsFromTable(id: id)
                if !segments.isEmpty {
                    let alpha = check_alpha(color: segments[0].color)
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
                        segments[0].color.setStroke()
                        path.stroke()
                    } else {
                        for segment in segments {
                            segment.color.setFill()
                            segment.paths[0].fill()
                        }
                    }
                }
            }
        }
        let end = CFAbsoluteTimeGetCurrent()
        print("draw time \(end - start)")
    }
}


extension DrawBoardView: DrawActiveViewDelegate {
    
    /// Begin Lasso Operation to generate a Transformview for drag
    /// - Parameters:
    ///   - lasso: a list of CGPoint describing the lasso
    ///   - panGestureRecognizer: the GestureRecognizer to support the drag of the transformview
    private func beginLasso(lasso: [CGPoint]) {
        
        guard let segmentmap = segmentmap else {
            print("has not been loaded")
            return
        }
        let stroke_uuids = segmentmap.findCurvesInLasso(lasso: lasso)
        
        transformview = TransformView(frame: CGRect(origin: CGPoint.zero,
                                                    size: frame.size))
        
        for stroke_uuid in stroke_uuids {
            var curve = Curve(id: stroke_uuid)
            curve.segments = segmentmap.getSegmentsFromTable(id: stroke_uuid)
            // ALERT: MAY NEED IMPROVE HERE
            transformview.curves.append(curve)
        }
        
        transformview.curves.sort {
            segmentmap.getIndex(id: $0.id) < segmentmap.getIndex(id: $1.id)
        }
        
        for stroke_uuid in stroke_uuids {
            segmentmap.removeStroke(id: stroke_uuid)
        }
        transformview.lasso = lasso
        
        transformview.isUserInteractionEnabled = true
        transformview.backgroundColor = .clear
        transformview.tag = 0xDEADBEEF
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(recognizer:)))
        recognizer.allowedTouchTypes = touchTypes
        recognizer.delegate = self
        transformview.addGestureRecognizer(recognizer)
        
        self.addSubview(transformview)
        transformview.layer.contentsScale = self.layer.contentsScale
        self.setNeedsDisplay()
        transformview.setNeedsDisplay()
        transformview.drawLasso()
    }
    
    /// End the lasso state of drawboardview
    private func endLasso() {
        guard let segmentmap = segmentmap else { return }
        var removedCurves = [Curve]()
        var newCurves = [Curve]()
        var removedCurveUUID = [Int64]()
        for curve in transformview.curves {
            if curve.segments.count > 0 {
                var newCurve = curve
                newCurve.convert(dx: transformview.frame.origin.x, dy: transformview.frame.origin.y)
                removedCurves.append(curve)
                removedCurveUUID.append(curve.id)
                newCurves.append(newCurve)
                segmentmap.addCurve(curve: newCurve)
            }
        }
        
        var removedDict = [Int64: Point]()
        var pointDict = [Int64: Point]()
        guard let segmentdatabase = segmentdatabase else { return }
        let difference = transformview.frame.origin
        for curve in transformview.curves {
            let id = curve.id
            if let stroke = segmentdatabase.getStroke(id: id) {
                removedDict[id] = stroke.basePoint
                pointDict[id] = Point.with {
                    $0.x = stroke.basePoint.x + Float(difference.x)
                    $0.y = stroke.basePoint.y + Float(difference.y)
                    $0.force = stroke.basePoint.force
                }
            }
        }
        segmentdatabase.updateStrokes(pointDict: pointDict)
        delegate?.operationEnded(operation: LassoOperation(newDict: pointDict,
                                                           removedDict: removedDict))
        transformview.removeFromSuperview()
        transformview = nil
        self.setNeedsDisplay()
    }
    
    @objc private func strokeUpdated(_ gesture: GestureRecognizerModel) {
        
        if brush.type == .eraser && strokeGesture.state == .began {
            all_erased_segments = []
        }

        drawactiveview.state = strokeGesture.state
        
        if brush.type == .eraser {
            let points = strokeGesture.stroke.offsetPoints
            if points.count >= 2 {
                let p1 = points[points.count - 2].offsetLocation(basePoint: strokeGesture.stroke.basePoint)
                let p2 = points[points.count - 1].offsetLocation(basePoint: strokeGesture.stroke.basePoint)
                if !(p1 == p2) {
                    if let segmentmap = self.segmentmap {
                        let result = segmentmap.eraseSegments(A: p1, B: p2, width: CGFloat(strokeGesture.stroke.width))
                        let erased_segments = result.0
                        if erased_segments.count > 0 {
                            if let rect = result.1 {
                                let adjustedRect = CGRect(x: rect.minX - 10,
                                                          y: rect.minY - 10,
                                                          width: (rect.maxX - rect.minX) + 20,
                                                          height: (rect.maxY - rect.minY) + 20)
                                print("a86 \(rect)")
                                self.setNeedsDisplay(adjustedRect)
                            }
                            all_erased_segments?.append(contentsOf: erased_segments)
                        }
                    }
                }
            }
        }
        
        drawactiveview.activeStroke = strokeGesture.stroke
        drawactiveview.setNeedsDisplay()
        
        if strokeGesture.state == .ended {
            // test here
            switch brush.type {
            case .pen:
                break
            case .highlighter:
                break
            case .lasso:
                if let stroke = drawactiveview.activeStroke {
                    let lasso = stroke.offsetPoints.map {
                        $0.offsetLocation(basePoint: stroke.basePoint)
                    }
                    self.beginLasso(lasso: lasso)
                }
                drawactiveview.activeStroke = nil
                drawactiveview.setNeedsDisplay()
            case .eraser:
                if let all_erased_segments = all_erased_segments {
                    var erased_dict = [Int64:[UInt64]]()
                    for segment in all_erased_segments {
                        if erased_dict[segment.parentStrokeId] == nil  {
                            erased_dict[segment.parentStrokeId] = [UInt64(segment.index)]
                        } else {
                            erased_dict[segment.parentStrokeId]!.append(UInt64(segment.index))
                        }
                    }
                    self.segmentdatabase?.updateSegmentsErased(erased_dict: erased_dict, erased: true)
                    delegate?.operationEnded(operation: EraseOperation(erasedDict: erased_dict))
                }
                all_erased_segments = nil
                drawactiveview.activeStroke = nil
                drawactiveview.setNeedsDisplay()
            }
        }
    }
    
    func lastDrawFinish() {
        drawactiveview.state = UIGestureRecognizer.State.began
        if brush.type == .pen || brush.type == .highlighter,
            let stroke = drawactiveview.activeStroke {
            if let segmentmap = self.segmentmap,
               let segmentdatabase = self.segmentdatabase {
                segmentmap.addStroke(stroke: stroke)
                segmentdatabase.addStroke(stroke: stroke)
                self.setNeedsDisplay()
                drawactiveview.activeStroke = nil
                drawactiveview.setNeedsDisplay()
                delegate?.operationEnded(operation: DrawOperation(stroke: stroke))
            }
        }
    }
}

extension DrawBoardView: UIGestureRecognizerDelegate, GestureRecognizerModelDelegate {
    
    // need to consider scrollview here
    public func firstTouchDetected() {
        if self.touchTypes.contains(UITouch.TouchType.direct.rawValue as NSNumber),
           let scrollview = scrollview {
            scrollview.panGestureRecognizer.state = .failed
            scrollview.pinchGestureRecognizer?.state = .failed
        }
    }
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is GestureRecognizerModel {
            if self.segmentmap == nil && (brush.type == .eraser || brush.type == .lasso) {
                return false
            }
        }
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if touchTypes.contains(UITouch.TouchType.direct.rawValue as NSNumber) {
            if gestureRecognizer is GestureRecognizerModel {
                guard let scrollview = scrollview else { return true }
                if scrollview.gestureRecognizers!.contains(otherGestureRecognizer) {
                    return true
                }
            }
        }
        return false
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        print("should receive touch triggered")
        if let recognizer = gestureRecognizer as? GestureRecognizerModel {
            if recognizer.numberOfTouches > 1 {
                return false
            }
        }
        if transformview != nil && gestureRecognizer is GestureRecognizerModel {
            return false
        }
        let point = touch.location(in: self)
        if self.checkShouldKeepLasso(point: point) {
            return true
        } else {
            self.endLasso()
            return false
        }
    }
    
    private func checkShouldKeepLasso(point: CGPoint) -> Bool {
        if transformview == nil {
            return true
        }
        var point = point
        let origin = transformview.frame.origin
        point.x -= origin.x
        point.y -= origin.y
        if let segmentmap = self.segmentmap {
            return segmentmap.checkPointInLasso(point: point, lasso: transformview.lasso)
        }
        return false
    }
    
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer) {
        var translation = recognizer.translation(in: self)
        translation = CGPoint(x: translation.x, y: translation.y)
        if let view = recognizer.view {
            view.center = CGPoint(x:view.center.x + translation.x,
                                  y:view.center.y + translation.y)
        }
        recognizer.setTranslation(CGPoint.zero, in: self)
    }
}


