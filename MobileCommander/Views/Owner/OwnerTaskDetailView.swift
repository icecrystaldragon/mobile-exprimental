import SwiftUI

struct OwnerTaskDetailView: View {
    let task: CommanderTask
    @EnvironmentObject var store: DataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                statusSection
                descriptionSection
                detailsSection

                followUpSection

                if task.status == .failed || task.status == .blocked {
                    retrySection
                }
            }
            .padding(16)
        }
        .background(Color.commanderBg)
        .navigationTitle(task.task)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status

    private var statusSection: some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    StatusBadge(status: task.effectiveStatus)
                    Spacer()
                    if task.status == .running {
                        HStack(spacing: 6) {
                            LiveDot()
                            Text("Working...")
                                .font(.commanderSmall)
                                .foregroundColor(.commanderAmber)
                        }
                    }
                }

                Text(task.task)
                    .font(.commanderSubhead)
                    .foregroundColor(.commanderText)

                Label(task.project, systemImage: "folder.fill")
                    .font(.commanderCaption)
                    .foregroundColor(.commanderOrange)

                if let error = task.error {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What went wrong:")
                            .font(.commanderCaptionMedium)
                            .foregroundColor(.commanderRed)
                        Text(error)
                            .font(.commanderCaption)
                            .foregroundColor(.commanderRed.opacity(0.8))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.commanderRedDim)
                    .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("What was requested")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderSecondary)
                Text(task.description)
                    .font(.commanderBody)
                    .foregroundColor(.commanderText)
            }
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Details")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderSecondary)

                if let duration = task.durationString {
                    detailRow(icon: "clock", label: "Time taken", value: duration)
                }
                if let cost = task.costString {
                    detailRow(icon: "dollarsign.circle", label: "Cost", value: cost)
                }
                if let worker = task.claimedBy {
                    detailRow(icon: "server.rack", label: "Handled by", value: worker)
                }
                if let created = task.createdAt {
                    detailRow(icon: "calendar", label: "Created", value: created.commanderDateString)
                }
                if let completed = task.completedAt {
                    detailRow(icon: "checkmark.circle", label: "Finished", value: completed.commanderDateString)
                }

                if task.reviewStatus != .none {
                    detailRow(icon: "eye", label: "Review", value: task.reviewStatus.displayName)
                }
                if let test = task.testStatus {
                    detailRow(icon: "testtube.2", label: "Tests", value: test)
                }
                if let deploy = task.deployStatus {
                    detailRow(icon: "arrow.up.circle", label: "Deploy", value: deploy)
                }
            }
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.commanderMuted)
                .frame(width: 20)
            Text(label)
                .font(.commanderCaption)
                .foregroundColor(.commanderSecondary)
            Spacer()
            Text(value)
                .font(.commanderCaption)
                .foregroundColor(.commanderText)
        }
    }

    // MARK: - Follow Up

    @ViewBuilder
    private var followUpSection: some View {
        if let followUp = task.followUp, !followUp.isEmpty {
            CommanderCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.commanderGreen)
                        Text("Summary")
                            .font(.commanderCaptionMedium)
                            .foregroundColor(.commanderGreen)
                    }
                    Text(followUp)
                        .font(.commanderBody)
                        .foregroundColor(.commanderText)
                        .textSelection(.enabled)
                }
            }
        }
    }

    // MARK: - Retry

    private var retrySection: some View {
        Button {
            Task { try? await store.retryTask(task) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                Text("Try Again")
                    .font(.commanderSubhead)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.commanderOrange)
            .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationView {
        OwnerTaskDetailView(task: MockData.tasks[0])
            .environmentObject(DataStore.shared)
    }
}
