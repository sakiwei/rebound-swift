# Rebound Swift

[![Version][version-image]][version-url]
[![Carthage compatible][carthage-image]][carthage-url]

Swift port of https://github.com/facebook/rebound-js

## Usage

```swift
import UIKit
import Rebound

class ViewController: UIViewController {
  
  var springSystem: SpringSystem!
  var spring: Spring!
  
  let square = UIControl(frame: CGRect(x: 0, y: 0, width: 100.0, height: 100.0))
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    springSystem = SpringSystem()
    spring = springSystem.createSpring(tension: 40.0, friction: 3.0)
    spring.addListener(update: { spring in
      let scale = MathUtil.mapValueInRange(
        CGFloat(spring.currentValue), fromLow: 0, fromHigh: 1.0, toLow: 1.0, toHigh: 0.5
      )
      self.square.transform = CGAffineTransformMakeScale(scale, scale)
    })
    
    square.backgroundColor = UIColor(red: 0/255.0, green: 122.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    square.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    square.addTarget(self, action: "squareDown", forControlEvents: .TouchDown)
    square.addTarget(self, action: "squareUp", forControlEvents: .TouchUpInside)
    square.addTarget(self, action: "squareUp", forControlEvents: .TouchUpOutside)
    view.addSubview(square)
  }
  
  func squareDown() {
    spring.setEndValue(1.0)
  }
  
  func squareUp() {
    spring.setEndValue(0)
  }
  
}
```

[version-url]: https://github.com/aputinski/rebound-swift/releases
[version-image]: https://img.shields.io/github/release/aputinski/rebound-swift.svg

[carthage-url]: https://github.com/Carthage/Carthage
[carthage-image]: https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat
