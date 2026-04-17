import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: DataStore
    @Binding var appMode: String

    private var mode: AppMode {
        AppMode(rawValue: appMode) ?? .developer
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    modeSelector
                    accountSection
                    if mode == .developer {
                        quickLinksSection
                    }
                    statsSection
                    aboutSection
                    signOutButton
                }
                .padding(16)
            }
            .background(Color.commanderBg)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Interface Mode")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderOrange)

                ForEach(AppMode.allCases, id: \.rawValue) { modeOption in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appMode = modeOption.rawValue
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: modeOption.icon)
                                .font(.system(size: 20))
                                .foregroundColor(mode == modeOption ? .commanderOrange : .commanderMuted)
                                .frame(width: 36, height: 36)
                                .background(mode == modeOption ? Color.commanderOrangeDim : Color.commanderBg)
                                .cornerRadius(8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(modeOption.rawValue)
                                    .font(.commanderSubhead)
                                    .foregroundColor(.commanderText)
                                Text(modeOption.description)
                                    .font(.commanderSmall)
                                    .foregroundColor(.commanderSecondary)
                            }

                            Spacer()

                            if mode == modeOption {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.commanderOrange)
                            }
                        }
                        .padding(12)
                        .background(mode == modeOption ? Color.commanderOrangeDim.opacity(0.3) : Color.clear)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Account")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderOrange)

                if let user = store.currentUser {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.commanderOrange.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Text(String((user.displayName ?? user.email ?? "?").prefix(1)).uppercased())
                                .font(.commanderSubhead)
                                .foregroundColor(.commanderOrange)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            if let name = user.displayName {
                                Text(name)
                                    .font(.commanderSubhead)
                                    .foregroundColor(.commanderText)
                            }
                            if let email = user.email {
                                Text(email)
                                    .font(.commanderCaption)
                                    .foregroundColor(.commanderSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Stats")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderOrange)

                HStack(spacing: 16) {
                    miniStat("Tasks", "\(store.tasks.count)")
                    miniStat("Workers", "\(store.workers.count)")
                    miniStat("Cost", String(format: "$%.2f", store.totalCost))
                    miniStat("Done", "\(store.taskCounts[.done] ?? 0)")
                }
            }
        }
    }

    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.commanderSubhead)
                .foregroundColor(.commanderText)
            Text(label)
                .font(.commanderSmall)
                .foregroundColor(.commanderMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Links (Developer only)

    private var quickLinksSection: some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Links")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderOrange)

                NavigationLink(destination: DevWorkersView()) {
                    quickLinkRow(icon: "server.rack", label: "Workers", subtitle: "\(store.workers.filter { $0.status != .offline }.count) online")
                }
                .buttonStyle(.plain)

                NavigationLink(destination: DevActivityView()) {
                    quickLinkRow(icon: "clock.arrow.circlepath", label: "Activity Log", subtitle: "\(store.activities.count) events")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func quickLinkRow(icon: String, label: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.commanderOrange)
                .frame(width: 28, height: 28)
                .background(Color.commanderOrangeDim)
                .cornerRadius(6)

            Text(label)
                .font(.commanderBody)
                .foregroundColor(.commanderText)

            Spacer()

            Text(subtitle)
                .font(.commanderCaption)
                .foregroundColor(.commanderSecondary)

            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(.commanderMuted)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("About")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderOrange)

                settingsRow(icon: "terminal", label: "Commander", value: "Mobile v1.0")
                settingsRow(icon: "server.rack", label: "Backend", value: "Firebase")
                settingsRow(icon: "cpu", label: "AI Model", value: "Claude Opus 4.6")
            }
        }
    }

    private func settingsRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.commanderOrange)
                .frame(width: 28, height: 28)
                .background(Color.commanderOrangeDim)
                .cornerRadius(6)

            Text(label)
                .font(.commanderBody)
                .foregroundColor(.commanderText)

            Spacer()

            Text(value)
                .font(.commanderCaption)
                .foregroundColor(.commanderSecondary)
        }
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button {
            store.signOut()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
                    .font(.commanderSubhead)
            }
            .foregroundColor(.commanderRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.commanderRedDim)
            .cornerRadius(12)
        }
    }
}

#Preview {
    SettingsView(appMode: .constant("Developer"))
        .environmentObject(DataStore.shared)
}
