//
//  BouncyConversion.swift
//  Rebound
//
//  Created by Adam Putinski on 7/31/15.
//

import Foundation

public class BouncyConversion {
  
  public let bounciness: Double
  public let bouncyTension: Double
  public let bouncyFriction: Double
  public let speed: Double
  
  public init(bounciness: Double, speed: Double) {
    let b = BouncyConversion.projectNormal(
      BouncyConversion.normalize(bounciness / 1.7, start: 0, end: 20.0), start: 0, end: 0.8
    )
    let s = BouncyConversion.normalize(speed / 1.7, start: 0, end: 2.0)
    self.bounciness = bounciness
    self.bouncyTension = BouncyConversion.projectNormal(s, start: 0.5, end: 200)
    self.bouncyFriction = BouncyConversion.quadraticOutInterpolation(
      b, start: BouncyConversion.b3Nobounce(bouncyTension), end: 0.01
    )
    self.speed = speed
  }
  
  static func normalize(value: Double, start: Double, end: Double) -> Double {
    return (value - start) / (end - start)
  }
  
  static func projectNormal(n: Double, start: Double, end: Double) -> Double {
    return start + (n * (end - start))
  }
  
  static func linearInterpolation(t: Double, start: Double, end: Double) -> Double {
    return t * end + (1.0 - t) * start
  }
  
  static func quadraticOutInterpolation(t: Double, start: Double, end: Double) -> Double {
    return linearInterpolation(2 * t - t * t, start: start, end: end)
  }
  
  static func b3Friction1(x: Double) -> Double {
    return (0.0007 * pow(x, 3)) - (0.031 * pow(x, 2)) + 0.64 * x + 1.28
  }
  
  static func b3Friction2(x: Double) -> Double {
    return (0.000044 * pow(x, 3)) - (0.006 * pow(x, 2)) + 0.36 * x + 2.0
  }
  
  static func b3Friction3(x: Double) -> Double {
    return (0.00000045 * pow(x, 3)) - (0.000332 * pow(x, 2)) + 0.1078 * x + 5.84
  }
  
  static func b3Nobounce(tension: Double) -> Double {
    if tension <= 18 {
      return b3Friction1(tension)
    } else if tension > 18 && tension <= 44 {
      return b3Friction2(tension)
    } else {
      return b3Friction3(tension)
    }
  }
  
}