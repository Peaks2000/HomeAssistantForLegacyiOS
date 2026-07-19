import Foundation

struct WatchEntity: Identifiable, Hashable {
    let entityID: String
    var state: String
    let name: String
    let brightness: Double?

    var id: String { entityID }

    var domain: String {
        entityID.components(separatedBy: ".").first ?? ""
    }

    var isOn: Bool {
        state == "on" || state == "open" || state == "unlocked"
    }

    init?(dictionary: [String: Any]) {
        guard let entityID = dictionary["entity_id"] as? String,
              let state = dictionary["state"] as? String else { return nil }
        self.entityID = entityID
        self.state = state
        name = dictionary["name"] as? String ?? entityID
        if let rawBrightness = dictionary["brightness"] as? NSNumber {
            brightness = rawBrightness.doubleValue * 100 / 255
        } else {
            brightness = nil
        }
    }
}
