import XCTest
@testable import HALegacyWatch

final class WatchEntityTests: XCTestCase {
    func testParsesEntityAndDomain() throws {
        let entity = try XCTUnwrap(WatchEntity(dictionary: [
            "entity_id": "light.living_room",
            "state": "on",
            "name": "Living Room",
            "brightness": 128,
        ]))

        XCTAssertEqual(entity.entityID, "light.living_room")
        XCTAssertEqual(entity.domain, "light")
        XCTAssertTrue(entity.isOn)
        XCTAssertEqual(entity.brightness ?? 0, 50.2, accuracy: 0.1)
    }

    func testRejectsIncompleteEntity() {
        XCTAssertNil(WatchEntity(dictionary: ["entity_id": "switch.fan"]))
    }
}
