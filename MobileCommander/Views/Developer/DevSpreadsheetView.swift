import SwiftUI

struct DevSpreadsheetView: View {
    @EnvironmentObject var store: DataStore
    @State private var sortKey: SortKey = .numId
    @State private var sortAscending = false
    @State private var statusFilter: TaskStatus?
    @State private var selectedTaskId: String?

    enum SortKey: String, CaseIterable {
        case numId = "#"
        case status = "Status"
        case task = "Task"
        case project = "Project"
        case cost = "Cost"
        case duration = "Duration"
        case priority = "Priority"
    }

    private var sortedTasks: [CommanderTask] {
        var result = store.tasks
        if let filter = statusFilter {
            result = result.filter { $0.effectiveStatus == filter }
        }
        result.sort { a, b in
            let cmp: Bool
            switch sortKey {
            case .numId: cmp = a.numId < b.numId
            case .status: cmp = a.effectiveStatus.rawValue < b.effectiveStatus.rawValue
            case .task: cmp = a.task.lowercased() < b.task.lowercased()
            case .project: cmp = a.project.lowercased() < b.project.lowercased()
            case .cost: cmp = (a.costUsd ?? 0) < (b.costUsd ?? 0)
            case .duration: cmp = (a.durationMs ?? 0) < (b.durationMs ?? 0)
            case .priority: cmp = a.priority < b.priority
            }
            return sortAscending ? cmp : !cmp
        }
        return result
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                filterBar
                tableHeader
                tableBody
            }
            .background(Color.commanderBg)
            .navigationTitle("Spreadsheet")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterChip(label: "All (\(store.tasks.count))", isSelected: statusFilter == nil) {
                    withAnimation { statusFilter = nil }
                }
                ForEach(TaskStatus.allCases, id: \.rawValue) { status in
                    let count = store.taskCounts[status] ?? 0
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
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Table Header

    private var tableHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                columnHeader("#", key: .numId, width: 44)
                columnHeader("Status", key: .status, width: 80)
                columnHeader("Task", key: .task, width: 200)
                columnHeader("Project", key: .project, width: 100)
                columnHeader("P", key: .priority, width: 36)
                columnHeader("Cost", key: .cost, width: 70)
                columnHeader("Duration", key: .duration, width: 80)
            }
            .padding(.horizontal, 16)
        }
        .background(Color.commanderSurface)
        .overlay(
            Rectangle()
                .fill(Color.commanderBorder)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private func columnHeader(_ title: String, key: SortKey, width: CGFloat) -> some View {
        Button {
            if sortKey == key {
                sortAscending.toggle()
            } else {
                sortKey = key
                sortAscending = true
            }
        } label: {
            HStack(spacing: 2) {
                Text(title)
                    .font(.commanderSmall)
                    .foregroundColor(sortKey == key ? .commanderOrange : .commanderMuted)
                if sortKey == key {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                        .foregroundColor(.commanderOrange)
                }
            }
            .frame(width: width, alignment: .leading)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Table Body

    private var tableBody: some View {
        ScrollView {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    if sortedTasks.isEmpty {
                        EmptyStateView(
                            icon: "tablecells",
                            title: "No tasks",
                            subtitle: "Tasks will appear here"
                        )
                    } else {
                        ForEach(sortedTasks) { task in
                            NavigationLink(destination: DevTaskDetailView(task: task)) {
                                tableRow(task)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func tableRow(_ task: CommanderTask) -> some View {
        HStack(spacing: 0) {
            Text("\(task.numId)")
                .font(.commanderMonoSmall)
                .foregroundColor(.commanderMuted)
                .frame(width: 44, alignment: .leading)

            HStack(spacing: 4) {
                Circle()
                    .fill(task.effectiveStatus.color)
                    .frame(width: 6, height: 6)
                Text(task.effectiveStatus.displayName)
                    .font(.commanderSmall)
                    .foregroundColor(task.effectiveStatus.color)
                    .lineLimit(1)
            }
            .frame(width: 80, alignment: .leading)

            Text(task.task)
                .font(.commanderCaption)
                .foregroundColor(.commanderText)
                .lineLimit(1)
                .frame(width: 200, alignment: .leading)

            Text(task.project)
                .font(.commanderSmall)
                .foregroundColor(.commanderOrange)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)

            Text("\(task.priority)")
                .font(.commanderMonoSmall)
                .foregroundColor(.commanderSecondary)
                .frame(width: 36, alignment: .leading)

            Text(task.costString ?? "—")
                .font(.commanderMonoSmall)
                .foregroundColor(.commanderSecondary)
                .frame(width: 70, alignment: .leading)

            Text(task.durationString ?? "—")
                .font(.commanderMonoSmall)
                .foregroundColor(.commanderSecondary)
                .frame(width: 80, alignment: .leading)
        }
        .padding(.vertical, 10)
        .background(Color.commanderBg)
        .overlay(
            Rectangle()
                .fill(Color.commanderBorder.opacity(0.3))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

#Preview {
    DevSpreadsheetView()
        .environmentObject(DataStore.shared)
}
