// Copyright (c) 2012 - 2015, GitHub, Inc. All rights reserved.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  Bag.swift
//  ReactiveCocoa
//
//  Created by Justin Spahr-Summers on 2014-07-10.
//

import Foundation

/// A uniquely identifying token for removing a value that was inserted into a Bag.
public final class SpringRemovalToken {
  private(set) public var identifier: UInt?
  init(identifier: UInt) {
    self.identifier = identifier
  }
}

/// An unordered, non-unique collection of values of type T.
internal struct Bag<T> {
  private var elements: [BagElement<T>] = []
  private var currentIdentifier: UInt = 0
  
  /// Inserts the given value in the collection, and returns a token that can
  /// later be passed to removeValueForToken().
  mutating func insert(value: T) -> SpringRemovalToken {
    let nextIdentifier = currentIdentifier &+ 1
    if nextIdentifier == 0 {
      reindex()
    }
    
    let token = SpringRemovalToken(identifier: currentIdentifier)
    let element = BagElement(value: value, identifier: currentIdentifier, token: token)
    
    elements.append(element)
    currentIdentifier++
    
    return token
  }
  
  mutating func removeAll() {
    elements.removeAll()
  }
  
  /// Removes a value, given the token returned from insert().
  ///
  /// If the value has already been removed, nothing happens.
  mutating func removeValueForToken(token: SpringRemovalToken) {
    if let identifier = token.identifier {
      // Removal is more likely for recent objects than old ones.
      for var i = elements.count - 1; i >= 0; i-- {
        if elements[i].identifier == identifier {
          elements.removeAtIndex(i)
          token.identifier = nil
          break
        }
      }
    }
    print(elements.count)
  }
  
  /// In the event of an identifier overflow (highly, highly unlikely), this
  /// will reset all current identifiers to reclaim a contiguous set of
  /// available identifiers for the future.
  private mutating func reindex() {
    for var i = 0; i < elements.count; i++ {
      currentIdentifier = UInt(i)
      
      elements[i].identifier = currentIdentifier
      elements[i].token.identifier = currentIdentifier
    }
  }
}

extension Bag: SequenceType {
  func generate() -> AnyGenerator<T> {
    var index = 0
    let count = elements.count
    
    return anyGenerator {
      if index < count {
        return self.elements[index++].value
      } else {
        return nil
      }
    }
  }
}

extension Bag: CollectionType {
  typealias Index = Array<T>.Index
  
  var startIndex: Index {
    return 0
  }
  
  var endIndex: Index {
    return elements.count
  }
  
  subscript(index: Index) -> T {
    return elements[index].value
  }
}

private struct BagElement<T> {
  let value: T
  var identifier: UInt
  let token: SpringRemovalToken
}

extension BagElement: CustomStringConvertible {
  var description: String {
    return "BagElement(\(value))"
  }
}