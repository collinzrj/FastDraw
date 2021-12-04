//
//  ViewController.swift
//  FastDrawDemo
//
//  Created by 张睿杰 on 2021/2/13.
//

import UIKit
import FastDraw

class ViewController: UIViewController {
    
    var drawboardview: DrawBoardView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        drawboardview = DrawBoardView(frame: CGRect(origin: CGPoint(x: 0, y: 100),
                                                    size: view.frame.size))
        drawboardview.setupDrawing()
        drawboardview.delegate = self
        let penButton = UIButton(frame: CGRect(x: 50, y: 50, width: 100, height: 50))
        let eraserButton = UIButton(frame: CGRect(x: 100, y: 50, width: 100, height: 50))
        let highlighterButton = UIButton(frame: CGRect(x: 175, y: 50, width: 100, height: 50))
        let lassoButton = UIButton(frame: CGRect(x: 250, y: 50, width: 100, height: 50))
        let exportButton = UIButton(frame: CGRect(x: 325, y: 50, width: 100, height: 50))
        penButton.setTitle("Pen", for: .normal)
        penButton.addTarget(self, action: #selector(penTapped), for: .touchUpInside)
        eraserButton.setTitle("Eraser", for: .normal)
        eraserButton.addTarget(self, action: #selector(eraserTapped), for: .touchUpInside)
        highlighterButton.setTitle("Highlighter", for: .normal)
        highlighterButton.addTarget(self, action: #selector(highlighterTapped), for: .touchUpInside)
        lassoButton.setTitle("Lasso", for: .normal)
        lassoButton.addTarget(self, action: #selector(lassoTapped), for: .touchUpInside)
        exportButton.setTitle("Export", for: .normal)
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        for button in [penButton, eraserButton, highlighterButton, lassoButton, exportButton] {
            button.setTitleColor(.black, for: .normal)
            self.view.addSubview(button)
        }
        self.view.addSubview(drawboardview)
    }
    
    @objc func penTapped() {
        Brush.shared.type = .pen
        Brush.shared.color = .black
        Brush.shared.width = 5
    }

    @objc func eraserTapped() {
        Brush.shared.type = .eraser
        Brush.shared.width = 5
    }
    
    @objc func lassoTapped() {
        Brush.shared.type = .lasso
    }
    
    @objc func highlighterTapped() {
        Brush.shared.type = .pen
        Brush.shared.color = .yellow
        Brush.shared.width = 20
    }
    
    @objc func exportTapped() {
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = baseURL.appendingPathComponent("test.pdf")
        drawboardview.drawPDF(url: url)
        print(url)
    }
}

extension ViewController: DrawBoardViewDelegate {
    func operationEnded(operation: FastOperation) {
        dump(operation)
    }
}
