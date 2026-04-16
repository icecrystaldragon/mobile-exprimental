import SwiftUI

struct OwnerHomeView: View {
    @EnvironmentObject var store: DataStore

    private var activeTasks: [CommanderTask] {
        store.tasks.filter { $0.status == .running || $0.status == .claimed }
    }

    private var pendingTasks: [CommanderTask] {
        store.tasks.filter { $0.status == .pending }
    }

    private var completedTasks: [CommanderTask] {
        store.tasks.filter { $0.status == .done }
    }

    private var needsAttention: [CommanderTask] {
        store.tasks.filter { $0.status == .failed || $0.status == .blocked || $0.effectiveStatus == .needsReview }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusCards
                    activeSection
                    attentionSection
                    recentlyCompleted
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color.commanderBg)
            .safeAreaInset(edge: .top) {
                ownerHeader
            }
        }
    }

    // MARK: - Header

    private var ownerHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.commanderOrange)
                        Text("Commander")
                            .font(.commanderHeadline)
                            .foregroundColor(.commanderText)
                    }

                    HStack(spacing: 6) {
                        LiveDot()
                        Text(statusMessage)
                            .font(.commanderCaption)
                            .foregroundColor(.commanderSecondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.commanderSurface)
    }

    private var statusMessage: String {
        let running = activeTasks.count
        let attention = needsAttention.count
        if attention > 0 {
            return "\(attention) item\(attention == 1 ? "" : "s") need\(attention == 1 ? "s" : "") your attention"
        }
        if running > 0 {
            return "\(running) task\(running == 1 ? "" : "s") running"
        }
        return "All quiet — no active tasks"
    }

    // MARK: - Status Cards

    private var statusCards: some View {
        HStack(spacing: 10) {
            ownerStatCard(
                icon: "play.circle.fill",
                label: "Running",
                value: activeTasks.count,
                color: .commanderAmber
            )
            ownerStatCard(
                icon: "checkmark.circle.fill",
                label: "Completed",
                value: completedTasks.count,
                color: .commanderGreen
            )
            ownerStatCard(
                icon: "exclamationmark.circle.fill",
                label: "Attention",
                value: needsAttention.count,
                color: needsAttention.isEmpty ? .commanderSecondary : .commanderRed
            )
        }
    }

    private func ownerStatCard(icon: String, label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            Text("\(value)")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.commanderText)
            Text(label)
                .font(.commanderSmall)
                .foregroundColor(.commanderSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.commanderSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.commanderBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Active Tasks

    @ViewBuilder
    private var activeSection: some View {
        if !activeTasks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Currently Working On")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderSecondary)

                ForEach(activeTasks) { task in
                    NavigationLink(destination: OwnerTaskDetailView(task: task)) {
                        activeTaskCard(task)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func activeTaskCard(_ task: CommanderTask) -> some View {
        CommanderAccentCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    StatusBadge(status: .running)
                    Spacer()
                    if task.status == .running {
                        LiveDot()
                    }
                }

                Text(task.task)
                    .font(.commanderSubhead)
                    .foregroundColor(.commanderText)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(task.project, systemImage: "folder")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderOrange)

                    if let duration = task.durationString {
                        Label(duration, systemImage: "clock")
                            .font(.commanderSmall)
                            .foregroundColor(.commanderSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Needs Attention

    @ViewBuilder
    private var attentionSection: some View {
        if !needsAttention.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.commanderRed)
                    Text("Needs Your Attention")
                        .font(.commanderCaptionMedium)
                        .foregroundColor(.commanderRed)
                }

                ForEach(needsAttention) { task in
                    NavigationLink(destination: OwnerTaskDetailView(task: task)) {
                        attentionCard(task)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func attentionCard(_ task: CommanderTask) -> some View {
        CommanderCard {
            HStack(spacing: 12) {
                Image(systemName: task.effectiveStatus.icon)
                    .font(.system(size: 20))
                    .foregroundColor(task.effectiveStatus.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.task)
                        .font(.commanderBody)
                        .foregroundColor(.commanderText)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        StatusBadge(status: task.effectiveStatus)
                        Text(task.project)
                            .font(.commanderSmall)
                            .foregroundColor(.commanderSecondary)
                    }

                    if let error = task.error {
                        Text(error)
                            .font(.commanderSmall)
                            .foregroundColor(.commanderRed)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.commanderMuted)
            }
        }
    }

    // MARK: - Recently Completed

    @ViewBuilder
    private var recentlyCompleted: some View {
        if !completedTasks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recently Completed")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderSecondary)

                ForEach(completedTasks.prefix(5)) { task in
                    NavigationLink(destination: OwnerTaskDetailView(task: task)) {
                        completedRow(task)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func completedRow(_ task: CommanderTask) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.commanderGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.task)
                    .font(.commanderBody)
                    .foregroundColor(.commanderText)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(task.project)
                        .font(.commanderSmall)
                        .foregroundColor(.commanderOrange)
                    if let time = task.completedAt {
                        Text(time.commanderRelative)
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(.commanderMuted)
        }
        .padding(12)
        .background(Color.commanderSurface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.commanderBorder, lineWidth: 0.5)
        )
    }
}

#Preview {
    OwnerHomeView()
        .environmentObject(DataStore.shared)
}
