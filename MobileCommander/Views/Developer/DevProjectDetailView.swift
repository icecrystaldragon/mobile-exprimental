import SwiftUI

struct DevProjectDetailView: View {
    let project: String
    @EnvironmentObject var store: DataStore
    @State private var statusFilter: TaskStatus?
    @State private var showCreateTask = false

    private var projectTasks: [CommanderTask] {
        var result = store.tasks(for: project)
        if let filter = statusFilter {
            result = result.filter { $0.effectiveStatus == filter }
        }
        return result
    }

    private var progress: (done: Int, total: Int) {
        store.projectProgress(project)
    }

    private var projectCost: Double {
        store.tasks(for: project).reduce(0) { $0 + ($1.costUsd ?? 0) }
    }

    private var statusCounts: [TaskStatus: Int] {
        var counts: [TaskStatus: Int] = [:]
        for task in store.tasks(for: project) {
            counts[task.effectiveStatus, default: 0] += 1
        }
        return counts
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                progressSection
                statsRow
                filterBar
                taskList
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.commanderBg)
        .navigationTitle(project)
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
    }

    // MARK: - Progress

    private var progressSection: some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project)
                            .font(.commanderHeadline)
                            .foregroundColor(.commanderText)
                        Text("\(progress.total) tasks · \(progress.done) completed")
                            .font(.commanderCaption)
                            .foregroundColor(.commanderSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "$%.2f", projectCost))
                            .font(.commanderSubhead)
                            .foregroundColor(.commanderOrange)
                        Text("total cost")
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                    }
                }

                CommanderProgressBar(done: progress.done, total: progress.total, label: "Completion")
            }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        let stats: [(String, Int, Color, TaskStatus)] = [
            ("Running", statusCounts[.running] ?? 0, .commanderAmber, .running),
            ("Pending", (statusCounts[.pending] ?? 0) + (statusCounts[.claimed] ?? 0), .commanderSecondary, .pending),
            ("Review", statusCounts[.needsReview] ?? 0, .commanderPurple, .needsReview),
            ("Failed", statusCounts[.failed] ?? 0, .commanderRed, .failed),
        ]

        return HStack(spacing: 8) {
            ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                StatCard(
                    label: stat.0,
                    value: stat.1,
                    color: stat.2,
                    isSelected: statusFilter == stat.3
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        statusFilter = statusFilter == stat.3 ? nil : stat.3
                    }
                }
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterChip(label: "All (\(store.tasks(for: project).count))", isSelected: statusFilter == nil) {
                    withAnimation { statusFilter = nil }
                }
                ForEach(TaskStatus.allCases, id: \.rawValue) { status in
                    let count = statusCounts[status] ?? 0
                    if count > 0 {
                        FilterChip(
                            label: "\(status.displayName) (\(count))",
                            isSelected: statusFilter == status,
                            color: status.color
                        ) {
                            withAnimation { statusFilter = statusFilter == status ? nil : status }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        LazyVStack(spacing: 8) {
            if projectTasks.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "No matching tasks",
                    subtitle: statusFilter != nil ? "Try a different filter" : "Create a task to get started"
                )
            } else {
                ForEach(projectTasks) { task in
                    NavigationLink(destination: DevTaskDetailView(task: task)) {
                        TaskRow(task: task)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if task.status == .failed || task.status == .blocked {
                            Button {
                                Task { try? await store.retryTask(task) }
                            } label: {
                                Label("Retry", systemImage: "arrow.clockwise")
                            }
                        }
                        if task.effectiveStatus == .needsReview {
                            Button {
                                Task { try? await store.approveTask(task) }
                            } label: {
                                Label("Approve", systemImage: "checkmark.seal")
                            }
                        }
                        Button(role: .destructive) {
                            Task { try? await store.deleteTask(task) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        DevProjectDetailView(project: "everbnb")
            .environmentObject(DataStore.shared)
    }
}
