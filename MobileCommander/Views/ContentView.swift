import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @AppStorage("appMode") private var appMode: String = AppMode.developer.rawValue

    private var mode: AppMode {
        AppMode(rawValue: appMode) ?? .developer
    }

    var body: some View {
        Group {
            switch mode {
            case .developer:
                DevTabView(appMode: $appMode)
            case .owner:
                OwnerTabView(appMode: $appMode)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appMode)
    }
}

// MARK: - Developer Tab View

struct DevTabView: View {
    @Binding var appMode: String
    @State private var selectedTab: DevTab = .dashboard

    enum DevTab: String {
        case dashboard = "Dashboard"
        case tasks = "Tasks"
        case workers = "Workers"
        case activity = "Activity"
        case settings = "Settings"
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DevDashboardView()
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Dashboard")
                }
                .tag(DevTab.dashboard)

            DevTaskListView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("Tasks")
                }
                .tag(DevTab.tasks)

            DevWorkersView()
                .tabItem {
                    Image(systemName: "server.rack")
                    Text("Workers")
                }
                .tag(DevTab.workers)

            DevActivityView()
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Activity")
                }
                .tag(DevTab.activity)

            SettingsView(appMode: $appMode)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(DevTab.settings)
        }
        .tint(.commanderOrange)
    }
}

// MARK: - Owner Tab View

struct OwnerTabView: View {
    @Binding var appMode: String
    @State private var selectedTab: OwnerTab = .home

    enum OwnerTab: String {
        case home = "Home"
        case create = "New Task"
        case settings = "Settings"
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            OwnerHomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(OwnerTab.home)

            OwnerTaskCreateView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("New Task")
                }
                .tag(OwnerTab.create)

            SettingsView(appMode: $appMode)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(OwnerTab.settings)
        }
        .tint(.commanderOrange)
    }
}

#Preview {
    ContentView()
        .environmentObject(DataStore.shared)
}
