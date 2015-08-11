//
//  SpringLooper.swift
//  Rebound
//
//  Created by Adam Putinski on 7/31/15.
//

import Foundation

public class SpringLooper {
  
  public var springSystem: SpringSystem?
  
  public init() {

  }
  
  public func run() {

  }
  
}

public class AnimationLooper: SpringLooper {
  
  let queue = DisplayLinkQueue()
  
  deinit {
    queue.destroy()
  }
  
  public override func run() {
    queue.enqueue {
      dispatch_async(dispatch_get_main_queue()) {
        self.springSystem?.loop(CACurrentMediaTime() * 1000.0)
      }
    }
  }
  
}

public class SimulationLooper: SpringLooper {
  
  private var timestep: Double = 16.667
  private var time: Double = 0
  private var running: Bool = false
  
  public override init() {
    super.init()
  }
  
  public init(timestep: Double) {
    super.init()
    self.timestep = timestep
  }
  
  public override func run() {
    guard springSystem != nil else { return }
    guard !running else { return }
    running = true
    while !springSystem!.idle {
      time += timestep
      springSystem?.loop(time)
    }
    running = false
  }
  
}

public class SteppingSimulationLooper: SpringLooper {
  
  private var time: Double = 0
  
  public func step(timestep: Double) {
    time += timestep
    springSystem?.loop(time)
  }
  
}