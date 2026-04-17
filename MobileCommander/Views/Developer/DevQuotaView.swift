import SwiftUI

struct DevQuotaView: View {
    @EnvironmentObject var store: DataStore

    private var totalCost: Double {
        store.tasks.reduce(0) { $0 + ($1.costUsd ?? 0) }
    }

    private var todayCost: Double {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return store.tasks
            .filter { ($0.createdAt ?? .distantPast) >= startOfDay }
            .reduce(0) { $0 + ($1.costUsd ?? 0) }
    }

    private var onlineWorkers: [CommanderWorker] {
        store.workers.filter { $0.status != .offline }
    }

    private var rateLimitedWorkers: [CommanderWorker] {
        store.workers.filter { $0.isRateLimited }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                costSummary
                workerQuotas
                rateLimitSection
                costBreakdown
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.commanderBg)
        .navigationTitle("Quota & Costs")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await store.refresh()
        }
    }

    // MARK: - Cost Summary

    private var costSummary: some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Cost Overview")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderOrange)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today")
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                        Text(String(format: "$%.2f", todayCost))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.commanderOrange)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("All Time")
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                        Text(String(format: "$%.2f", totalCost))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.commanderText)
                    }
                    Spacer()
                }

                let tasksWithCost = store.tasks.filter { ($0.costUsd ?? 0) > 0 }
                if !tasksWithCost.isEmpty {
                    let avg = tasksWithCost.reduce(0) { $0 + ($1.costUsd ?? 0) } / Double(tasksWithCost.count)
                    CompactStatRow(
                        icon: "chart.bar",
                        label: "Avg cost per task",
                        value: String(format: "$%.2f", avg),
                        color: .commanderAmber
                    )
                }
            }
        }
    }

    // MARK: - Worker Quotas

    private var workerQuotas: some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Worker Quotas")

                if store.workers.isEmpty {
                    Text("No workers registered")
                        .font(.commanderCaption)
                        .foregroundColor(.commanderMuted)
                } else {
                    ForEach(store.workers) { worker in
                        workerQuotaRow(worker)
                        if worker.id != store.workers.last?.id {
                            Divider().background(Color.commanderBorder)
                        }
                    }
                }
            }
        }
    }

    private func workerQuotaRow(_ worker: CommanderWorker) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(worker.status.color)
                    .frame(width: 8, height: 8)
                Text(worker.hostname)
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderText)
                Spacer()
                if let plan = worker.plan {
                    Text(plan.uppercased())
                        .font(.commanderSmall)
                        .foregroundColor(.commanderPurple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.commanderPurpleDim)
                        .cornerRadius(4)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Active")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderMuted)
                    Text("\(worker.activeTaskCount)/\(worker.maxParallel)")
                        .font(.commanderCaptionMedium)
                        .foregroundColor(.commanderAmber)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Completed")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderMuted)
                    Text("\(worker.completedTasks)")
                        .font(.commanderCaptionMedium)
                        .foregroundColor(.commanderGreen)
                }
            }

            if let quota = worker.quotaRemaining {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Quota remaining")
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                        Spacer()
                        Text("\(Int(quota * 100))%")
                            .font(.commanderSmall)
                            .foregroundColor(quota < 0.2 ? .commanderRed : .commanderGreen)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.commanderBorder.opacity(0.3))
                                .frame(height: 6)
                            Capsule()
                                .fill(quota < 0.2 ? Color.commanderRed : Color.commanderGreen)
                                .frame(width: geo.size.width * quota, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }

            if worker.isRateLimited {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text("Rate limited")
                    if let reset = worker.rateLimitResetAt {
                        Text("· resets \(reset.commanderRelative)")
                    }
                }
                .font(.commanderSmall)
                .foregroundColor(.commanderAmber)
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.commanderAmberDim)
                .cornerRadius(6)
            }
        }
    }

    // MARK: - Rate Limit Section

    @ViewBuilder
    private var rateLimitSection: some View {
        if !rateLimitedWorkers.isEmpty {
            CommanderAccentCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.commanderAmber)
                        Text("\(rateLimitedWorkers.count) worker\(rateLimitedWorkers.count == 1 ? "" : "s") rate limited")
                            .font(.commanderSubhead)
                            .foregroundColor(.commanderAmber)
                    }

                    ForEach(rateLimitedWorkers) { worker in
                        HStack(spacing: 8) {
                            Text(worker.hostname)
                                .font(.commanderCaption)
                                .foregroundColor(.commanderText)
                            Spacer()
                            if let reset = worker.rateLimitResetAt {
                                Text("Resets \(reset.commanderRelative)")
                                    .font(.commanderSmall)
                                    .foregroundColor(.commanderMuted)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Cost Breakdown

    @ViewBuilder
    private var costBreakdown: some View {
        let projectCosts = store.projectNames.map { project -> (String, Double) in
            let cost = store.tasks(for: project).reduce(0) { $0 + ($1.costUsd ?? 0) }
            return (project, cost)
        }.sorted { $0.1 > $1.1 }

        if !projectCosts.isEmpty {
            CommanderCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Cost by Project")
                        .font(.commanderCaptionMedium)
                        .foregroundColor(.commanderOrange)

                    ForEach(projectCosts, id: \.0) { project, cost in
                        HStack {
                            Text(project)
                                .font(.commanderCaption)
                                .foregroundColor(.commanderText)
                            Spacer()
                            Text(String(format: "$%.2f", cost))
                                .font(.commanderCaptionMedium)
                                .foregroundColor(.commanderOrange)
                        }
                    }

                    Divider().background(Color.commanderBorder)

                    HStack {
                        Text("Total")
                            .font(.commanderCaptionMedium)
                            .foregroundColor(.commanderText)
                        Spacer()
                        Text(String(format: "$%.2f", totalCost))
                            .font(.commanderSubhead)
                            .foregroundColor(.commanderOrange)
                    }
                }
            }
        }
    }
}

#Preview {
    DevQuotaView()
        .environmentObject(DataStore.shared)
}
