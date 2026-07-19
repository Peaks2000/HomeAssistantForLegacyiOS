import SwiftUI

struct WatchRootView: View {
    @EnvironmentObject private var store: WatchSessionStore

    var body: some View {
        let visibleEntities = store.entities.filter { entity in
            let belongsToSelectedView = store.viewMode == .allDevices || store.selectedEntityIDs.contains(entity.entityID)
            let matchesSearch = store.searchText.isEmpty ||
                entity.name.localizedCaseInsensitiveContains(store.searchText) ||
                entity.entityID.localizedCaseInsensitiveContains(store.searchText)
            return belongsToSelectedView && matchesSearch
        }

        NavigationView {
            VStack(spacing: 4) {
                Picker(WatchStrings.devices, selection: $store.viewMode) {
                    ForEach(WatchViewMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if visibleEntities.isEmpty {
                    Text(store.entities.isEmpty ? WatchStrings.openPhone : WatchStrings.noDevices)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    List(visibleEntities) { entity in
                        NavigationLink {
                            WatchEntityDetailView(entity: entity)
                        } label: {
                            WatchEntityRow(entity: entity, pending: store.pendingEntityID == entity.entityID)
                        }
                    }
                    .listStyle(.carousel)
                }
            }
            .navigationTitle(store.homeName)
            .searchable(text: $store.searchText, prompt: WatchStrings.search)
            .alert(
                "Home Assistant",
                isPresented: Binding(
                    get: { store.errorMessage != nil },
                    set: { if !$0 { store.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    store.errorMessage = nil
                }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }
}

#Preview {
    WatchRootView()
        .environmentObject(WatchSessionStore.preview)
}
