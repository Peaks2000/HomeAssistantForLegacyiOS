import SwiftUI

struct WatchEntityDetailView: View {
    @EnvironmentObject private var store: WatchSessionStore
    let entity: WatchEntity
    @State private var brightness = 50.0

    var body: some View {
        List {
            Text(entity.state.capitalized)
                .foregroundStyle(.secondary)

            if entity.domain == "light" || entity.domain == "switch" {
                Button(entity.isOn ? WatchStrings.turnOff : WatchStrings.turnOn) {
                    store.callService(
                        for: entity,
                        domain: "homeassistant",
                        service: entity.isOn ? "turn_off" : "turn_on"
                    )
                }
            } else if entity.domain == "lock" {
                Button(entity.isOn ? WatchStrings.lock : WatchStrings.unlock) {
                    store.callService(
                        for: entity,
                        domain: "lock",
                        service: entity.isOn ? "lock" : "unlock"
                    )
                }
            } else if entity.domain == "cover" {
                Button(WatchStrings.open) {
                    store.callService(for: entity, domain: "cover", service: "open_cover")
                }
                Button(WatchStrings.stop) {
                    store.callService(for: entity, domain: "cover", service: "stop_cover")
                }
                Button(WatchStrings.close) {
                    store.callService(for: entity, domain: "cover", service: "close_cover")
                }
            } else if ["scene", "script", "automation"].contains(entity.domain) {
                Button(WatchStrings.run) {
                    store.callService(for: entity, domain: entity.domain, service: "turn_on")
                }
            } else if entity.domain == "button" {
                Button(WatchStrings.press) {
                    store.callService(for: entity, domain: "button", service: "press")
                }
            }

            if entity.domain == "light" {
                Slider(value: $brightness, in: 1 ... 100, step: 5)
                Button(WatchStrings.applyBrightness) {
                    store.callService(
                        for: entity,
                        domain: "light",
                        service: "turn_on",
                        serviceData: ["brightness_pct": Int(brightness)]
                    )
                }
                Button(WatchStrings.red) {
                    store.callService(
                        for: entity,
                        domain: "light",
                        service: "turn_on",
                        serviceData: ["rgb_color": [255, 0, 0]]
                    )
                }
                Button(WatchStrings.green) {
                    store.callService(
                        for: entity,
                        domain: "light",
                        service: "turn_on",
                        serviceData: ["rgb_color": [0, 255, 0]]
                    )
                }
                Button(WatchStrings.blue) {
                    store.callService(
                        for: entity,
                        domain: "light",
                        service: "turn_on",
                        serviceData: ["rgb_color": [0, 0, 255]]
                    )
                }
                Button(WatchStrings.white) {
                    store.callService(
                        for: entity,
                        domain: "light",
                        service: "turn_on",
                        serviceData: ["rgb_color": [255, 255, 255]]
                    )
                }
            }
        }
        .navigationTitle(entity.name)
        .onAppear {
            brightness = entity.brightness ?? 50
        }
    }
}

#Preview {
    if let entity = WatchEntity(dictionary: [
        "entity_id": "light.living_room",
        "state": "on",
        "name": "Living Room",
        "brightness": 180,
    ]) {
        NavigationView {
            WatchEntityDetailView(entity: entity)
                .environmentObject(WatchSessionStore.preview)
        }
    }
}
