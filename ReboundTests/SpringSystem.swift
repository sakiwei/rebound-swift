//
//  ReboundTests.swift
//  ReboundTests
//
//  Created by Adam Putinski on 7/31/15.
//

import XCTest
@testable import Rebound

class SpringSystemSpec: XCTestCase {
  
  var system: SpringSystem!
  
  override func setUp() {
    system = SpringSystem(looper: SimulationLooper())
  }
  
  func testItCreatesSpringsAndMaintainsARegistryOfSprings() {
    _ = system.createSpring()
    XCTAssert(system.springs.count == 1)
  }
  
  func testItStartsOutIdle() {
    _ = system.createSpring()
    XCTAssert(system.idle)
  }
  
  func testItActivatesWhenASpringIsMoved() {
    class TestSpringSystem: SpringSystem {
      var activateSpringCalledWith: Spring?
      override func activateSpring(_ spring: Spring) {
        activateSpringCalledWith = spring
      }
    }
    let system = TestSpringSystem()
    let spring = system.createSpring()
    XCTAssert(system.idle)
    spring.setEndValue(1)
    XCTAssertEqual(system.activateSpringCalledWith, spring)
  }
  
  func testItCanHaveListeners() {
    let removeToken = system.addListener()
    XCTAssertEqual(system.getListenerCount(), 1)
    system.removeListener(removeToken)
    XCTAssertEqual(system.getListenerCount(), 0)
    system.addListener()
    system.addListener()
    system.addListener()
    system.addListener()
    XCTAssertEqual(system.getListenerCount(), 4)
    system.removeAllListeners()
    XCTAssertEqual(system.getListenerCount(), 0)
  }
  
  func testItShouldCallItsListenersOnEachFrameOfTheAnimation() {
    let looper = SteppingSimulationLooper()
    let timestep = 16.667
    var beforeIntegrateCalled: SpringSystem!
    var afterIntegrateCalled: SpringSystem!
    system.setLooper(looper)
    system.addListener(
      beforeIntegrate: { s in
        beforeIntegrateCalled = s
      },
      afterIntegrate: { s in
        afterIntegrateCalled = s
      }
    )
    let spring = system.createSpring()
    spring.setEndValue(1)
    looper.step(timestep)
    XCTAssert(beforeIntegrateCalled === system)
    XCTAssert(afterIntegrateCalled === system)
  }
  
}
