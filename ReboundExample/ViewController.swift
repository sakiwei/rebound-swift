//
//  ViewController.swift
//  Examples
//
//  Created by Adam Putinski on 8/3/15.
//

import UIKit
import Rebound

class ViewController: UIViewController {
  
  var system: SpringSystem!
  var spring: Spring!

  let tensionSlider = UISlider()
  let tensionTitle = UILabel()
  let tensionValue = UILabel()
  
  let frictionSlider = UISlider()
  let frictionTitle = UILabel()
  let frictionValue = UILabel()
  
  let square = UIControl()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    system = SpringSystem()
    spring = system.createSpring()
    spring.addListener(update: { spring in
      let scale = MathUtil.mapValueInRange(
        CGFloat(spring.currentValue), fromLow: 0, fromHigh: 1.0, toLow: 1.0, toHigh: 0.5
      )
      self.square.transform = CGAffineTransformMakeScale(scale, scale)
    })

    addSubViews([
      tensionSlider, tensionTitle, tensionValue, frictionSlider, frictionTitle, frictionValue, square
    ])
    
    tensionSlider.minimumValue = 0
    tensionSlider.maximumValue = 100.0
    tensionSlider.value = 40.0
    tensionSlider.addTarget(self, action: "updateSpringConfig", forControlEvents: .ValueChanged)
    view.addConstraints([
      NSLayoutConstraint(item: tensionSlider, attribute: .Bottom, relatedBy: .Equal, toItem: frictionSlider, attribute: .Top, multiplier: 1.0, constant: -20.0),
      NSLayoutConstraint(item: tensionSlider, attribute: .Left, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1.0, constant: 80.0),
      NSLayoutConstraint(item: tensionSlider, attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .Right, multiplier: 1.0, constant: -50.0),
      NSLayoutConstraint(item: tensionSlider, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 40.0)
    ])
    
    tensionTitle.text = "Tension"
    tensionTitle.textAlignment = .Right
    decorateLabel(tensionTitle)
    view.addConstraints([
      NSLayoutConstraint(item: tensionTitle, attribute: .CenterY, relatedBy: .Equal, toItem: tensionSlider, attribute: .CenterY, multiplier: 1.0, constant: 0),
      NSLayoutConstraint(item: tensionTitle, attribute: .Right, relatedBy: .Equal, toItem: tensionSlider, attribute: .Left, multiplier: 1.0, constant: -10.0)
    ])
    
    tensionValue.textAlignment = .Left
    decorateLabel(tensionValue)
    view.addConstraints([
      NSLayoutConstraint(item: tensionValue, attribute: .CenterY, relatedBy: .Equal, toItem: tensionSlider, attribute: .CenterY, multiplier: 1.0, constant: 0),
      NSLayoutConstraint(item: tensionValue, attribute: .Left, relatedBy: .Equal, toItem: tensionSlider, attribute: .Right, multiplier: 1.0, constant: 10.0)
    ])
    
    frictionSlider.minimumValue = 0
    frictionSlider.maximumValue = 30.0
    frictionSlider.value = 3.0
    frictionSlider.addTarget(self, action: "updateSpringConfig", forControlEvents: .ValueChanged)
    view.addConstraints([
      NSLayoutConstraint(item: frictionSlider, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: -40.0),
      NSLayoutConstraint(item: frictionSlider, attribute: .Left, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1.0, constant: 80.0),
      NSLayoutConstraint(item: frictionSlider, attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .Right, multiplier: 1.0, constant: -50.0),
      NSLayoutConstraint(item: frictionSlider, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 40.0)
    ])
    
    frictionTitle.text = "Friction"
    frictionTitle.textAlignment = .Right
    decorateLabel(frictionTitle)
    view.addConstraints([
      NSLayoutConstraint(item: frictionTitle, attribute: .CenterY, relatedBy: .Equal, toItem: frictionSlider, attribute: .CenterY, multiplier: 1.0, constant: 0),
      NSLayoutConstraint(item: frictionTitle, attribute: .Right, relatedBy: .Equal, toItem: frictionSlider, attribute: .Left, multiplier: 1.0, constant: -10.0)
    ])
    
    frictionValue.textAlignment = .Left
    decorateLabel(frictionValue)
    view.addConstraints([
      NSLayoutConstraint(item: frictionValue, attribute: .CenterY, relatedBy: .Equal, toItem: frictionSlider, attribute: .CenterY, multiplier: 1.0, constant: 0),
      NSLayoutConstraint(item: frictionValue, attribute: .Left, relatedBy: .Equal, toItem: frictionSlider, attribute: .Right, multiplier: 1.0, constant: 10.0)
    ])
    
    square.backgroundColor = UIColor(red: 0/255.0, green: 122.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    square.addTarget(self, action: "squareDown", forControlEvents: .TouchDown)
    square.addTarget(self, action: "squareUp", forControlEvents: .TouchUpInside)
    square.addTarget(self, action: "squareUp", forControlEvents: .TouchUpOutside)
    view.addConstraints([
      NSLayoutConstraint(item: square, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1.0, constant: 0),
      NSLayoutConstraint(item: square, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1.0, constant: 0),
      NSLayoutConstraint(item: square, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 140.0),
      NSLayoutConstraint(item: square, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 140.0)
    ])
    
    updateSpringConfig()
  }
  
  func decorateLabel(label: UILabel) {
    label.font = UIFont(name: "HelveticaNeue", size: 14.0)
    label.textColor = UIColor.darkGrayColor()
  }
  
  func addSubViews(views: [UIView]) {
    for v in views {
      v.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(v)
    }
  }
  
  func updateSpringConfig() {
    tensionValue.text = "\(Int(tensionSlider.value))"
    frictionValue.text = "\(Int(frictionSlider.value))"
    spring.config = SpringConfig.fromOrigamiTensionAndFriction(
      tension: Double(tensionSlider.value),
      friction: Double(frictionSlider.value)
    )
  }
  
  func squareDown() {
    spring.setEndValue(1.0)
  }
  
  func squareUp() {
    spring.setEndValue(0)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

}

