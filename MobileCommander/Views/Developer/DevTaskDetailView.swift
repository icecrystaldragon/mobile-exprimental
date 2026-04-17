import SwiftUI
import FirebaseFirestore

struct DevTaskDetailView: View {
    let task: CommanderTask
    @EnvironmentObject var store: DataStore
    @State private var outputChunks: [OutputChunk] = []
    @State private var chatMessages: [ChatMessage] = []
    @State private var chatInput = ""
    @State private var selectedTab: DetailTab = .output
    @State private var autoScroll = true
    @State private var outputListener: ListenerRegistration?
    @State private var chatListener: ListenerRegistration?
    @State private var showDeleteConfirm = false
    @State private var isEditing = false
    @State private var editProject: String = ""
    @State private var editPath: String = ""
    @State private var editDescription: String = ""
    @State private var editPriority: String = ""
    @State private var editAssignedWorker: String = ""

    enum DetailTab: String, CaseIterable {
        case output = "Output"
        case chat = "Chat"
        case followUp = "Follow Up"
        case info = "Info"
    }

    var body: some View {
        VStack(spacing: 0) {
            taskHeader
            tabSelector
            tabContent
        }
        .background(Color.commanderBg)
        .navigationTitle("#\(task.numId)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if task.status == .failed || task.status == .blocked {
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            Task { try? await store.retryTask(task) }
                        } label: {
                            Label("Retry Task", systemImage: "arrow.clockwise")
                        }
                    }

                    if task.effectiveStatus == .needsReview {
                        Button {
                            let impact = UINotificationFeedbackGenerator()
                            impact.notificationOccurred(.success)
                            Task { try? await store.approveTask(task) }
                        } label: {
                            Label("Approve", systemImage: "checkmark.seal")
                        }

                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            Task { try? await store.requestChanges(task) }
                        } label: {
                            Label("Request Changes", systemImage: "arrow.uturn.backward")
                        }
                    }

                    Button {
                        Task {
                            try? await store.updateTaskStatus(task, status: .done)
                        }
                    } label: {
                        Label("Mark Done", systemImage: "checkmark.circle")
                    }

                    Button(role: .destructive) {
                        Task {
                            try? await store.updateTaskStatus(task, status: .failed)
                        }
                    } label: {
                        Label("Mark Failed", systemImage: "xmark.circle")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Task", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.commanderOrange)
                }
            }
        }
        .onAppear { startListeners() }
        .onDisappear { stopListeners() }
        .alert("Delete Task #\(task.numId)?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.warning)
                Task { try? await store.deleteTask(task) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove \"\(task.task)\" and all its output. This cannot be undone.")
        }
    }

    // MARK: - Task Header

    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                StatusBadge(status: task.effectiveStatus)

                Text(task.project)
                    .font(.commanderSmall)
                    .foregroundColor(.commanderOrange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.commanderOrangeDim)
                    .cornerRadius(4)

                Spacer()

                if task.status == .running {
                    LiveDot()
                }
            }

            Text(task.task)
                .font(.commanderSubhead)
                .foregroundColor(.commanderText)

            HStack(spacing: 12) {
                if let cost = task.costString {
                    Label(cost, systemImage: "dollarsign.circle")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderSecondary)
                }
                if let duration = task.durationString {
                    Label(duration, systemImage: "clock")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderSecondary)
                }
                if let worker = task.claimedBy {
                    Label(worker, systemImage: "server.rack")
                        .font(.commanderSmall)
                        .foregroundColor(.commanderSecondary)
                }
            }
        }
        .padding(16)
        .background(Color.commanderSurface)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.commanderCaptionMedium)
                            if tab == .chat && !chatMessages.isEmpty {
                                Text("\(chatMessages.count)")
                                    .font(.commanderSmall)
                                    .foregroundColor(.commanderOrange)
                            }
                        }
                        .foregroundColor(selectedTab == tab ? .commanderOrange : .commanderSecondary)

                        Rectangle()
                            .fill(selectedTab == tab ? Color.commanderOrange : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .background(Color.commanderSurface)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .output:
            outputView
        case .chat:
            chatView
        case .followUp:
            followUpView
        case .info:
            infoView
        }
    }

    // MARK: - Output View

    private var outputView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if outputChunks.isEmpty {
                        EmptyStateView(
                            icon: "text.alignleft",
                            title: "No output yet",
                            subtitle: task.status == .pending ? "Task is waiting to be claimed" : "Output will appear here"
                        )
                    } else {
                        ForEach(outputChunks) { chunk in
                            outputChunkView(chunk)
                                .id(chunk.id)
                        }
                    }
                }
                .padding(12)
            }
            .background(Color(red: 0.05, green: 0.05, blue: 0.07))
            .onChange(of: outputChunks.count) { _, _ in
                if autoScroll, let last = outputChunks.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func outputChunkView(_ chunk: OutputChunk) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            switch chunk.type {
            case .assistant:
                Text(chunk.content)
                    .font(.commanderMono)
                    .foregroundColor(.commanderText)
            case .toolUse:
                HStack(spacing: 4) {
                    Image(systemName: "wrench.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.commanderAmber)
                    Text(chunk.content)
                        .font(.commanderMonoSmall)
                        .foregroundColor(.commanderAmber)
                }
                .padding(.vertical, 2)
            case .toolResult:
                Text(chunk.content)
                    .font(.commanderMonoSmall)
                    .foregroundColor(.commanderSecondary)
                    .padding(8)
                    .background(Color.commanderBg.opacity(0.5))
                    .cornerRadius(6)
            case .system:
                Text(chunk.content)
                    .font(.commanderMonoSmall)
                    .foregroundColor(.commanderMuted)
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Chat View

    private var chatView: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 8) {
                    if chatMessages.isEmpty {
                        EmptyStateView(
                            icon: "bubble.left.and.bubble.right",
                            title: "No messages",
                            subtitle: task.status == .running ? "Send a message to interact with this task" : "Chat is available while a task is running"
                        )
                    } else {
                        ForEach(chatMessages) { msg in
                            chatBubble(msg)
                        }
                    }
                }
                .padding(12)
            }

            if task.status == .running {
                chatInputBar
            }
        }
    }

    private func chatBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer() }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if let name = message.senderName {
                    Text(name)
                        .font(.commanderSmall)
                        .foregroundColor(.commanderMuted)
                }

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
                        Text("Pending...")
                            .font(.commanderSmall)
                            .foregroundColor(.commanderMuted)
                    }
                }
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant { Spacer() }
        }
    }

    private var chatInputBar: some View {
        HStack(spacing: 8) {
            TextField("Message...", text: $chatInput)
                .font(.commanderBody)
                .foregroundColor(.commanderText)
                .padding(10)
                .background(Color.commanderSurface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.commanderBorder, lineWidth: 0.5)
                )

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(chatInput.isEmpty ? .commanderMuted : .commanderOrange)
            }
            .disabled(chatInput.isEmpty)
        }
        .padding(12)
        .background(Color.commanderSurface)
    }

    // MARK: - Follow Up View

    private var followUpView: some View {
        ScrollView {
            if let followUp = task.followUp, !followUp.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(followUp)
                        .font(.commanderBody)
                        .foregroundColor(.commanderText)
                        .textSelection(.enabled)
                }
                .padding(16)
            } else {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No follow-up notes",
                    subtitle: "Follow-up notes will appear here after the task completes"
                )
            }
        }
    }

    // MARK: - Info View

    private var infoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Spacer()
                    Button {
                        if isEditing {
                            saveEdits()
                        } else {
                            editProject = task.project
                            editPath = task.path
                            editDescription = task.description
                            editPriority = "\(task.priority)"
                            editAssignedWorker = task.assignedWorker ?? ""
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditing.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                                .font(.system(size: 14))
                            Text(isEditing ? "Save" : "Edit")
                                .font(.commanderCaptionMedium)
                        }
                        .foregroundColor(.commanderOrange)
                    }
                    .buttonStyle(.plain)
                }

                infoSection("Task Details") {
                    infoRow("ID", "#\(task.numId)")
                    InlineEditField(label: "Project", text: $editProject, placeholder: "Project", isEditing: isEditing)
                    InlineEditField(label: "Path", text: $editPath, placeholder: "Working directory", isEditing: isEditing)
                    InlineEditField(label: "Priority", text: $editPriority, placeholder: "1-100", isEditing: isEditing)
                    InlineEditField(label: "Worker", text: $editAssignedWorker, placeholder: "Any", isEditing: isEditing)
                    if !task.dependsOn.isEmpty {
                        infoRow("Depends On", task.dependsOn.map { "#\($0)" }.joined(separator: ", "))
                    }
                }

                infoSection("Description") {
                    if isEditing {
                        TextEditor(text: $editDescription)
                            .font(.commanderBody)
                            .foregroundColor(.commanderText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color.commanderBg)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.commanderOrange.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        Text(task.description)
                            .font(.commanderBody)
                            .foregroundColor(.commanderText)
                            .textSelection(.enabled)
                    }
                }

                infoSection("Execution") {
                    infoRow("Status", task.effectiveStatus.displayName)
                    if let worker = task.claimedBy {
                        infoRow("Worker", worker)
                    }
                    if let cost = task.costString {
                        infoRow("Cost", cost)
                    }
                    if let duration = task.durationString {
                        infoRow("Duration", duration)
                    }
                    if let exitCode = task.exitCode {
                        infoRow("Exit Code", "\(exitCode)")
                    }
                    if let error = task.error {
                        Text(error)
                            .font(.commanderMono)
                            .foregroundColor(.commanderRed)
                            .padding(8)
                            .background(Color.commanderRedDim)
                            .cornerRadius(6)
                    }
                }

                infoSection("Timestamps") {
                    if let created = task.createdAt {
                        infoRow("Created", created.commanderDateString)
                    }
                    if let started = task.startedAt {
                        infoRow("Started", started.commanderDateString)
                    }
                    if let completed = task.completedAt {
                        infoRow("Completed", completed.commanderDateString)
                    }
                }

                infoSection("Review") {
                    infoRow("Review", task.reviewStatus.displayName)
                    if let test = task.testStatus {
                        infoRow("Tests", test)
                    }
                    if let deploy = task.deployStatus {
                        infoRow("Deploy", deploy)
                    }
                }
            }
            .padding(16)
        }
    }

    private func saveEdits() {
        Task {
            if editProject != task.project {
                try? await store.updateTaskField(task, field: "project", value: editProject)
            }
            if editPath != task.path {
                try? await store.updateTaskField(task, field: "path", value: editPath)
            }
            if editDescription != task.description {
                try? await store.updateTaskField(task, field: "description", value: editDescription)
            }
            if let newPriority = Int(editPriority), newPriority != task.priority {
                try? await store.updateTaskField(task, field: "priority", value: newPriority)
            }
            let newWorker = editAssignedWorker.trimmingCharacters(in: .whitespaces)
            if newWorker != (task.assignedWorker ?? "") {
                try? await store.updateTaskField(task, field: "assigned_worker", value: newWorker.isEmpty ? NSNull() : newWorker)
            }
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        }
    }

    private func infoSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        CommanderCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderOrange)
                content()
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.commanderCaption)
                .foregroundColor(.commanderSecondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.commanderCaption)
                .foregroundColor(.commanderText)
            Spacer()
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

    private func startListeners() {
        outputListener = store.listenToOutput(taskId: task.id) { chunks in
            Task { @MainActor in
                self.outputChunks = chunks
            }
        }
        chatListener = store.listenToChat(taskId: task.id) { messages in
            Task { @MainActor in
                self.chatMessages = messages
            }
        }
    }

    private func stopListeners() {
        outputListener?.remove()
        chatListener?.remove()
        outputListener = nil
        chatListener = nil
    }
}

#Preview {
    NavigationView {
        DevTaskDetailView(task: MockData.tasks[0])
            .environmentObject(DataStore.shared)
    }
}
