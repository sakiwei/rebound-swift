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
    displayLink = CADisplayLink(target: self, selector: "update")
    displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
  }
  
  internal func destroy() {
    requests.removeAll()
    displayLink.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    displayLink = nil
  }
  
  @objc private func update() {
    while requests.count > 0 {
      let request = requests.removeLast()
      request()
    }
    displayLink.paused = true
  }
  
  internal func enqueue(request: () -> Void) {
    requests.insert(request, atIndex: 0)
    displayLink.paused = false
  }
  
}
