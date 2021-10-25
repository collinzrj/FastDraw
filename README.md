# FastDraw

A Fast and Complete Swift Drawing Library

## Description

FastDraw is a **high performance** and **highly extensible** Drawing Library that supports **Apple Pencil**. It supports **pencil**, **highlighter**, **eraser**, and **lasso**. 

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

### Installing

```
pod 'FastDraw', :git => 'https://github.com/collinzrj/FastDraw.git', :commit => "33ed685f73b8adae8ab1ca26e5f028f8ef1cd406"
```

## Help

Send me an email and I will answer your question and fix problem for you as soon as possible, or you can create an issue if you meet any problems

## Authors

Collin Zhang


## License

This project is licensed under the [MIT] License - see the LICENSE.md file for details
