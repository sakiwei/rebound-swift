//
//  SpringSystem.swift
//  Rebound
//
//  Created by Adam Putinski on 7/31/15.
//

import Foundation

public enum SpringSystemEvent {
  
  case BeforeIntegrate(SpringSystem)
  case AfterIntegrate(SpringSystem)
  
  public typealias Sink = SpringSystemEvent -> ()
  
  public static func sink(beforeIntegrate beforeIntegrate: ((SpringSystem) -> ())? = nil, afterIntegrate: ((SpringSystem) -> ())? = nil) -> Sink {
    return { event in
      switch event {
      case let .BeforeIntegrate(springSystem):
        beforeIntegrate?(springSystem)
      case let .AfterIntegrate(springSystem):
        afterIntegrate?(springSystem)
      }
    }
  }
  
}

public class SpringSystem {

  // MARK: Init
  
  public init() {
    setLooper(AnimationLooper())
  }
  
  public init(looper: SpringLooper) {
    setLooper(looper)
  }
  
  public func destroy() {
    looper = nil
    removeAllListeners()
  }
  
  // MARK: Looper
  
  private var looper: SpringLooper?
  
  // A SpringSystem is iterated by a looper. The looper is responsible
  // for executing each frame as the SpringSystem is resolved to idle.
  // There are three types of Loopers described below AnimationLooper,
  // SimulationLooper, and SteppingSimulationLooper. AnimationLooper is
  // the default as it is the most useful for common UI animations.
  public func setLooper(looper: SpringLooper) {
    self.looper = looper
    looper.springSystem = self
  }
  
  // MARK: Create
  
  // Add a new spring to this SpringSystem. This Spring will now be solved for
  // during the physics iteration loop. By default the spring will use the
  // default Origami spring config with 40 tension and 7 friction, but you can
  // also provide your own values here.
  public func createSpring() -> Spring {
    return createSpring(
      SpringConfig.DEFAULT_ORIGAMI_SPRING_CONFIG
    )
  }
  
  public func createSpring(tension tension: Double, friction: Double) -> Spring {
    return createSpring(
      SpringConfig.fromOrigamiTensionAndFriction(tension: tension, friction: friction)
    )
  }
  
  // Add a spring with a specified bounciness and speed. To replicate Origami
  // compositions based on PopAnimation patches, use this factory method to
  // create matching springs.
  public func createSpring(bounciness bounciness: Double, speed: Double) -> Spring {
    return createSpring(
      SpringConfig.fromBouncinessAndSpeed(bounciness, speed: speed)
    )
  }
  
  // Add a spring with the provided SpringConfig.
  public func createSpring(config: SpringConfig) -> Spring {
    let spring = Spring(config: config, springSystem: self)
    registerSpring(spring)
    return spring
  }
  
  // MARK: Springs
  
  public private(set) var springs = [Spring]()
  private var activeSprings = [Spring]()
  private var idleSprings = [Spring]()
  
  // If all of the Springs in the SpringSystem are at rest,
  // i.e. the physics forces have reached equilibrium, then this
  // will return true.
  private(set) public var idle = true
  
  // registerSpring is called automatically as soon as you create
  // a Spring with SpringSystem#createSpring. This method sets the
  // spring up in the registry so that it can be solved in the
  // solver loop.
  public func registerSpring(spring: Spring) {
    if !springs.contains(spring) {
      springs.append(spring)
    }
  }
  
  // Deregister a spring with this SpringSystem. The SpringSystem will
  // no longer consider this Spring during its integration loop once
  // this is called. This is normally done automatically for you when
  // you call Spring#destroy.
  public func deregisterSpring(spring: Spring) {
    if let index = springs.indexOf(spring) {
      springs.removeAtIndex(index)
    }
    if let index = activeSprings.indexOf(spring) {
      activeSprings.removeAtIndex(index)
    }
    if let index = idleSprings.indexOf(spring) {
      idleSprings.removeAtIndex(index)
    }
  }
  
  // activateSpring is used to notify the SpringSystem that a Spring
  // has become displaced. The system responds by starting its solver
  // loop up if it is currently idle.
  public func activateSpring(spring: Spring) {
    if !activeSprings.contains(spring) {
      activeSprings.append(spring)
    }
    if idle {
      idle = false
      looper?.run()
    }
  }
  
  // MARK: Advance
  
  private var lastTime: Double = -1.0
  
  private func advance(time: Double, deltaTime: Double) {
    idleSprings.removeAll()
    for spring in activeSprings {
      if spring.systemShouldAdvance() {
        spring.advance(time / 1000.0, realDeltaTime: deltaTime / 1000.0)
      } else {
        idleSprings.append(spring)
      }
    }
    while idleSprings.count > 0 {
      let spring = idleSprings.removeLast()
      if let index = activeSprings.indexOf(spring) {
        activeSprings.removeAtIndex(index)
      }
    }
  }
  
  // This is our main solver loop called to move the simulation
  // forward through time. Before each pass in the solver loop
  // onBeforeIntegrate is called on an any listeners that have
  // registered themeselves with the SpringSystem. This gives you
  // an opportunity to apply any constraints or adjustments to
  // the springs that should be enforced before each iteration
  // loop. Next the advance method is called to move each Spring in
  // the systemShouldAdvance forward to the current time. After the
  // integration step runs in advance, onAfterIntegrate is called
  // on any listeners that have registered themselves with the
  // SpringSystem. This gives you an opportunity to run any post
  // integration constraints or adjustments on the Springs in the
  // SpringSystem.
  public func loop(time: Double) {
    if lastTime == -1.0 {
      lastTime = time - 1.0
    }
    let ellapsedTime = time - lastTime
    lastTime = time
    for listener in listeners {
      listener(.BeforeIntegrate(self))
    }
    advance(time, deltaTime: ellapsedTime)
    if activeSprings.count == 0 {
      idle = true
      lastTime = -1
    }
    for listener in listeners {
      listener(.AfterIntegrate(self))
    }
    if !idle {
      looper?.run()
    }
  }
  
  // MARK: Listeners
  
  private var listeners = Bag<SpringSystemEvent.Sink>()
  
  public func getListenerCount() -> Int {
    return listeners.count
  }
  
  public func addListener(beforeIntegrate beforeIntegrate: ((SpringSystem) -> ())? = nil, afterIntegrate: ((SpringSystem) -> ())? = nil) -> SpringRemovalToken {
    let sink = SpringSystemEvent.sink(beforeIntegrate: beforeIntegrate, afterIntegrate: afterIntegrate)
    return listeners.insert(sink)
  }
  
  public func removeListener(token: SpringRemovalToken) {
    listeners.removeValueForToken(token)
  }
  
  public func removeAllListeners() {
    listeners.removeAll()
  }
  
}