import SwiftUI

struct DevDashboardView: View {
    @EnvironmentObject var store: DataStore
    @State private var statusFilter: TaskStatus?
    @State private var showCreateTask = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summaryHeader
                    statsGrid
                    overallProgress
                    projectProgress
                    workerFleet
                    recentTasks
                    activityLink
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color.commanderBg)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.commanderOrange)
                    }
                }
            }
            .sheet(isPresented: $showCreateTask) {
                DevTaskCreateView()
            }
            .refreshable {
                await store.refresh()
            }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    LiveDot()
                    Text("Live updates")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderSecondary)
                }

                let counts = store.taskCounts
                Text("\(store.tasks.count) tasks · \(counts[.running] ?? 0) running · \(counts[.done] ?? 0) done")
                    .font(.commanderCaption)
                    .foregroundColor(.commanderSecondary)
            }
            Spacer()
            if store.totalCost > 0 {
                Text(String(format: "$%.2f", store.totalCost))
                    .font(.commanderSubhead)
                    .foregroundColor(.commanderOrange)
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        let counts = store.taskCounts
        let stats: [(String, Int, Color, TaskStatus?)] = [
            ("Total", store.tasks.count, .commanderText, nil),
            ("Review", counts[.needsReview] ?? 0, .commanderPurple, .needsReview),
            ("Running", counts[.running] ?? 0, .commanderAmber, .running),
            ("Pending", (counts[.pending] ?? 0) + (counts[.claimed] ?? 0), .commanderSecondary, .pending),
            ("Done", counts[.done] ?? 0, .commanderGreen, .done),
            ("Failed", counts[.failed] ?? 0, .commanderRed, .failed),
            ("Blocked", counts[.blocked] ?? 0, .commanderOrange, .blocked),
        ]

        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
        ], spacing: 8) {
            ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                StatCard(
                    label: stat.0,
                    value: stat.1,
                    color: stat.2,
                    isSelected: statusFilter == stat.3 || (statusFilter == nil && stat.3 == nil)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        statusFilter = stat.3
                    }
                }
            }
        }
    }

    // MARK: - Overall Progress

    private var overallProgress: some View {
        let done = store.taskCounts[.done] ?? 0
        return CommanderProgressBar(done: done, total: store.tasks.count, label: "Overall Progress")
    }

    // MARK: - Project Progress

    @ViewBuilder
    private var projectProgress: some View {
        let projects = store.projectNames
        if projects.count > 1 {
            VStack(alignment: .leading, spacing: 8) {
                Text("By Project")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderSecondary)

                ForEach(projects, id: \.self) { project in
                    let progress = store.projectProgress(project)
                    CommanderProgressBar(done: progress.done, total: progress.total, label: project)
                }
            }
        }
    }

    // MARK: - Worker Fleet

    @ViewBuilder
    private var workerFleet: some View {
        if !store.workers.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Worker Fleet")
                        .font(.commanderCaptionMedium)
                        .foregroundColor(.commanderSecondary)
                    Spacer()
                    NavigationLink(destination: DevWorkersView()) {
                        Text("View all")
                            .font(.commanderSmall)
                            .foregroundColor(.commanderOrange)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(store.workers) { worker in
                            workerCard(worker)
                        }
                    }
                }
            }
        }
    }

    private func workerCard(_ worker: CommanderWorker) -> some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: worker.status.icon)
                        .font(.system(size: 10))
                        .foregroundColor(worker.status.color)
                    Text(worker.hostname)
                        .font(.commanderCaptionMedium)
                        .foregroundColor(.commanderText)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("Active")
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                        Text("\(worker.activeTaskCount)")
                            .font(.commanderSubhead)
                            .foregroundColor(.commanderText)
                    }
                    VStack(alignment: .leading) {
                        Text("Done")
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                        Text("\(worker.completedTasks)")
                            .font(.commanderSubhead)
                            .foregroundColor(.commanderGreen)
                    }
                }

                if worker.isRateLimited {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                        Text("Rate limited")
                            .font(.commanderSmall)
                    }
                    .foregroundColor(.commanderAmber)
                }
            }
        }
        .frame(width: 150)
    }

    // MARK: - Recent Tasks

    private var recentTasks: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Tasks")
                .font(.commanderCaptionMedium)
                .foregroundColor(.commanderSecondary)

            let filtered = filteredTasks
            if filtered.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "No tasks",
                    subtitle: "Create a task to get started"
                )
            } else {
                ForEach(filtered.prefix(10)) { task in
                    NavigationLink(destination: DevTaskDetailView(task: task)) {
                        TaskRow(task: task)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Activity Link

    private var activityLink: some View {
        NavigationLink(destination: DevActivityView()) {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14))
                    .foregroundColor(.commanderOrange)
                Text("View Activity Log")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderText)
                Spacer()
                Text("\(store.activities.count)")
                    .font(.commanderSmall)
                    .foregroundColor(.commanderSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(.commanderMuted)
            }
            .padding(14)
            .background(Color.commanderSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.commanderBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var filteredTasks: [CommanderTask] {
        guard let filter = statusFilter else { return store.tasks }
        return store.tasks.filter { $0.effectiveStatus == filter }
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: CommanderTask

    var body: some View {
        CommanderCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("#\(task.numId)")
                            .font(.commanderMonoSmall)
                            .foregroundColor(.commanderMuted)
                        Text(task.project)
                            .font(.commanderSmall)
                            .foregroundColor(.commanderOrange)
                    }

                    Text(task.task)
                        .font(.commanderBody)
                        .foregroundColor(.commanderText)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        StatusBadge(status: task.effectiveStatus)

                        if let cost = task.costString {
                            Text(cost)
                                .font(.commanderSmall)
                                .foregroundColor(.commanderSecondary)
                        }

                        if let duration = task.durationString {
                            Text(duration)
                                .font(.commanderSmall)
                                .foregroundColor(.commanderSecondary)
                        }

                        if let created = task.createdAt {
                            Text(created.commanderRelative)
                                .font(.commanderSmall)
                                .foregroundColor(.commanderMuted)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.commanderMuted)
            }
        }
    }
}

#Preview {
    DevDashboardView()
        .environmentObject(DataStore.shared)
}
