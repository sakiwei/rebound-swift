//
//  Spring.swift
//  Rebound
//
//  Created by Adam Putinski on 7/31/15.
//

import Foundation

public enum SpringEvent {
  
  case Activate(Spring)
  case Update(Spring)
  case Rest(Spring)
  case EndStateChange(Spring)
  
  public typealias Sink = SpringEvent -> ()
  
  public static func sink(activate activate: ((Spring) -> ())? = nil, update: ((Spring) -> ())? = nil, rest: ((Spring) -> ())? = nil, endStateChange: ((Spring) -> ())? = nil) -> Sink {
    return { event in
      switch event {
      case let .Activate(spring):
        activate?(spring)
      case let .Update(spring):
        update?(spring)
      case let .Rest(spring):
        rest?(spring)
      case let .EndStateChange(spring):
        endStateChange?(spring)
      }
    }
  }
  
}

public class Spring: Hashable, Equatable {
  
  private static var UID = 0
  private static let MAX_DELTA_TIME_SEC: Double = 0.064
  private static let SOLVER_TIMESTEP_SEC: Double = 0.001
  
  public var hashValue: Int {
    get { return id }
  }
  
  public let id = Spring.UID++
  
  // MARK: Init
  
  // Set the configuration values for this Spring. A SpringConfig
  // contains the tension and friction values used to solve for the
  // equilibrium of the Spring in the physics loop.
  public var config: SpringConfig
  
  private var springSystem: SpringSystem
  
  public init(config: SpringConfig, springSystem: SpringSystem) {
    self.config = config
    self.springSystem = springSystem
  }
  
  // Remove a Spring from simulation and clear its listeners.
  public func destroy() {
    listeners.removeAll()
    springSystem.deregisterSpring(self)
  }
  
  // MARK: State
  
  private var currentState = PhysicsState()
  private var previousState = PhysicsState()
  private var tempState = PhysicsState()
  
  // MARK: Overshoot
  
  // Enable overshoot clamping. This means that the Spring will stop
  // immediately when it reaches its resting position regardless of
  // any existing momentum it may have. This can be useful for certain
  // types of animations that should not oscillate such as a scale
  // down to 0 or alpha fade.
  public var overshootClampingEnabled = false
  
  // Check if the Spring has gone past its end point by comparing
  // the direction it was moving in when it started to the current
  // position and end value.
  public var isOvershooting: Bool {
    get {
      return config.tension > 0 &&
        ((startValue < endValue && currentValue > endValue) ||
          (startValue > endValue && currentValue < endValue))
    }
  }

  // MARK: Start Value
  
  // Get the position that the most recent animation started at. This
  // can be useful for determining the number off oscillations that
  // have occurred.
  public private(set) var startValue: Double = 0
  
  // MARK: Current Value
  
  // Retrieve the current value of the Spring.
  public var currentValue: Double {
    get {
      return currentState.position
    }
  }
  
  // Set the current position of this Spring. Listeners will be updated
  // with this value immediately. If the rest or `endValue` is not
  // updated to match this value, then the spring will be dispalced and
  // the SpringSystem will start to loop to restore the spring to the `endValue`.
  //
  // A common pattern is to move a Spring around without animation by calling.
  //
  // ```
  // spring.setCurrentValue(n).setAtRest();
  // ```
  //
  // This moves the Spring to a new position `n`, sets the endValue
  // to `n`, and removes any velocity from the `Spring`. By doing
  // this you can allow the `SpringListener` to manage the position
  // of UI elements attached to the spring even when moving without
  // animation. For example, when dragging an element you can
  // update the position of an attached view through a spring
  // by calling `spring.setCurrentValue(x)`.
  // When the gesture ends you can update the Springs velocity and endValue
  // `spring.setVelocity(gestureEndVelocity).setEndValue(flingTarget)`
  // to cause it to naturally animate the UI element to the resting
  // position taking into account existing velocity. The codepaths for
  // synchronous movement and spring driven animation can
  // be unified using this technique.
  public func setCurrentValue(currentValue: Double, skipSetAtRest: Bool = false) -> Spring {
    startValue = currentValue
    currentState.position = currentValue
    if !skipSetAtRest {
      setAtRest()
    }
    notifyPositionUpdated(notifyActivate: false, notifyAtRest: false)
    return self
  }
  
  public func currentValueIsApproximately(value: Double) -> Bool {
    return abs(currentValue - value) <= displacementFromRestThreshold
  }
  
  // MARK: Displacement
  
  // Get the absolute distance of the Spring from it's resting endValue position.
  public var currentDisplacementDistance: Double {
    get {
      return getDisplacementDistanceForState(currentState)
    }
  }
  
  public func getDisplacementDistanceForState(state: PhysicsState) -> Double {
    return abs(endValue - state.position)
  }
  
  // MARK: End Value
  
  // Retrieve the endValue or resting position of this spring.
  public private(set) var endValue: Double = 0
  
  // Set the endValue or resting position of the spring. If this
  // value is different than the current value, the SpringSystem will
  // be notified and will begin running its solver loop to resolve
  // the Spring to equilibrium. Any listeners that are registered
  // for onSpringEndStateChange will also be notified of this update
  // immediately.
  public func setEndValue(value: Double) -> Spring {
    if endValue == value && isAtRest {
      return self
    }
    startValue = currentValue
    endValue = value
    springSystem.activateSpring(self)
    for listener in listeners {
      listener(.EndStateChange(self))
    }
    return self
  }
  
  // MARK: Velocity
  
  // Get the current velocity of the Spring.
  public var velocity: Double {
    get {
      return currentState.velocity
    }
  }
  
  // Set the current velocity of the Spring. As previously mentioned,
  // this can be useful when you are performing a direct manipulation
  // gesture. When a UI element is released you may call setVelocity
  // on its animation Spring so that the Spring continues with the
  // same velocity as the gesture ended with. The friction, tension,
  // and displacement of the Spring will then govern its motion to
  // return to rest on a natural feeling curve.
  public func setVelocity(velocity: Double) -> Spring {
    if velocity == currentState.velocity {
      return self
    }
    currentState.velocity = velocity
    springSystem.activateSpring(self)
    return self
  }
  
  // MARK: Rest
  
  public var restSpeedThreshold: Double = 0.001
  
  public var displacementFromRestThreshold: Double = 0.001
  
  private(set) public var wasAtRest: Bool = true
  
  // Check if the Spring is atRest meaning that it's currentValue and
  // endValue are the same and that it has no velocity. The previously
  // described thresholds for speed and displacement define the bounds
  // of this equivalence check. If the Spring has 0 tension, then it will
  // be considered at rest whenever its absolute velocity drops below the
  // restSpeedThreshold.
  public var isAtRest: Bool {
    get {
      let displacement = getDisplacementDistanceForState(currentState)
      return abs(currentState.velocity) < restSpeedThreshold &&
        (displacement <= displacementFromRestThreshold || config.tension == 0)
    }
  }
  
  // Force the spring to be at rest at its current position. As
  // described in the documentation for setCurrentValue, this method
  // makes it easy to do synchronous non-animated updates to ui
  // elements that are attached to springs via SpringListeners.
  public func setAtRest() -> Spring {
    endValue = currentState.position
    tempState.position = currentState.position
    currentState.velocity = 0
    return self
  }
  
  // Check if the SpringSystem should advance. Springs are advanced
  // a final frame after they reach equilibrium to ensure that the
  // currentValue is exactly the requested endValue regardless of the
  // displacement threshold.
  public func systemShouldAdvance() -> Bool {
    return !isAtRest || !wasAtRest
  }
  
  private func interpolate(alpha: Double) {
    currentState.position = currentState.position *
      alpha + previousState.position * (1 - alpha)
    currentState.velocity = currentState.velocity *
      alpha + previousState.velocity * (1 - alpha)
  }
  
  // MARK: Advance
  
  private var timeAccumulator: Double = 0
  
  public func advance(time: Double, realDeltaTime: Double) {
    
    var _isAtRest = self.isAtRest
    
    if _isAtRest && wasAtRest {
      return
    }
    
    let adjustedDeltaTime = realDeltaTime > Spring.MAX_DELTA_TIME_SEC
      ? Spring.MAX_DELTA_TIME_SEC
      : realDeltaTime
    
    timeAccumulator += adjustedDeltaTime
    
    let tension = config.tension
    let friction = config.friction
    var position = currentState.position
    var velocity = currentState.velocity
    var tempPosition = tempState.position
    var tempVelocity = tempState.velocity
    let SOLVER_TIMESTEP_SEC = Spring.SOLVER_TIMESTEP_SEC
    
    var aVelocity: Double, aAcceleration: Double
    var bVelocity: Double, bAcceleration: Double
    var cVelocity: Double, cAcceleration: Double
    var dVelocity: Double, dAcceleration: Double
    var dxdt: Double, dvdt: Double
    
    while timeAccumulator >= SOLVER_TIMESTEP_SEC {
      
      timeAccumulator -= SOLVER_TIMESTEP_SEC
      
      if timeAccumulator < SOLVER_TIMESTEP_SEC {
        previousState.position = position
        previousState.velocity = velocity
      }
      
      aVelocity = velocity
      aAcceleration =
        (tension * (endValue - tempPosition)) - friction * velocity
      
      tempPosition = position + aVelocity * SOLVER_TIMESTEP_SEC * 0.5
      tempVelocity =
        velocity + aAcceleration * SOLVER_TIMESTEP_SEC * 0.5

      bVelocity = tempVelocity
      bAcceleration =
        (tension * (endValue - tempPosition)) - friction * tempVelocity
      
      tempPosition = position + bVelocity * SOLVER_TIMESTEP_SEC * 0.5
      tempVelocity =
        velocity + bAcceleration * SOLVER_TIMESTEP_SEC * 0.5
      
      cVelocity = tempVelocity
      cAcceleration =
        (tension * (endValue - tempPosition)) - friction * tempVelocity
      
      tempPosition = position + cVelocity * SOLVER_TIMESTEP_SEC * 0.5
      tempVelocity =
        velocity + cAcceleration * SOLVER_TIMESTEP_SEC * 0.5
      dVelocity = tempVelocity
      dAcceleration =
        (tension * (endValue - tempPosition)) - friction * tempVelocity
      
      dxdt =
        1.0/6.0 * (aVelocity + 2.0 * (bVelocity + cVelocity) + dVelocity)
      dvdt = 1.0/6.0 * (
        aAcceleration + 2.0 * (bAcceleration + cAcceleration) + dAcceleration
      )
      
      position += dxdt * SOLVER_TIMESTEP_SEC
      velocity += dvdt * SOLVER_TIMESTEP_SEC
    }
    
    tempState.position = tempPosition
    tempState.velocity = tempVelocity
    
    currentState.position = position
    currentState.velocity = velocity
    
    if timeAccumulator > 0 {
      interpolate(timeAccumulator / SOLVER_TIMESTEP_SEC)
    }
    
    if isAtRest || overshootClampingEnabled && isOvershooting {
      if config.tension > 0 {
        startValue = endValue
        currentState.position = endValue
      } else {
        endValue = currentState.position
        startValue = endValue
      }
      setVelocity(0)
      _isAtRest = true
    }
    
    var notifyActivate = false
    if wasAtRest {
      wasAtRest = false
      notifyActivate = true
    }
    
    var notifyAtRest = false
    if _isAtRest {
      wasAtRest = true
      notifyAtRest = true
    }
    
    notifyPositionUpdated(notifyActivate: notifyActivate, notifyAtRest: notifyAtRest)
  }
  
  // MARK: Notify
  
  private func notifyPositionUpdated(notifyActivate notifyActivate: Bool, notifyAtRest: Bool) {
    for listener in listeners {
      if notifyActivate {
        listener(.Activate(self))
      }
      listener(.Update(self))
      if notifyAtRest {
        listener(.Rest(self))
      }
    }
  }
  
  // MARK: Listeners
  
  private var listeners = Bag<SpringEvent.Sink>()
  
  public func getListenerCount() -> Int {
    return listeners.count
  }

  public func addListener(activate activate: ((Spring) -> ())? = nil, update: ((Spring) -> ())? = nil, rest: ((Spring) -> ())? = nil, endStateChange: ((Spring) -> ())? = nil) -> SpringRemovalToken {
    let sink = SpringEvent.sink(activate: activate, update: update, rest: rest, endStateChange: endStateChange)
    return listeners.insert(sink)
  }
  
  public func removeListener(token: SpringRemovalToken) {
    listeners.removeValueForToken(token)
  }
  
  public func removeAllListeners() {
    listeners.removeAll()
  }
  
}

public func ==(lhs: Spring, rhs: Spring) -> Bool {
  return lhs.hashValue == rhs.hashValue
}