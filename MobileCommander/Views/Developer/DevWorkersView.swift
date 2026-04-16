import SwiftUI

struct DevWorkersView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    fleetSummary

                    if store.workers.isEmpty {
                        EmptyStateView(
                            icon: "server.rack",
                            title: "No workers online",
                            subtitle: "Start a worker with: node worker/index.js"
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(store.workers) { worker in
                                workerDetailCard(worker)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color.commanderBg)
            .navigationTitle("Workers")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await store.refresh()
            }
        }
    }

    // MARK: - Fleet Summary

    private var fleetSummary: some View {
        HStack(spacing: 12) {
            fleetStat("Online", value: store.workers.filter { $0.status != .offline }.count, color: .commanderGreen)
            fleetStat("Busy", value: store.workers.filter { $0.status == .busy }.count, color: .commanderAmber)
            fleetStat("Offline", value: store.workers.filter { $0.status == .offline }.count, color: .commanderSecondary)
            fleetStat("Total", value: store.workers.count, color: .commanderText)
        }
    }

    private func fleetStat(_ label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.commanderHeadline)
                .foregroundColor(color)
            Text(label)
                .font(.commanderSmall)
                .foregroundColor(.commanderSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.commanderSurface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.commanderBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Worker Detail Card

    private func workerDetailCard(_ worker: CommanderWorker) -> some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 16))
                        .foregroundColor(.commanderOrange)

                    Text(worker.hostname)
                        .font(.commanderSubhead)
                        .foregroundColor(.commanderText)

                    Spacer()

                    HStack(spacing: 4) {
                        Circle()
                            .fill(worker.status.color)
                            .frame(width: 8, height: 8)
                        Text(worker.status.rawValue.capitalized)
                            .font(.commanderSmall)
                            .foregroundColor(worker.status.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(worker.status.color.opacity(0.15))
                    .cornerRadius(6)
                }

                // Stats row
                HStack(spacing: 16) {
                    workerStat("Active", value: "\(worker.activeTaskCount)/\(worker.maxParallel)", color: .commanderAmber)
                    workerStat("Completed", value: "\(worker.completedTasks)", color: .commanderGreen)
                    if let plan = worker.plan {
                        workerStat("Plan", value: plan, color: .commanderPurple)
                    }
                }

                // Quota bar
                if let quota = worker.quotaRemaining {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Quota")
                                .font(.commanderSmall)
                                .foregroundColor(.commanderMuted)
                            Spacer()
                            Text("\(Int(quota * 100))%")
                                .font(.commanderSmall)
                                .foregroundColor(quota < 0.2 ? .commanderRed : .commanderSecondary)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.commanderBorder.opacity(0.3))
                                    .frame(height: 4)
                                Capsule()
                                    .fill(quota < 0.2 ? Color.commanderRed : Color.commanderGreen)
                                    .frame(width: geo.size.width * quota, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }

                // Rate limit warning
                if worker.isRateLimited {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                        Text("Rate limited")
                        if let reset = worker.rateLimitResetAt {
                            Text("· resets \(reset.commanderRelative)")
                        }
                    }
                    .font(.commanderSmall)
                    .foregroundColor(.commanderAmber)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.commanderAmberDim)
                    .cornerRadius(6)
                }

                // Last heartbeat
                if let hb = worker.lastHeartbeat {
                    Text("Last heartbeat: \(hb.commanderRelative)")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderMuted)
                }
            }
        }
    }

    private func workerStat(_ label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.commanderSmall)
                .foregroundColor(.commanderMuted)
            Text(value)
                .font(.commanderCaptionMedium)
                .foregroundColor(color)
        }
    }
}

#Preview {
    DevWorkersView()
        .environmentObject(DataStore.shared)
}
