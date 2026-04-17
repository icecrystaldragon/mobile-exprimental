import SwiftUI

struct DevTaskListView: View {
    @EnvironmentObject var store: DataStore
    @State private var statusFilter: TaskStatus?
    @State private var projectFilter: String?
    @State private var searchText = ""
    @State private var showCreateTask = false
    @State private var showDeleteConfirm = false
    @State private var taskToDelete: CommanderTask?

    private var filteredTasks: [CommanderTask] {
        var result = store.tasks

        if let status = statusFilter {
            result = result.filter { $0.effectiveStatus == status }
        }

        if let project = projectFilter {
            result = result.filter { $0.project == project }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.task.lowercased().contains(query) ||
                $0.project.lowercased().contains(query) ||
                $0.description.lowercased().contains(query) ||
                "\($0.numId)".contains(query)
            }
        }

        return result
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                filterBar
                taskList
            }
            .background(Color.commanderBg)
            .navigationTitle("Tasks")
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
            .searchable(text: $searchText, prompt: "Search tasks...")
            .refreshable {
                await store.refresh()
            }
            .alert("Delete Task?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    if let task = taskToDelete {
                        let impact = UINotificationFeedbackGenerator()
                        impact.notificationOccurred(.warning)
                        Task { try? await store.deleteTask(task) }
                    }
                    taskToDelete = nil
                }
                Button("Cancel", role: .cancel) { taskToDelete = nil }
            } message: {
                if let task = taskToDelete {
                    Text("Permanently delete \"\(task.task)\"? This cannot be undone.")
                }
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 8) {
            // Status filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    FilterChip(label: "All", isSelected: statusFilter == nil) {
                        withAnimation { statusFilter = nil }
                    }
                    ForEach(TaskStatus.allCases, id: \.rawValue) { status in
                        let count = store.taskCounts[status] ?? 0
                        if count > 0 || status == .running || status == .pending || status == .done {
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
                .padding(.horizontal, 16)
            }

            // Project filters
            if store.projectNames.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        FilterChip(label: "All Projects", isSelected: projectFilter == nil) {
                            withAnimation { projectFilter = nil }
                        }
                        ForEach(store.projectNames, id: \.self) { project in
                            FilterChip(label: project, isSelected: projectFilter == project) {
                                withAnimation { projectFilter = projectFilter == project ? nil : project }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Task List

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if filteredTasks.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No matching tasks",
                        subtitle: "Try adjusting your filters"
                    )
                } else {
                    ForEach(filteredTasks) { task in
                        NavigationLink(destination: DevTaskDetailView(task: task)) {
                            TaskRow(task: task)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if task.status == .failed || task.status == .blocked {
                                Button {
                                    retryTask(task)
                                } label: {
                                    Label("Retry", systemImage: "arrow.clockwise")
                                }
                            }

                            if task.effectiveStatus == .needsReview {
                                Button {
                                    Task {
                                        let impact = UINotificationFeedbackGenerator()
                                        impact.notificationOccurred(.success)
                                        try? await store.approveTask(task)
                                    }
                                } label: {
                                    Label("Approve", systemImage: "checkmark.seal")
                                }
                            }

                            Button(role: .destructive) {
                                taskToDelete = task
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    private func retryTask(_ task: CommanderTask) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        Task {
            try? await store.retryTask(task)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = .commanderOrange
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.commanderSmall)
                .foregroundColor(isSelected ? .white : .commanderSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? color.opacity(0.3) : Color.commanderSurface)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? color.opacity(0.5) : Color.commanderBorder, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DevTaskListView()
        .environmentObject(DataStore.shared)
}
