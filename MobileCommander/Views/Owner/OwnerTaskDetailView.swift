import SwiftUI
import FirebaseFirestore

struct OwnerTaskDetailView: View {
    let task: CommanderTask
    @EnvironmentObject var store: DataStore
    @State private var chatMessages: [ChatMessage] = []
    @State private var chatInput = ""
    @State private var chatListener: ListenerRegistration?
    @State private var showRetryConfirm = false
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                statusSection
                progressSection
                descriptionSection
                detailsSection
                followUpSection
                actionButtons
                chatSection
            }
            .padding(16)
        }
        .background(Color.commanderBg)
        .navigationTitle(task.task)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startChatListener()
            startElapsedTimer()
        }
        .onDisappear {
            chatListener?.remove()
            chatListener = nil
            timer?.invalidate()
            timer = nil
        }
        .alert("Try again?", isPresented: $showRetryConfirm) {
            Button("Yes, retry", role: .destructive) {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                Task { try? await store.retryTask(task) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset the task and put it back in the queue for a worker to pick up.")
        }
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
                            Text("Working on it...")
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

    // MARK: - Progress (for running tasks)

    @ViewBuilder
    private var progressSection: some View {
        if task.status == .running {
            CommanderAccentCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 12))
                            .foregroundColor(.commanderAmber)
                        Text("In Progress")
                            .font(.commanderCaptionMedium)
                            .foregroundColor(.commanderAmber)
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Time elapsed")
                                .font(.commanderSmall)
                                .foregroundColor(.commanderMuted)
                            Text(formatElapsed(elapsedSeconds))
                                .font(.commanderMono)
                                .foregroundColor(.commanderText)
                        }

                        if let worker = task.claimedBy {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Being handled by")
                                    .font(.commanderSmall)
                                    .foregroundColor(.commanderMuted)
                                Text(worker)
                                    .font(.commanderCaptionMedium)
                                    .foregroundColor(.commanderSecondary)
                            }
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

                    Text("You can send a message below to ask questions or give feedback while it works.")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderMuted)
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

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if task.effectiveStatus == .needsReview {
            VStack(spacing: 10) {
                Text("This task is done and ready for your review.")
                    .font(.commanderCaption)
                    .foregroundColor(.commanderSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        Task { try? await store.approveTask(task) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.thumbsup.fill")
                            Text("Looks Good")
                                .font(.commanderSubhead)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.commanderGreen)
                        .cornerRadius(12)
                    }

                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        Task { try? await store.requestChanges(task) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Needs Work")
                                .font(.commanderSubhead)
                        }
                        .foregroundColor(.commanderAmber)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.commanderAmberDim)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.commanderAmber.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }

        if task.status == .failed || task.status == .blocked {
            Button {
                showRetryConfirm = true
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

    // MARK: - Chat Section

    @ViewBuilder
    private var chatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.commanderPurple)
                Text("Messages")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderPurple)
                if !chatMessages.isEmpty {
                    Text("\(chatMessages.count)")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderPurple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.commanderPurpleDim)
                        .cornerRadius(8)
                }
            }

            if chatMessages.isEmpty && task.status != .running {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 14))
                        .foregroundColor(.commanderMuted)
                    Text("No messages yet. You can send messages while a task is running.")
                        .font(.commanderCaption)
                        .foregroundColor(.commanderMuted)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.commanderSurface)
                .cornerRadius(10)
            } else {
                ForEach(chatMessages) { msg in
                    ownerChatBubble(msg)
                }
            }

            if task.status == .running || !chatMessages.isEmpty {
                ownerChatInput
            }
        }
    }

    private func ownerChatBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer() }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.role == .user ? "You" : "Commander")
                    .font(.commanderSmall)
                    .foregroundColor(.commanderMuted)

                Text(message.content)
                    .font(.commanderBody)
                    .foregroundColor(message.role == .user ? .white : .commanderText)
                    .padding(10)
                    .background(message.role == .user ? Color.commanderOrange : Color.commanderSurface)
                    .cornerRadius(12)

                if message.isPending {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Sending...")
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                    }
                }

                if let time = message.timestamp {
                    Text(time.commanderRelative)
                        .font(.commanderSmall)
                        .foregroundColor(.commanderMuted)
                }
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant { Spacer() }
        }
    }

    private var ownerChatInput: some View {
        HStack(spacing: 8) {
            TextField("Ask a question or give feedback...", text: $chatInput)
                .font(.commanderBody)
                .foregroundColor(.commanderText)
                .padding(12)
                .background(Color.commanderSurface)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.commanderBorder, lineWidth: 0.5)
                )

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(chatInput.trimmingCharacters(in: .whitespaces).isEmpty ? .commanderMuted : .commanderOrange)
            }
            .disabled(chatInput.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        let content = chatInput.trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        chatInput = ""
        Task {
            try? await store.sendChatMessage(taskId: task.id, content: content)
        }
    }

    private func startChatListener() {
        chatListener = store.listenToChat(taskId: task.id) { messages in
            Task { @MainActor in
                self.chatMessages = messages
            }
        }
    }

    private func startElapsedTimer() {
        updateElapsed()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                updateElapsed()
            }
        }
    }

    private func updateElapsed() {
        if let started = task.startedAt, task.status == .running {
            elapsedSeconds = Int(Date().timeIntervalSince(started))
        } else if let ms = task.durationMs {
            elapsedSeconds = ms / 1000
        }
    }

    private func formatElapsed(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        if m < 60 { return String(format: "%dm %02ds", m, s) }
        let h = m / 60
        let rm = m % 60
        return String(format: "%dh %02dm", h, rm)
    }
}

#Preview {
    NavigationView {
        OwnerTaskDetailView(task: MockData.tasks[0])
            .environmentObject(DataStore.shared)
    }
}
