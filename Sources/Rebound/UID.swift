//
//  UID.swift
//  Rebound
//
//  Created by Adam Putinski on 7/15/16.
//
//

import Foundation

struct UID {
 
  private static var UID: Int32 = 0
  
  static func next() -> Int32 {
    return OSAtomicIncrement32(&UID)
  }
  
}
