import SwiftUI

struct WatchEntityRow: View {
    let entity: WatchEntity
    let pending: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(entity.isOn ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(entity.name)
                    .lineLimit(1)
                Text(entity.state.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if pending {
                ProgressView()
            }
        }
    }
}

#Preview {
    if let entity = WatchEntity(dictionary: [
        "entity_id": "light.living_room",
        "state": "on",
        "name": "Living Room",
    ]) {
        WatchEntityRow(entity: entity, pending: false)
    }
}
