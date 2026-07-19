import Combine
import Foundation
import WatchConnectivity

@MainActor
final class WatchSessionStore: NSObject, ObservableObject {
    @Published private(set) var entities: [WatchEntity] = []
    @Published private(set) var homeID = ""
    @Published private(set) var homeName = "Home Assistant"
    @Published private(set) var selectedEntityIDs: Set<String> = []
    @Published private(set) var pendingEntityID: String?
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var viewMode: WatchViewMode = .myDevices

    private let session: WCSession

    init(activateSession: Bool = true) {
        session = .default
        super.init()
        if activateSession, WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    func callService(
        for entity: WatchEntity,
        domain: String,
        service: String,
        serviceData: [String: Any] = [:]
    ) {
        guard session.isReachable else {
            errorMessage = WatchStrings.openPhone
            return
        }
        pendingEntityID = entity.entityID
        session.sendMessage(
            [
                "type": "call_service",
                "home_id": homeID,
                "entity_id": entity.entityID,
                "domain": domain,
                "service": service,
                "service_data": serviceData,
            ],
            replyHandler: { [weak self] reply in
                Task { @MainActor in
                    self?.pendingEntityID = nil
                    if reply["ok"] as? Bool == true {
                        self?.applyOptimisticState(entityID: entity.entityID, service: service)
                    } else {
                        self?.errorMessage = reply["message"] as? String ?? WatchStrings.openPhone
                    }
                }
            },
            errorHandler: { [weak self] error in
                Task { @MainActor in
                    self?.pendingEntityID = nil
                    self?.errorMessage = error.localizedDescription
                }
            }
        )
    }

    private func apply(context: [String: Any]) {
        guard context["protocol_version"] as? Int == 1 else { return }
        homeID = context["home_id"] as? String ?? ""
        homeName = context["home_name"] as? String ?? "Home Assistant"
        selectedEntityIDs = Set(context["selected_entity_ids"] as? [String] ?? [])
        entities = (context["entities"] as? [[String: Any]] ?? []).compactMap(WatchEntity.init)
    }

    private func applyOptimisticState(entityID: String, service: String) {
        guard let index = entities.firstIndex(where: { $0.entityID == entityID }) else { return }
        switch service {
        case "turn_on", "open_cover", "unlock":
            entities[index].state = service == "open_cover" ? "open" : service == "unlock" ? "unlocked" : "on"
        case "turn_off", "close_cover", "lock":
            entities[index].state = service == "close_cover" ? "closed" : service == "lock" ? "locked" : "off"
        case "toggle":
            entities[index].state = entities[index].isOn ? "off" : "on"
        default:
            break
        }
    }

    static var preview: WatchSessionStore {
        let store = WatchSessionStore(activateSession: false)
        store.homeID = "preview-home"
        store.homeName = "Home"
        store.selectedEntityIDs = ["light.living_room", "switch.fan"]
        store.entities = [
            WatchEntity(dictionary: [
                "entity_id": "light.living_room",
                "state": "on",
                "name": "Living Room",
                "brightness": 180,
            ]),
            WatchEntity(dictionary: [
                "entity_id": "switch.fan",
                "state": "off",
                "name": "Fan",
            ]),
        ].compactMap { $0 }
        return store
    }
}

extension WatchSessionStore: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith _: WCSessionActivationState,
        error _: Error?
    ) {
        let context = session.receivedApplicationContext
        Task { @MainActor in
            apply(context: context)
        }
    }

    nonisolated func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            apply(context: applicationContext)
        }
    }
}
