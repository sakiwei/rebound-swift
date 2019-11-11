//
//  SpringConfig.swift
//  Rebound
//
//  Created by Adam Putinski on 7/31/15.
//

import Foundation

public struct SpringConfig {
  
  public var tension: Double = 0
  public var friction: Double = 0
  
  public static let DEFAULT_ORIGAMI_SPRING_CONFIG = SpringConfig
    .fromOrigamiTensionAndFriction(tension: 40.0, friction: 7.0)
  
  public static func fromOrigamiTensionAndFriction(tension: Double, friction: Double) -> SpringConfig {
    return SpringConfig(
      tension: OrigamiValueConverter.tensionFromOrigamiValue(tension),
      friction: OrigamiValueConverter.frictionFromOrigamiValue(friction)
    )
  }
  
  public static func fromBouncinessAndSpeed(_ bounciness: Double, speed: Double) -> SpringConfig {
    let bouncyConversion = BouncyConversion(bounciness: bounciness, speed: speed)
    return fromOrigamiTensionAndFriction(
      tension: bouncyConversion.bouncyTension, friction: bouncyConversion.bouncyFriction
    )
  }
  
  public static func coastingConfigWithOrigamiFriction(_ friction: Double) -> SpringConfig {
    return SpringConfig(
      tension: 0,
      friction: OrigamiValueConverter.frictionFromOrigamiValue(friction)
    )
  }
  
}
