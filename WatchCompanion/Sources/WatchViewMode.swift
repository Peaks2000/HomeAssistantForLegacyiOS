import Foundation

enum WatchViewMode: String, CaseIterable, Identifiable {
    case myDevices
    case allDevices

    var id: String { rawValue }

    var title: String {
        switch self {
        case .myDevices:
            WatchStrings.myDevices
        case .allDevices:
            WatchStrings.allDevices
        }
    }
}
