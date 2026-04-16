import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        Group {
            if store.isAuthenticated {
                ContentView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.isAuthenticated)
    }
}

#Preview {
    RootView()
        .environmentObject(DataStore.shared)
}
