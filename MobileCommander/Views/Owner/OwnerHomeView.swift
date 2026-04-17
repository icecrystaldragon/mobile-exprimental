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
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var needsAttention: [CommanderTask] {
        store.tasks.filter { $0.status == .failed || $0.status == .blocked || $0.effectiveStatus == .needsReview }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusStrip
                    activeSection
                    attentionSection
                    pendingSection
                    recentlyCompleted
                    todayTimeline
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color.commanderBg)
            .refreshable {
                await store.refresh()
            }
            .safeAreaInset(edge: .top) {
                ownerHeader
            }
        }
    }

    // MARK: - Header (palmr-inspired sticky header)

    private var ownerHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.commanderOrange.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.commanderOrange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Commander")
                        .font(.commanderHeadline)
                        .foregroundColor(.commanderText)
                    HStack(spacing: 6) {
                        LiveDot()
                        Text(statusMessage)
                            .font(.commanderCaption)
                            .foregroundColor(.commanderSecondary)
                    }
                }

                Spacer()

                if store.totalCost > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "$%.2f", store.totalCost))
                            .font(.commanderCaptionMedium)
                            .foregroundColor(.commanderOrange)
                        Text("total cost")
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(Color.commanderBorder)
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
            return "\(running) task\(running == 1 ? " is" : "s are") being worked on"
        }
        if !completedTasks.isEmpty {
            return "Everything's up to date"
        }
        return "No tasks yet — create one to get started"
    }

    // MARK: - Status Strip (palmr pillar-strip inspired)

    private var statusStrip: some View {
        HStack(spacing: 8) {
            statusPill(
                icon: "play.circle.fill",
                label: "Active",
                value: activeTasks.count,
                color: .commanderAmber
            )
            statusPill(
                icon: "clock",
                label: "Queued",
                value: pendingTasks.count,
                color: .commanderSecondary
            )
            statusPill(
                icon: "checkmark.circle.fill",
                label: "Done",
                value: completedTasks.count,
                color: .commanderGreen
            )
            if !needsAttention.isEmpty {
                statusPill(
                    icon: "exclamationmark.triangle.fill",
                    label: "Attention",
                    value: needsAttention.count,
                    color: .commanderRed
                )
            }
        }
    }

    private func statusPill(icon: String, label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
            Text("\(value)")
                .font(.commanderCaptionMedium)
                .foregroundColor(.commanderText)
            Text(label)
                .font(.commanderSmall)
                .foregroundColor(.commanderMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.commanderSurface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.commanderBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Active Tasks (palmr RunningTaskCard inspired)

    @ViewBuilder
    private var activeSection: some View {
        if !activeTasks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Currently Working On")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderSecondary)

                ForEach(activeTasks) { task in
                    NavigationLink(destination: OwnerTaskDetailView(task: task)) {
                        runningTaskCard(task)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func runningTaskCard(_ task: CommanderTask) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    LiveDot()
                    Text("NOW RUNNING")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderAmber)
                }
                Spacer()
                if let duration = task.durationString {
                    Text(duration)
                        .font(.commanderMonoSmall)
                        .foregroundColor(.commanderMuted)
                }
            }

            Text(task.task)
                .font(.commanderSubhead)
                .foregroundColor(.commanderText)
                .lineLimit(2)

            HStack(spacing: 8) {
                Label(task.project, systemImage: "folder.fill")
                    .font(.commanderSmall)
                    .foregroundColor(.commanderOrange)

                if let worker = task.claimedBy {
                    Label(worker, systemImage: "server.rack")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderMuted)
                }
            }

            if let cost = task.costUsd, cost > 0 {
                HStack {
                    Text("Cost so far")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderMuted)
                    Spacer()
                    Text(String(format: "$%.2f", cost))
                        .font(.commanderMonoSmall)
                        .foregroundColor(.commanderSecondary)
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.commanderOrange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Needs Attention (urgent banner inspired by palmr)

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
                    Spacer()
                    Text("\(needsAttention.count)")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderRed)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.commanderRedDim)
                        .cornerRadius(10)
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
            VStack(alignment: .leading, spacing: 10) {
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

                HStack(spacing: 8) {
                    if task.effectiveStatus == .needsReview {
                        QuickActionButton(title: "Looks Good", icon: "hand.thumbsup.fill", color: .commanderGreen, isPrimary: true) {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            Task { try? await store.approveTask(task) }
                        }
                        QuickActionButton(title: "Needs Work", icon: "arrow.uturn.backward", color: .commanderAmber) {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            Task { try? await store.requestChanges(task) }
                        }
                    }
                    if task.status == .failed || task.status == .blocked {
                        QuickActionButton(title: "Try Again", icon: "arrow.clockwise", color: .commanderOrange, isPrimary: true) {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            Task { try? await store.retryTask(task) }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pending Queue

    @ViewBuilder
    private var pendingSection: some View {
        if !pendingTasks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Up Next")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderSecondary)

                ForEach(pendingTasks) { task in
                    NavigationLink(destination: OwnerTaskDetailView(task: task)) {
                        HStack(spacing: 10) {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                                .foregroundColor(.commanderMuted)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.task)
                                    .font(.commanderBody)
                                    .foregroundColor(.commanderText)
                                    .lineLimit(1)
                                HStack(spacing: 6) {
                                    Text(task.project)
                                        .font(.commanderSmall)
                                        .foregroundColor(.commanderOrange)
                                    Text("Priority \(task.priority)")
                                        .font(.commanderSmall)
                                        .foregroundColor(.commanderMuted)
                                }
                            }

                            Spacer()

                            Text("Queued")
                                .font(.commanderSmall)
                                .foregroundColor(.commanderSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.commanderSurface)
                                .cornerRadius(6)
                        }
                        .padding(12)
                        .background(Color.commanderSurface)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.commanderBorder, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
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
                    if let cost = task.costString {
                        Text(cost)
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                    }
                    if let time = task.completedAt {
                        Text(time.commanderRelative)
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                    }
                }
            }

            Spacer()

            if task.effectiveStatus == .needsReview {
                Image(systemName: "eye.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.commanderPurple)
            }

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

    // MARK: - Today Timeline (palmr-inspired)

    @ViewBuilder
    private var todayTimeline: some View {
        let todayActivities = store.activities.filter { event in
            guard let ts = event.timestamp else { return false }
            return Calendar.current.isDateInToday(ts)
        }.prefix(8)

        if !todayActivities.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Today")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderSecondary)

                ForEach(Array(todayActivities.enumerated()), id: \.element.id) { index, event in
                    HStack(alignment: .top, spacing: 12) {
                        TimelineDot(
                            color: event.color,
                            isLast: index == todayActivities.count - 1
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(friendlyTimelineAction(event))
                                    .font(.commanderCaption)
                                    .foregroundColor(.commanderText)
                                Spacer()
                                if let ts = event.timestamp {
                                    Text(ts.commanderTimeString)
                                        .font(.commanderSmall)
                                        .foregroundColor(.commanderMuted)
                                }
                            }
                            if let detail = event.details["task_name"] ?? event.details["project"] {
                                Text(detail)
                                    .font(.commanderSmall)
                                    .foregroundColor(.commanderSecondary)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
        }
    }

    private func friendlyTimelineAction(_ event: ActivityEvent) -> String {
        switch event.action {
        case "task_created": return "New task submitted"
        case "task_retried": return "Task retried"
        case "chat_message_sent": return "Message sent"
        case "task_status_changed":
            if let status = event.details["new_status"] {
                switch status {
                case "done": return "Task completed"
                case "failed": return "Task failed"
                case "running": return "Task started"
                default: return "Task updated"
                }
            }
            return "Task updated"
        case "task_deleted": return "Task removed"
        case "task_approved": return "Task approved"
        case "task_changes_requested": return "Changes requested"
        default: return event.displayAction
        }
    }
}

#Preview {
    OwnerHomeView()
        .environmentObject(DataStore.shared)
}
