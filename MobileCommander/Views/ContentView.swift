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
    @EnvironmentObject var store: DataStore
    @Binding var appMode: String
    @State private var selectedTab: DevTab = .dashboard

    enum DevTab: String {
        case dashboard = "Dashboard"
        case tasks = "Tasks"
        case notifications = "Alerts"
        case reports = "Reports"
        case settings = "Settings"
    }

    private var reviewCount: Int {
        store.tasks.filter { $0.effectiveStatus == .needsReview }.count
    }

    private var attentionCount: Int {
        store.tasks.filter { $0.status == .failed || $0.status == .blocked }.count
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DevDashboardView()
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Dashboard")
                }
                .tag(DevTab.dashboard)
                .badge(attentionCount + reviewCount)

            DevTaskListView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("Tasks")
                }
                .tag(DevTab.tasks)
                .badge(reviewCount)

            DevNotificationsView()
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Alerts")
                }
                .tag(DevTab.notifications)
                .badge(attentionCount)

            DevReportsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Reports")
                }
                .tag(DevTab.reports)

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
    @EnvironmentObject var store: DataStore
    @Binding var appMode: String
    @State private var selectedTab: OwnerTab = .home

    enum OwnerTab: String {
        case home = "Home"
        case create = "New Task"
        case messages = "Messages"
        case activity = "Activity"
        case settings = "Settings"
    }

    private var attentionCount: Int {
        store.tasks.filter { $0.status == .failed || $0.status == .blocked || $0.effectiveStatus == .needsReview }.count
    }

    private var runningCount: Int {
        store.tasks.filter { $0.status == .running }.count
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            OwnerHomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(OwnerTab.home)
                .badge(attentionCount)

            OwnerTaskCreateView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("New Task")
                }
                .tag(OwnerTab.create)

            OwnerChatListView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Messages")
                }
                .tag(OwnerTab.messages)
                .badge(runningCount)

            OwnerActivityView()
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Activity")
                }
                .tag(OwnerTab.activity)

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
