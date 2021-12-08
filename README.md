![Cocoapods](https://img.shields.io/cocoapods/v/FastDraw)
# FastDraw

A Fast and Complete Swift Drawing(Handwriting) Library

## Description

FastDraw is a **high performance** and **highly extensible** Drawing(Handwriting) Library that supports **Apple Pencil**. 
### Features
- pencil and highlighter, color and width selection
- eraser
- lasso
- export to `sqlite`, `pdf`, `png`

Here is a the demo of FastDraw

https://user-images.githubusercontent.com/44433088/138016576-04e9864b-1680-459e-8278-f424b7332049.mov


## Getting Started

Add a basic DrawBoard

```
import UIKit
import FastDraw

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let drawboardview = DrawBoardView(frame: CGRect(origin: CGPoint(x: 0, y: 100),
                                                    size: view.frame.size))
        drawboardview.setupDrawing()
        self.view.addSubview(drawboardview)
    }
}
```

Update Brush type and color anywhere you like

```
import UIKit
import FastDraw

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let drawboardview = DrawBoardView(frame: CGRect(origin: CGPoint(x: 0, y: 100),
                                                    size: view.frame.size))
        drawboardview.setupDrawing()
        self.view.addSubview(drawboardview)
        Brush.shared.type = .pen
        Brush.shared.color = .red
        Brush.shared.width = 10
    }
}
```

Try out the FastDrawDemo

Try the app powered by FastDraw [CoCreate](https://apps.apple.com/us/app/cocreate-draw-together/id1548911886). 

## Installation

### CocoaPods

Create `Podfile` and add pod `FastDraw`:

```
use_frameworks!

target 'YourApp' do
    pod 'FastDraw'
end
```

Install pods:
```
pod install
```

## Usage
Export to PDF/Image
```
// drawboardview is a view you have setup before

// export current drawing to URL
drawboardview.drawPDF(url: URL)
drawboardview.drawImage(url: URL)

// export current drawing to URL with background
// use these methods if you have provided a pdf as background of the UIView
drawboardview.drawPDF(pdfpage: CGPDFPage, url: URL)
drawboardview.drawImage(pdfpage: CGPDFPage, url: URL)
```

## Help

Send me an email and I will answer your question and fix problem for you as soon as possible, or you can create an issue if you meet any problems

## Contribution

Contribution is always welcomed! You can create an issue or pull request if you found a bug/implement a new feature/willing to improve the doc.

## Roadmap
- [] Toolbox to set brush
- [] Stresstest function for FastDrawDemo
- [] Improve performance of drawing
- [] Documentation

## Authors

Collin Zhang


## License

MIT
