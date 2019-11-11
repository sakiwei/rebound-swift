//
//  AnimationUtil.swift
//  Rebound
//
//  Created by Adam Putinski on 8/3/15.
//

import Foundation
import CoreGraphics
import UIKit

internal class DisplayLinkQueue {
  
  private var displayLink: CADisplayLink!
  internal var updateBlock: (() -> Void)?
  
  internal init() {
    displayLink = CADisplayLink(target: self, selector: #selector(DisplayLinkQueue.update))
    displayLink.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
  }
  
  internal func destroy() {
    displayLink.remove(from: RunLoop.main, forMode: RunLoop.Mode.common)
    displayLink = nil
  }
  
  @objc private func update() {
    updateBlock?()
  }
  
}
