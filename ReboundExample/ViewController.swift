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
      self.square.transform = CGAffineTransform(scaleX: scale, y: scale)
    })

    addSubViews([
      tensionSlider, tensionTitle, tensionValue, frictionSlider, frictionTitle, frictionValue, square
    ])
    
    tensionSlider.minimumValue = 0
    tensionSlider.maximumValue = 100.0
    tensionSlider.value = 40.0
    tensionSlider.addTarget(self, action: #selector(ViewController.updateSpringConfig), for: .valueChanged)
    view.addConstraints([
      NSLayoutConstraint(item: tensionSlider, attribute: .bottom, relatedBy: .equal, toItem: frictionSlider, attribute: .top, multiplier: 1.0, constant: -20.0),
      NSLayoutConstraint(item: tensionSlider, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 80.0),
      NSLayoutConstraint(item: tensionSlider, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -50.0),
      NSLayoutConstraint(item: tensionSlider, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 40.0)
    ])
    
    tensionTitle.text = "Tension"
    tensionTitle.textAlignment = .right
    decorateLabel(tensionTitle)
    view.addConstraints([
      NSLayoutConstraint(item: tensionTitle, attribute: .centerY, relatedBy: .equal, toItem: tensionSlider, attribute: .centerY, multiplier: 1.0, constant: 0),
      NSLayoutConstraint(item: tensionTitle, attribute: .right, relatedBy: .equal, toItem: tensionSlider, attribute: .left, multiplier: 1.0, constant: -10.0)
    ])
    
    tensionValue.textAlignment = .left
    decorateLabel(tensionValue)
    view.addConstraints([
      NSLayoutConstraint(item: tensionValue, attribute: .centerY, relatedBy: .equal, toItem: tensionSlider, attribute: .centerY, multiplier: 1.0, constant: 0),
      NSLayoutConstraint(item: tensionValue, attribute: .left, relatedBy: .equal, toItem: tensionSlider, attribute: .right, multiplier: 1.0, constant: 10.0)
    ])
    
    frictionSlider.minimumValue = 0
    frictionSlider.maximumValue = 30.0
    frictionSlider.value = 3.0
    frictionSlider.addTarget(self, action: #selector(ViewController.updateSpringConfig), for: .valueChanged)
    view.addConstraints([
      NSLayoutConstraint(item: frictionSlider, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -40.0),
      NSLayoutConstraint(item: frictionSlider, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 80.0),
      NSLayoutConstraint(item: frictionSlider, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -50.0),
      NSLayoutConstraint(item: frictionSlider, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 40.0)
    ])
    
    frictionTitle.text = "Friction"
    frictionTitle.textAlignment = .right
    decorateLabel(frictionTitle)
    view.addConstraints([
      NSLayoutConstraint(item: frictionTitle, attribute: .centerY, relatedBy: .equal, toItem: frictionSlider, attribute: .centerY, multiplier: 1.0, constant: 0),
      NSLayoutConstraint(item: frictionTitle, attribute: .right, relatedBy: .equal, toItem: frictionSlider, attribute: .left, multiplier: 1.0, constant: -10.0)
    ])
    
    frictionValue.textAlignment = .left
    decorateLabel(frictionValue)
    view.addConstraints([
      NSLayoutConstraint(item: frictionValue, attribute: .centerY, relatedBy: .equal, toItem: frictionSlider, attribute: .centerY, multiplier: 1.0, constant: 0),
      NSLayoutConstraint(item: frictionValue, attribute: .left, relatedBy: .equal, toItem: frictionSlider, attribute: .right, multiplier: 1.0, constant: 10.0)
    ])
    
    square.backgroundColor = UIColor(red: 0/255.0, green: 122.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    square.addTarget(self, action: #selector(ViewController.squareDown), for: .touchDown)
    square.addTarget(self, action: #selector(ViewController.squareUp), for: .touchUpInside)
    square.addTarget(self, action: #selector(ViewController.squareUp), for: .touchUpOutside)
    view.addConstraints([
      NSLayoutConstraint(item: square, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0),
      NSLayoutConstraint(item: square, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0),
      NSLayoutConstraint(item: square, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 140.0),
      NSLayoutConstraint(item: square, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 140.0)
    ])
    
    updateSpringConfig()
  }
  
  func decorateLabel(_ label: UILabel) {
    label.font = UIFont(name: "HelveticaNeue", size: 14.0)
    label.textColor = UIColor.darkGray
  }
  
  func addSubViews(_ views: [UIView]) {
    for v in views {
      v.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(v)
    }
  }
  
  @objc func updateSpringConfig() {
    tensionValue.text = "\(Int(tensionSlider.value))"
    frictionValue.text = "\(Int(frictionSlider.value))"
    spring.config = SpringConfig.fromOrigamiTensionAndFriction(
      tension: Double(tensionSlider.value),
      friction: Double(frictionSlider.value)
    )
  }
  
  @objc func squareDown() {
    spring.setEndValue(1.0)
  }
  
  @objc func squareUp() {
    spring.setEndValue(0)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

}

