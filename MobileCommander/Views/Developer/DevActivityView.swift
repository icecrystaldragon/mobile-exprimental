import SwiftUI

struct DevActivityView: View {
    @EnvironmentObject var store: DataStore
    @State private var filterAction: String?

    private var actionTypes: [String] {
        Array(Set(store.activities.map { $0.action })).sorted()
    }

    private var filteredActivities: [ActivityEvent] {
        guard let filter = filterAction else { return store.activities }
        return store.activities.filter { $0.action == filter }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                filterBar
                activityList
            }
            .background(Color.commanderBg)
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterChip(label: "All", isSelected: filterAction == nil) {
                    withAnimation { filterAction = nil }
                }
                ForEach(actionTypes, id: \.self) { action in
                    FilterChip(
                        label: action.replacingOccurrences(of: "_", with: " ").capitalized,
                        isSelected: filterAction == action
                    ) {
                        withAnimation { filterAction = filterAction == action ? nil : action }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Activity List

    private var activityList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if filteredActivities.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No activity yet",
                        subtitle: "Actions will appear here as they happen"
                    )
                } else {
                    ForEach(filteredActivities) { event in
                        activityRow(event)
                    }
                }
            }
            .padding(.bottom, 32)
        }
    }

    private func activityRow(_ event: ActivityEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline dot
            VStack(spacing: 0) {
                Circle()
                    .fill(event.color)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color.commanderBorder.opacity(0.3))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 10)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: event.icon)
                        .font(.system(size: 12))
                        .foregroundColor(event.color)

                    Text(event.displayAction)
                        .font(.commanderCaptionMedium)
                        .foregroundColor(.commanderText)

                    Spacer()

                    if let time = event.timestamp {
                        Text(time.commanderRelative)
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                    }
                }

                // Details
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(event.details.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        HStack(spacing: 4) {
                            Text(key.replacingOccurrences(of: "_", with: " "))
                                .font(.commanderSmall)
                                .foregroundColor(.commanderMuted)
                            Text(value)
                                .font(.commanderSmall)
                                .foregroundColor(.commanderSecondary)
                        }
                    }
                }

                if let user = event.userName {
                    Text("by \(user)")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderMuted)
                }
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    DevActivityView()
        .environmentObject(DataStore.shared)
}
