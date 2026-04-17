import SwiftUI

struct DevNotificationsView: View {
    @EnvironmentObject var store: DataStore
    @State private var filter: NotifFilter = .all

    enum NotifFilter: String, CaseIterable {
        case all = "All"
        case attention = "Needs Attention"
        case completed = "Completed"
        case running = "Running"
    }

    private var notifications: [TaskNotification] {
        var result: [TaskNotification] = []

        for task in store.tasks {
            switch task.effectiveStatus {
            case .failed:
                result.append(TaskNotification(
                    task: task,
                    type: .failed,
                    message: "Task #\(task.numId) failed" + (task.error != nil ? ": \(task.error!.prefix(80))" : ""),
                    time: task.completedAt ?? task.startedAt ?? task.createdAt ?? Date()
                ))
            case .blocked:
                result.append(TaskNotification(
                    task: task,
                    type: .blocked,
                    message: "Task #\(task.numId) is blocked and needs help",
                    time: task.completedAt ?? task.startedAt ?? task.createdAt ?? Date()
                ))
            case .needsReview:
                result.append(TaskNotification(
                    task: task,
                    type: .needsReview,
                    message: "Task #\(task.numId) is done and waiting for review",
                    time: task.completedAt ?? task.createdAt ?? Date()
                ))
            case .done:
                result.append(TaskNotification(
                    task: task,
                    type: .completed,
                    message: "Task #\(task.numId) completed successfully",
                    time: task.completedAt ?? Date()
                ))
            case .running:
                result.append(TaskNotification(
                    task: task,
                    type: .running,
                    message: "Task #\(task.numId) is running on \(task.claimedBy ?? "a worker")",
                    time: task.startedAt ?? task.createdAt ?? Date()
                ))
            default:
                break
            }
        }

        result.sort { $0.time > $1.time }

        switch filter {
        case .all: return result
        case .attention: return result.filter { $0.type == .failed || $0.type == .blocked || $0.type == .needsReview }
        case .completed: return result.filter { $0.type == .completed }
        case .running: return result.filter { $0.type == .running }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                filterBar
                notificationList
            }
            .background(Color.commanderBg)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(NotifFilter.allCases, id: \.rawValue) { f in
                    let count: Int = {
                        switch f {
                        case .all: return notifications.count
                        case .attention: return store.tasks.filter { $0.status == .failed || $0.status == .blocked || $0.effectiveStatus == .needsReview }.count
                        case .completed: return store.tasks.filter { $0.status == .done && $0.reviewStatus != .needsReview }.count
                        case .running: return store.tasks.filter { $0.status == .running }.count
                        }
                    }()

                    FilterChip(
                        label: count > 0 ? "\(f.rawValue) (\(count))" : f.rawValue,
                        isSelected: filter == f,
                        color: f == .attention ? .commanderRed : .commanderOrange
                    ) {
                        withAnimation { filter = filter == f ? .all : f }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "No notifications",
                        subtitle: "Task updates will appear here"
                    )
                } else {
                    ForEach(notifications) { notif in
                        NavigationLink(destination: DevTaskDetailView(task: notif.task)) {
                            notificationCard(notif)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    private func notificationCard(_ notif: TaskNotification) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(notif.type.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: notif.type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(notif.type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notif.task.task)
                        .font(.commanderBody)
                        .foregroundColor(.commanderText)
                        .lineLimit(1)
                    Spacer()
                    Text(notif.time.commanderRelative)
                        .font(.commanderSmall)
                        .foregroundColor(.commanderMuted)
                }

                Text(notif.message)
                    .font(.commanderCaption)
                    .foregroundColor(.commanderSecondary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(notif.task.project)
                        .font(.commanderSmall)
                        .foregroundColor(.commanderOrange)
                    if let cost = notif.task.costString {
                        Text(cost)
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(.commanderMuted)
                .padding(.top, 8)
        }
        .padding(14)
        .background(Color.commanderSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    notif.type == .failed || notif.type == .blocked ? notif.type.color.opacity(0.3) : Color.commanderBorder,
                    lineWidth: notif.type == .failed || notif.type == .blocked ? 1 : 0.5
                )
        )
    }
}

// MARK: - Notification Model

struct TaskNotification: Identifiable {
    let id = UUID()
    let task: CommanderTask
    let type: NotificationType
    let message: String
    let time: Date
}

enum NotificationType {
    case failed
    case blocked
    case needsReview
    case completed
    case running

    var icon: String {
        switch self {
        case .failed: return "xmark.circle.fill"
        case .blocked: return "exclamationmark.triangle.fill"
        case .needsReview: return "eye.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .running: return "play.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .failed: return .commanderRed
        case .blocked: return .commanderOrange
        case .needsReview: return .commanderPurple
        case .completed: return .commanderGreen
        case .running: return .commanderAmber
        }
    }
}

#Preview {
    DevNotificationsView()
        .environmentObject(DataStore.shared)
}
