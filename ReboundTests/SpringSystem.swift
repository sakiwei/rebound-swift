//
//  ReboundTests.swift
//  ReboundTests
//
//  Created by Adam Putinski on 7/31/15.
//

import Quick
import Nimble
import Rebound

class SpringSystemSpec: QuickSpec {
  
  override func spec() {
    var system: SpringSystem!
        
    beforeEach {
      system = SpringSystem(looper: SimulationLooper())
    }
    
    it("creates springs and maintains a registry of springs") {
      system.createSpring()
      expect(system.springs.count).to(equal(1))
    }
    
    it("starts out idle") {
      system.createSpring()
      expect(system.idle).to(beTrue())
    }
    
    it("activates when a spring is moved") {
      class TestSpringSystem: SpringSystem {
        var activateSpringCalledWith: Spring?
        override func activateSpring(spring: Spring) {
          activateSpringCalledWith = spring
        }
      }
      let system = TestSpringSystem()
      let spring = system.createSpring()
      expect(system.idle).to(beTrue())
      spring.setEndValue(1)
      expect(system.activateSpringCalledWith).to(equal(spring))
    }
    
    it("can have listeners") {
      let removeToken = system.addListener()
      expect(system.getListenerCount()).to(equal(1))
      system.removeListener(removeToken)
      expect(system.getListenerCount()).to(equal(0))
      system.addListener()
      system.addListener()
      system.addListener()
      system.addListener()
      expect(system.getListenerCount()).to(equal(4))
      system.removeAllListeners()
      expect(system.getListenerCount()).to(equal(0))
    }
    
    it("should call its listeners on each frame of the animation") {
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
      expect(beforeIntegrateCalled).to(beIdenticalTo(system))
      expect(afterIntegrateCalled).to(beIdenticalTo(system))
    }
  }
    
}
