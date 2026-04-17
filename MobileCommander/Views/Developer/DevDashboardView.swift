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
        if !projects.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("By Project")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderSecondary)

                ForEach(projects, id: \.self) { project in
                    NavigationLink(destination: DevProjectDetailView(project: project)) {
                        projectCard(project)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func projectCard(_ project: String) -> some View {
        let progress = store.projectProgress(project)
        let cost = store.tasks(for: project).reduce(0) { $0 + ($1.costUsd ?? 0) }
        let running = store.tasks(for: project).filter { $0.status == .running }.count

        return CommanderCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.commanderOrange)
                        Text(project)
                            .font(.commanderCaptionMedium)
                            .foregroundColor(.commanderText)
                    }
                    Spacer()
                    if running > 0 {
                        HStack(spacing: 4) {
                            LiveDot()
                            Text("\(running) running")
                                .font(.commanderSmall)
                                .foregroundColor(.commanderAmber)
                        }
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.commanderMuted)
                }

                CommanderProgressBar(done: progress.done, total: progress.total, label: "\(progress.done)/\(progress.total) tasks")

                if cost > 0 {
                    Text(String(format: "$%.2f spent", cost))
                        .font(.commanderSmall)
                        .foregroundColor(.commanderMuted)
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

    // MARK: - Quick Links

    private var activityLink: some View {
        VStack(spacing: 8) {
            dashboardLink(
                icon: "chart.bar.doc.horizontal",
                label: "Quota & Costs",
                subtitle: String(format: "$%.2f total", store.totalCost),
                destination: AnyView(DevQuotaView())
            )
            dashboardLink(
                icon: "tablecells",
                label: "Spreadsheet View",
                subtitle: "\(store.tasks.count) tasks",
                destination: AnyView(DevSpreadsheetView())
            )
            dashboardLink(
                icon: "clock.arrow.circlepath",
                label: "Activity Log",
                subtitle: "\(store.activities.count) events",
                destination: AnyView(DevActivityView())
            )
        }
    }

    private func dashboardLink(icon: String, label: String, subtitle: String, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.commanderOrange)
                Text(label)
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderText)
                Spacer()
                Text(subtitle)
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
