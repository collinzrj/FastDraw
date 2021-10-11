//
//  EraserView.swift
//  realtimedrawing
//
//  Created by 张睿杰 on 2020/4/6.
//  Copyright © 2020 张睿杰. All rights reserved.
//

import UIKit

public class EraserView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        print("frame is \(frame)")
        let circle = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 20, height: 20))
        circle.fill()
    }
}
