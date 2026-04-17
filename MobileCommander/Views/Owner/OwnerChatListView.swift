import SwiftUI
import FirebaseFirestore

struct OwnerChatListView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedTask: CommanderTask?

    private var tasksWithChat: [CommanderTask] {
        store.tasks.filter { $0.status == .running || $0.status == .done || $0.status == .failed }
            .sorted { ($0.startedAt ?? $0.createdAt ?? .distantPast) > ($1.startedAt ?? $1.createdAt ?? .distantPast) }
    }

    private var runningTasks: [CommanderTask] {
        tasksWithChat.filter { $0.status == .running }
    }

    private var pastTasks: [CommanderTask] {
        tasksWithChat.filter { $0.status != .running }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if tasksWithChat.isEmpty {
                        EmptyStateView(
                            icon: "bubble.left.and.bubble.right",
                            title: "No conversations yet",
                            subtitle: "Messages will appear here when tasks start running."
                        )
                    } else {
                        if !runningTasks.isEmpty {
                            activeSection
                        }
                        if !pastTasks.isEmpty {
                            pastSection
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color.commanderBg)
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Active Conversations

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                LiveDot()
                Text("Active Conversations")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderAmber)
            }

            ForEach(runningTasks) { task in
                NavigationLink(destination: OwnerTaskDetailView(task: task)) {
                    chatTaskRow(task, isActive: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Past Conversations

    private var pastSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Previous Tasks")
                .font(.commanderCaptionMedium)
                .foregroundColor(.commanderSecondary)

            ForEach(pastTasks.prefix(20)) { task in
                NavigationLink(destination: OwnerTaskDetailView(task: task)) {
                    chatTaskRow(task, isActive: false)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Chat Task Row

    private func chatTaskRow(_ task: CommanderTask, isActive: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.commanderAmber.opacity(0.15) : Color.commanderSurface)
                    .frame(width: 40, height: 40)
                Image(systemName: isActive ? "bubble.left.and.bubble.right.fill" : "bubble.left.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isActive ? .commanderAmber : .commanderMuted)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.task)
                        .font(.commanderBody)
                        .foregroundColor(.commanderText)
                        .lineLimit(1)
                    Spacer()
                    if isActive {
                        Text("Active")
                            .font(.commanderSmall)
                            .foregroundColor(.commanderAmber)
                    } else if let time = task.completedAt ?? task.startedAt {
                        Text(time.commanderRelative)
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                    }
                }

                HStack(spacing: 6) {
                    Text(task.project)
                        .font(.commanderSmall)
                        .foregroundColor(.commanderOrange)
                    StatusBadge(status: task.effectiveStatus)
                }

                if isActive {
                    Text("Tap to send a message while it's working")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderMuted)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(.commanderMuted)
        }
        .padding(12)
        .background(Color.commanderSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.commanderAmber.opacity(0.3) : Color.commanderBorder, lineWidth: isActive ? 1 : 0.5)
        )
    }
}

#Preview {
    OwnerChatListView()
        .environmentObject(DataStore.shared)
}
