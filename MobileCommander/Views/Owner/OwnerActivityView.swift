import SwiftUI

struct OwnerActivityView: View {
    @EnvironmentObject var store: DataStore

    private var groupedActivities: [(String, [ActivityEvent])] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"

        var groups: [String: [ActivityEvent]] = [:]
        var order: [String] = []

        for event in store.activities {
            let key: String
            if let ts = event.timestamp {
                if Calendar.current.isDateInToday(ts) {
                    key = "Today"
                } else if Calendar.current.isDateInYesterday(ts) {
                    key = "Yesterday"
                } else {
                    key = dateFormatter.string(from: ts)
                }
            } else {
                key = "Unknown"
            }

            if groups[key] == nil {
                order.append(key)
            }
            groups[key, default: []].append(event)
        }

        return order.map { ($0, groups[$0]!) }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if store.activities.isEmpty {
                        EmptyStateView(
                            icon: "clock.arrow.circlepath",
                            title: "No activity yet",
                            subtitle: "Things will show up here as tasks are created and completed."
                        )
                    } else {
                        ForEach(groupedActivities, id: \.0) { group, events in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group)
                                    .font(.commanderCaptionMedium)
                                    .foregroundColor(.commanderSecondary)
                                    .padding(.horizontal, 16)

                                ForEach(events) { event in
                                    activityCard(event)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color.commanderBg)
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func activityCard(_ event: ActivityEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(event.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: event.icon)
                    .font(.system(size: 14))
                    .foregroundColor(event.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(friendlyAction(event))
                    .font(.commanderBody)
                    .foregroundColor(.commanderText)

                if let detail = friendlyDetail(event) {
                    Text(detail)
                        .font(.commanderCaption)
                        .foregroundColor(.commanderSecondary)
                        .lineLimit(2)
                }

                if let time = event.timestamp {
                    Text(time.commanderTimeString)
                        .font(.commanderSmall)
                        .foregroundColor(.commanderMuted)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.commanderSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.commanderBorder, lineWidth: 0.5)
        )
    }

    private func friendlyAction(_ event: ActivityEvent) -> String {
        switch event.action {
        case "task_created":
            return "New task created"
        case "task_retried":
            return "Task sent back for another try"
        case "chat_message_sent":
            return "Message sent"
        case "task_status_changed":
            if let status = event.details["new_status"] {
                switch status {
                case "done": return "Task completed"
                case "failed": return "Task ran into a problem"
                case "running": return "Task started working"
                default: return "Task status changed"
                }
            }
            return "Task updated"
        case "task_deleted":
            return "Task removed"
        case "task_approved":
            return "Task approved"
        case "task_changes_requested":
            return "Changes requested"
        default:
            return event.displayAction
        }
    }

    private func friendlyDetail(_ event: ActivityEvent) -> String? {
        if let taskName = event.details["task_name"] {
            return taskName
        }
        if let project = event.details["project"], let numId = event.details["task_num_id"] {
            return "#\(numId) in \(project)"
        }
        if let preview = event.details["message_preview"] {
            return "\"\(preview)\""
        }
        return nil
    }
}

#Preview {
    OwnerActivityView()
        .environmentObject(DataStore.shared)
}
