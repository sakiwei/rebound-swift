//
//  AnimationUtil.swift
//  Rebound
//
//  Created by Adam Putinski on 8/3/15.
//

import Foundation

internal class DisplayLinkQueue {
  
  private var displayLink: CADisplayLink!
  private var requests: Array<() -> Void> = []
  
  internal init() {
    displayLink = CADisplayLink(target: self, selector: #selector(DisplayLinkQueue.update))
    displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
  }
  
  internal func destroy() {
    requests.removeAll()
    displayLink.remove(from: RunLoop.main, forMode: RunLoopMode.commonModes)
    displayLink = nil
  }
  
  @objc private func update() {
    while requests.count > 0 {
      let request = requests.removeLast()
      request()
    }
    displayLink.isPaused = true
  }
  
  internal func enqueue(_ request: () -> Void) {
    requests.insert(request, at: 0)
    displayLink.isPaused = false
  }
  
}
