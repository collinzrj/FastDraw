# FastDraw

A Fast and Complete Swift Drawing Library

## Description

FastDraw is a **high performance** and **highly extensible** Drawing Library that supports **Apple Pencil**. It supports **pencil**, **highlighter**, **eraser**, and **lasso**. 

Here is a the demo of FastDraw


https://user-images.githubusercontent.com/44433088/138016576-04e9864b-1680-459e-8278-f424b7332049.mov




It is the drawing library used in the collaborative drawing app [CoCreate](https://apps.apple.com/us/app/cocreate-draw-together/id1548911886). 
It has been optimized for Apple Pencil, which means that the stroke you draw with this library detects force performed on the drawing. You can directly get access to the SQLite file created by the library. 
Moreover, it also provides interface to get updates on operation happens on the board, so it is possible to send
the operation in the format of `protobuff` to other users. There is also interface to draw on the board programatically, which means you can even listen to a 
websocket, receive a drawing, erasing, or even lasso operation from others, and perform that on the board. FastDraw gives developer the full control over drawing. 


## Getting Started

Try out the FastDrawDemo

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
