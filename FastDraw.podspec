#  Be sure to run `pod spec lint FastDraw.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "FastDraw"
  spec.version      = "0.0.1"
  spec.summary      = "A short description of FastDraw."
  spec.description  = "A complete description of FastDraw"
  spec.ios.deployment_target = '11.0'

  spec.homepage     = "http://EXAMPLE/FastDraw"
  spec.license      = "MIT"
  spec.author             = { "collin" => "collinzrj@outlook.com" }
  spec.dependency 'SQLite.swift', '~> 0.12.0'
  spec.dependency 'SwiftProtobuf', '~> 1.0'


  spec.source_files  = "FastDraw/**/*.swift"
  # spec.source       = { :git => 'https://github.com/MessageBoard/FastDrawProject.git', :tag => '0.0.1' }
  spec.source       = { :path => '.' }

end
