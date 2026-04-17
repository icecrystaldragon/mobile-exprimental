import SwiftUI

struct DevReportsView: View {
    @EnvironmentObject var store: DataStore
    @State private var timeRange: TimeRange = .all

    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "7 Days"
        case month = "30 Days"
        case all = "All Time"

        var cutoff: Date {
            switch self {
            case .today: return Calendar.current.startOfDay(for: Date())
            case .week: return Date().addingTimeInterval(-7 * 86400)
            case .month: return Date().addingTimeInterval(-30 * 86400)
            case .all: return .distantPast
            }
        }
    }

    private var filteredTasks: [CommanderTask] {
        store.tasks.filter { task in
            guard let created = task.createdAt else { return timeRange == .all }
            return created >= timeRange.cutoff
        }
    }

    private var totalCost: Double {
        filteredTasks.reduce(0) { $0 + ($1.costUsd ?? 0) }
    }

    private var avgCost: Double {
        let tasksWithCost = filteredTasks.filter { ($0.costUsd ?? 0) > 0 }
        guard !tasksWithCost.isEmpty else { return 0 }
        return tasksWithCost.reduce(0) { $0 + ($1.costUsd ?? 0) } / Double(tasksWithCost.count)
    }

    private var avgDurationMinutes: Double {
        let tasksWithDuration = filteredTasks.filter { ($0.durationMs ?? 0) > 0 }
        guard !tasksWithDuration.isEmpty else { return 0 }
        let totalMs = tasksWithDuration.reduce(0) { $0 + Double($1.durationMs ?? 0) }
        return (totalMs / Double(tasksWithDuration.count)) / 60000
    }

    private var successRate: Double {
        let finished = filteredTasks.filter { $0.status == .done || $0.status == .failed }
        guard !finished.isEmpty else { return 0 }
        let succeeded = finished.filter { $0.status == .done }.count
        return Double(succeeded) / Double(finished.count)
    }

    private var projectBreakdown: [(String, Int, Double)] {
        var result: [(String, Int, Double)] = []
        for project in Set(filteredTasks.map { $0.project }) {
            let tasks = filteredTasks.filter { $0.project == project }
            let cost = tasks.reduce(0) { $0 + ($1.costUsd ?? 0) }
            result.append((project, tasks.count, cost))
        }
        return result.sorted { $0.2 > $1.2 }
    }

    private var statusBreakdown: [(TaskStatus, Int)] {
        var counts: [TaskStatus: Int] = [:]
        for task in filteredTasks {
            counts[task.effectiveStatus, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
    }

    private var workerBreakdown: [(String, Int, Double)] {
        var result: [(String, Int, Double)] = []
        for worker in Set(filteredTasks.compactMap { $0.claimedBy }) {
            let tasks = filteredTasks.filter { $0.claimedBy == worker }
            let cost = tasks.reduce(0) { $0 + ($1.costUsd ?? 0) }
            result.append((worker, tasks.count, cost))
        }
        return result.sorted { $0.1 > $1.1 }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    timeRangeSelector
                    summaryCards
                    statusDistribution
                    projectCosts
                    workerPerformance
                    costlyTasks
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color.commanderBg)
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Time Range

    private var timeRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(TimeRange.allCases, id: \.rawValue) { range in
                    FilterChip(label: range.rawValue, isSelected: timeRange == range) {
                        withAnimation { timeRange = range }
                    }
                }
            }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
        ], spacing: 8) {
            reportCard(label: "Total Cost", value: String(format: "$%.2f", totalCost), color: .commanderOrange)
            reportCard(label: "Avg Cost/Task", value: String(format: "$%.2f", avgCost), color: .commanderAmber)
            reportCard(label: "Avg Duration", value: String(format: "%.1f min", avgDurationMinutes), color: .commanderPurple)
            reportCard(label: "Success Rate", value: String(format: "%.0f%%", successRate * 100), color: successRate > 0.8 ? .commanderGreen : .commanderRed)
            reportCard(label: "Total Tasks", value: "\(filteredTasks.count)", color: .commanderText)
            reportCard(label: "Projects", value: "\(Set(filteredTasks.map { $0.project }).count)", color: .commanderSecondary)
        }
    }

    private func reportCard(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.commanderSmall)
                .foregroundColor(.commanderSecondary)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.commanderSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.commanderBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Status Distribution

    private var statusDistribution: some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Status Distribution")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderOrange)

                if filteredTasks.isEmpty {
                    Text("No tasks in this time range")
                        .font(.commanderCaption)
                        .foregroundColor(.commanderMuted)
                } else {
                    ForEach(statusBreakdown, id: \.0) { status, count in
                        HStack(spacing: 8) {
                            Image(systemName: status.icon)
                                .font(.system(size: 12))
                                .foregroundColor(status.color)
                                .frame(width: 20)
                            Text(status.displayName)
                                .font(.commanderCaption)
                                .foregroundColor(.commanderText)
                            Spacer()
                            Text("\(count)")
                                .font(.commanderCaptionMedium)
                                .foregroundColor(.commanderSecondary)

                            GeometryReader { geo in
                                Capsule()
                                    .fill(status.color)
                                    .frame(width: geo.size.width * Double(count) / Double(max(filteredTasks.count, 1)), height: 6)
                            }
                            .frame(width: 60, height: 6)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Project Costs

    @ViewBuilder
    private var projectCosts: some View {
        if !projectBreakdown.isEmpty {
            CommanderCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Cost by Project")
                        .font(.commanderCaptionMedium)
                        .foregroundColor(.commanderOrange)

                    ForEach(projectBreakdown, id: \.0) { project, count, cost in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(project)
                                    .font(.commanderCaptionMedium)
                                    .foregroundColor(.commanderText)
                                Text("\(count) tasks")
                                    .font(.commanderSmall)
                                    .foregroundColor(.commanderMuted)
                            }
                            Spacer()
                            Text(String(format: "$%.2f", cost))
                                .font(.commanderSubhead)
                                .foregroundColor(.commanderOrange)
                        }

                        if project != projectBreakdown.last?.0 {
                            Divider()
                                .background(Color.commanderBorder)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Worker Performance

    @ViewBuilder
    private var workerPerformance: some View {
        if !workerBreakdown.isEmpty {
            CommanderCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Worker Performance")
                        .font(.commanderCaptionMedium)
                        .foregroundColor(.commanderOrange)

                    ForEach(workerBreakdown, id: \.0) { worker, count, cost in
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "server.rack")
                                    .font(.system(size: 12))
                                    .foregroundColor(.commanderSecondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(worker)
                                        .font(.commanderCaptionMedium)
                                        .foregroundColor(.commanderText)
                                    Text("\(count) tasks · \(String(format: "$%.2f", cost))")
                                        .font(.commanderSmall)
                                        .foregroundColor(.commanderMuted)
                                }
                            }
                            Spacer()
                            Text(String(format: "$%.2f avg", count > 0 ? cost / Double(count) : 0))
                                .font(.commanderSmall)
                                .foregroundColor(.commanderSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Costly Tasks

    @ViewBuilder
    private var costlyTasks: some View {
        let expensive = filteredTasks
            .filter { ($0.costUsd ?? 0) > 0 }
            .sorted { ($0.costUsd ?? 0) > ($1.costUsd ?? 0) }
            .prefix(5)

        if !expensive.isEmpty {
            CommanderCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Most Expensive Tasks")
                        .font(.commanderCaptionMedium)
                        .foregroundColor(.commanderOrange)

                    ForEach(Array(expensive)) { task in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("#\(task.numId) \(task.task)")
                                    .font(.commanderCaption)
                                    .foregroundColor(.commanderText)
                                    .lineLimit(1)
                                Text(task.project)
                                    .font(.commanderSmall)
                                    .foregroundColor(.commanderMuted)
                            }
                            Spacer()
                            if let cost = task.costString {
                                Text(cost)
                                    .font(.commanderCaptionMedium)
                                    .foregroundColor(.commanderRed)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    DevReportsView()
        .environmentObject(DataStore.shared)
}
