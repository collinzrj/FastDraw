//
//  File.swift
//  realtimedrawing
//
//  Created by 张睿杰 on 2020/2/13.
//  Copyright © 2020 张睿杰. All rights reserved.
//

import Foundation
import UIKit

public class DrawPDFView: UIView {
    public var pdfpage: CGPDFPage?
    
    public override func draw(_ rect: CGRect) {
        if let page = pdfpage {
            let context: CGContext = UIGraphicsGetCurrentContext()!
            context.setFillColor(red: 1.0,green: 1.0,blue: 1.0,alpha: 1.0)
            context.fill(self.bounds)
            let pageRect: CGRect = page.getBoxRect(CGPDFBox.mediaBox)
            let scale: CGFloat = min(self.bounds.size.width / pageRect.size.width , self.bounds.size.height / pageRect.size.height)
            context.saveGState()
            context.translateBy(x: 0.0, y: self.bounds.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            context.scaleBy(x: scale, y: scale)
            context.drawPDFPage(page)
            context.restoreGState()
        }
    }
}
