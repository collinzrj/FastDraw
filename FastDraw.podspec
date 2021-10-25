#  Be sure to run `pod spec lint FastDraw.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "FastDraw"
  spec.version      = "0.1.0"
  spec.summary      = "A Fast and Complete Swift Drawing Library."
  spec.description  = "FastDraw is a high performance and highly extensible Drawing Library that supports Apple Pencil. It supports pencil, highlighter, eraser, and lasso."
  spec.ios.deployment_target = '11.0'

  spec.homepage     = "https://github.com/collinzrj/FastDraw"
  spec.license      = "MIT"
  spec.author       = { "collin" => "collinzrj@gmail.com" }
  spec.dependency 'SQLite.swift', '~> 0.12.0'
  spec.dependency 'SwiftProtobuf', '~> 1.0'


  spec.source_files  = "FastDraw/**/*.swift"
  spec.source       = { :git => 'https://github.com/collinzrj/FastDraw', :tag => '0.0.1' }
  spec.swift_version = '5.0'

end
