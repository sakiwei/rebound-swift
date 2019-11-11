//
//  OrigamiValueConverter.swift
//  Rebound
//
//  Created by Adam Putinski on 7/31/15.
//

import Foundation

public struct OrigamiValueConverter {
  
  public static func tensionFromOrigamiValue(_ oValue: Double) -> Double {
    return (oValue - 30.0) * 3.62 + 194.0
  }
  
  public static func origamiValueFromTension(_ tension: Double) -> Double {
    return (tension - 194.0) / 3.62 + 30.0;
  }
  
  public static func frictionFromOrigamiValue(_ oValue: Double) -> Double {
    return (oValue - 8.0) * 3.0 + 25.0;
  }
  
  public static func origamiFromFriction(_ friction: Double) -> Double {
    return (friction - 25.0) / 3.0 + 8.0;
  }
  
}
