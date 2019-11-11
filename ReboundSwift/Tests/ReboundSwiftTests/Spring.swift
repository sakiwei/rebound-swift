//
//  Spring.swift
//  Rebound
//
//  Created by Adam Putinski on 8/1/15.
//

import XCTest
@testable import ReboundSwift

class SpringSpec: XCTestCase {
  
  var system: SpringSystem!
  var spring: Spring!
  
  override func setUp() {
    system = SpringSystem(looper: SimulationLooper())
    spring = system.createSpring()
  }
  
  func testItIsCreatedAtRest() {
    XCTAssert(spring.isAtRest)
    XCTAssertEqual(spring.currentValue, 0)
    XCTAssertEqual(spring.endValue, 0)
    XCTAssertEqual(spring.velocity, 0)
  }
  
  func testItCanHaveListeners() {
    let removeToken = spring.addListener()
    XCTAssertEqual(spring.getListenerCount(), 1)
    spring.removeListener(removeToken)
    XCTAssertEqual(spring.getListenerCount(), 0)
    spring.addListener()
    spring.addListener()
    spring.addListener()
    spring.addListener()
    XCTAssertEqual(spring.getListenerCount(), 4)
    spring.removeAllListeners()
    XCTAssertEqual(spring.getListenerCount(), 0)
  }
  
  func testItPerformsTheExpectedNumericalIntegration() {
    let expectedValues = [
      9.52848338491667e-05, 0.0280551305179629, 0.0976222162450096, 0.190497295109813,
      0.293671406740464, 0.404972861445447, 0.511154620365362, 0.608094950748042, 0.698951264400022,
      0.776398779443102, 0.840705433961584, 0.895891857904224, 0.938997248097101, 0.97173377816996,
      0.997159213205988, 1.01476258136631, 1.02622082577252, 1.03329564932684, 1.03648946072759,
      1.03693989835553, 1.03540388512924, 1.03257859112136, 1.0290563359258, 1.02500642918106,
      1.02097461568528, 1.01717719976916, 1.01352576938495, 1.01034175794478, 1.00764258881001,
      1.0052779569598, 1.00339015100599, 1.00192189582887, 1.00074860414277, 0.999905475829482,
      0.999327247722712, 0.998937454133214, 0.998722961913546, 0.998636250658114, 0.998641642340227,
      0.998713318946208, 0.998824878849694, 0.998966054352768, 0.999114736756395, 0.999260176669424,
      0.999404175513922, 0.99953287104958, 0.999644341038988, 0.999744018657976, 0.99982527212144,
      0.999889854959369, 0.999942754508108, 0.999981940911546, 1.0000098947929, 1.0
    ]

    let expectedVelocities = [
      0.228097133938337, 3.18362795565378, 5.18969355221027, 6.30813323126167,
      6.77768007214265, 6.77982070324507, 6.44238061699663, 5.89889697645961,
      5.20272072228581, 4.464480016355, 3.73912445737494, 3.0186340411984,
      2.37287827903462, 1.81217685432229, 1.30966581693994, 0.899063471343696,
      0.571907908370749, 0.303217761832437, 0.103527665273483, -0.0395034891417408,
      -0.142350714486958, -0.205860785078523, -0.239846237850156, -0.25264329505409,
      -0.248793645303234, -0.234145130232077, -0.211581130826735, -0.185501057593562,
      -0.15853434660787, -0.130760368115395, -0.105145469346107, -0.0823722207562575,
      -0.0615193132781277, -0.0441214723178374, -0.0299690850716248, -0.0180823343233512,
      -0.0090150795817449, -0.00231313923658305, 0.0027155555738821, 0.00603264077492341,
      0.00803456840095728, 0.00909565564543121, 0.00936894907445586, 0.00910612207902817,
      0.008453224982293, 0.00758173875580081, 0.00661380014855828, 0.0055701159887829,
      0.00457462163674249, 0.00366596517146286, 0.00281474053224796, 0.0020893441663067,
      0.00148722044181752, 0.000970784332533191, 0.0
    ]

    var actualValues = [Double]()
    var actualVelocities = [Double]()
    spring.addListener(update: { spring in
      actualValues.append(spring.currentValue)
      actualVelocities.append(spring.velocity)
    })
    spring.setEndValue(1)
    
    var valuesAreClose = true
    for (index, actualItem) in actualValues.enumerated() {
      if fabs(actualItem - expectedValues[index]) > 0.0001 {
        valuesAreClose = false
        break
      }
    }
    
    var velocitiesAreClose = true
    for (index, actualItem) in expectedVelocities.enumerated() {
      if fabs(actualItem - expectedVelocities[index]) > 0.0001 {
        velocitiesAreClose = false
        break
      }
    }

    XCTAssert(valuesAreClose)
    XCTAssert(velocitiesAreClose)
  }
  
  func testItShouldNotOscillateIfOvershootClampingIsEnabled() {
    var actualValues = [Double]()
    spring.addListener(update: { spring in
      actualValues.append(spring.currentValue)
    })
    spring.overshootClampingEnabled = true
    spring.setEndValue(1)
    var didOscillate = false
    var priorValue: Double = -1
    for value in actualValues {
      if value < priorValue {
        didOscillate = true
        break
      }
      priorValue = value
    }
    XCTAssertFalse(didOscillate)
  }
  
  func testItShouldNotOscillateIfTheSpringHas0Tension() {
    var actualValues = [Double]()
    spring.addListener(update: { spring in
      actualValues.append(spring.currentValue)
    })
    spring.config = SpringConfig.coastingConfigWithOrigamiFriction(7)
    spring.setVelocity(1000)
    var didOscillate = false
    var priorValue: Double = -1
    for value in actualValues {
      if value < priorValue {
        didOscillate = true
        break
      }
      priorValue = value
    }
    XCTAssertFalse(didOscillate)
  }
  
  func testItShouldBeAtRestAfterCallingSetCurrentValue() {
    let system = SpringSystem(looper: SimulationLooper())
    let spring = system.createSpring()
    spring.setEndValue(1)
    spring.setCurrentValue(-1.0)
    XCTAssert(spring.isAtRest)
    XCTAssertEqual(spring.currentValue, -1.0)
    XCTAssertEqual(spring.endValue, -1.0)
  }
  
  func testItShouldNotBeAtRestIfTheSkipSetAtRestParameterIsPassedToSetCurrentValueWhileMoving() {
    let system = SpringSystem(looper: SimulationLooper())
    let spring = system.createSpring()
    spring.setEndValue(1)
    spring.setCurrentValue(-1.0, skipSetAtRest: true)
    XCTAssertFalse(spring.isAtRest)
    XCTAssertEqual(spring.currentValue, -1.0)
    XCTAssertEqual(spring.endValue, 1.0)
  }
  
}
