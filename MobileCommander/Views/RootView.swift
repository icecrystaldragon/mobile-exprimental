import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        Group {
            if store.isAuthenticated {
                if store.isLoading {
                    loadingView
                } else {
                    ContentView()
                }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: store.isLoading)
    }

    private var loadingView: some View {
        ZStack {
            Color.commanderBg.ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.commanderOrange.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.commanderOrange)
                }

                ProgressView()
                    .tint(.commanderOrange)

                Text("Loading...")
                    .font(.commanderCaption)
                    .foregroundColor(.commanderSecondary)
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(DataStore.shared)
}
