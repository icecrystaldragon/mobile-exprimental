import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

// MARK: - Data Store

@MainActor
class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var tasks: [CommanderTask] = []
    @Published var workers: [CommanderWorker] = []
    @Published var activities: [ActivityEvent] = []
    @Published var currentUser: User?
    @Published var isLoading = true
    @Published var isAuthenticated = false

    private var taskListener: ListenerRegistration?
    private var workerListener: ListenerRegistration?
    private var activityListener: ListenerRegistration?

    private let db = Firestore.firestore()

    private init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                if user != nil {
                    self?.startListening()
                } else {
                    self?.stopListening()
                }
            }
        }
    }

    // MARK: - Auth

    func signInWithGoogle() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = result.user.idToken?.tokenString else { return }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        try await Auth.auth().signIn(with: credential)
    }

    func signOut() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    // MARK: - Listeners

    func startListening() {
        listenToTasks()
        listenToWorkers()
        listenToActivity()
    }

    func refresh() async {
        stopListening()
        startListening()
        try? await Task.sleep(nanoseconds: 500_000_000)
    }

    func stopListening() {
        taskListener?.remove()
        workerListener?.remove()
        activityListener?.remove()
        tasks = []
        workers = []
        activities = []
    }

    private func listenToTasks() {
        taskListener?.remove()
        let q = db.collection("commander_tasks").order(by: "priority")
        taskListener = q.addSnapshotListener { [weak self] snapshot, error in
            guard let docs = snapshot?.documents else { return }
            var seen: [Int: CommanderTask] = [:]
            for doc in docs {
                if let task = Self.decodeTask(doc) {
                    let existing = seen[task.numId]
                    if existing == nil || (task.createdAt ?? .distantPast) > (existing!.createdAt ?? .distantPast) {
                        seen[task.numId] = task
                    }
                }
            }
            Task { @MainActor in
                self?.tasks = Array(seen.values).sorted { $0.priority < $1.priority }
                self?.isLoading = false
            }
        }
    }

    private func listenToWorkers() {
        workerListener?.remove()
        let q = db.collection("commander_workers").order(by: "hostname")
        workerListener = q.addSnapshotListener { [weak self] snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let workers = docs.compactMap { Self.decodeWorker($0) }
            Task { @MainActor in
                self?.workers = workers
            }
        }
    }

    private func listenToActivity() {
        activityListener?.remove()
        let q = db.collection("commander_activity")
            .order(by: "timestamp", descending: true)
            .limit(to: 100)
        activityListener = q.addSnapshotListener { [weak self] snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let events = docs.compactMap { Self.decodeActivity($0) }
            Task { @MainActor in
                self?.activities = events
            }
        }
    }

    // MARK: - Task Operations

    func createTask(_ form: NewTaskForm) async throws {
        let q = db.collection("commander_tasks")
            .order(by: "num_id", descending: true)
            .limit(to: 1)
        let snap = try await q.getDocuments()
        let nextId = snap.documents.isEmpty ? 1 : ((snap.documents[0].data()["num_id"] as? Int) ?? 0) + 1

        let deps = form.dependsOn.trimmingCharacters(in: .whitespaces).isEmpty
            ? [Int]()
            : form.dependsOn.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

        let data: [String: Any] = [
            "num_id": nextId,
            "project": form.project.trimmingCharacters(in: .whitespaces),
            "path": form.path.trimmingCharacters(in: .whitespaces),
            "task": form.task.trimmingCharacters(in: .whitespaces),
            "description": form.description.trimmingCharacters(in: .whitespaces),
            "depends_on": deps,
            "status": "pending",
            "priority": form.priority,
            "assigned_worker": form.assignedWorker.isEmpty ? NSNull() : form.assignedWorker,
            "created_at": FieldValue.serverTimestamp(),
            "updated_at": FieldValue.serverTimestamp(),
            "claimed_by": NSNull(),
            "claimed_at": NSNull(),
            "started_at": NSNull(),
            "completed_at": NSNull(),
            "session_id": NSNull(),
            "cost_usd": NSNull(),
            "duration_ms": NSNull(),
            "exit_code": NSNull(),
            "error": NSNull(),
            "needs_human": false,
            "human_reason": NSNull(),
        ]

        try await db.collection("commander_tasks").addDocument(data: data)

        try await logActivity("task_created", details: [
            "task_num_id": "\(nextId)",
            "project": form.project.trimmingCharacters(in: .whitespaces),
            "task_name": form.task.trimmingCharacters(in: .whitespaces),
        ])
    }

    func retryTask(_ task: CommanderTask) async throws {
        let q = db.collection("commander_tasks")
            .whereField("num_id", isEqualTo: task.numId)
            .limit(to: 1)
        let snap = try await q.getDocuments()
        guard let doc = snap.documents.first else { return }

        try await doc.reference.updateData([
            "status": "pending",
            "claimed_by": NSNull(),
            "claimed_at": NSNull(),
            "started_at": NSNull(),
            "completed_at": NSNull(),
            "session_id": NSNull(),
            "exit_code": NSNull(),
            "error": NSNull(),
            "cost_usd": NSNull(),
            "duration_ms": NSNull(),
            "updated_at": FieldValue.serverTimestamp(),
        ])

        try await logActivity("task_retried", details: [
            "task_num_id": "\(task.numId)",
            "project": task.project,
        ])
    }

    func updateTaskStatus(_ task: CommanderTask, status: TaskStatus) async throws {
        let q = db.collection("commander_tasks")
            .whereField("num_id", isEqualTo: task.numId)
            .limit(to: 1)
        let snap = try await q.getDocuments()
        guard let doc = snap.documents.first else { return }

        try await doc.reference.updateData([
            "status": status.rawValue,
            "updated_at": FieldValue.serverTimestamp(),
        ])
    }

    func approveTask(_ task: CommanderTask) async throws {
        let q = db.collection("commander_tasks")
            .whereField("num_id", isEqualTo: task.numId)
            .limit(to: 1)
        let snap = try await q.getDocuments()
        guard let doc = snap.documents.first else { return }

        try await doc.reference.updateData([
            "review_status": "approved",
            "updated_at": FieldValue.serverTimestamp(),
        ])

        try await logActivity("task_approved", details: [
            "task_num_id": "\(task.numId)",
            "project": task.project,
        ])
    }

    func requestChanges(_ task: CommanderTask) async throws {
        let q = db.collection("commander_tasks")
            .whereField("num_id", isEqualTo: task.numId)
            .limit(to: 1)
        let snap = try await q.getDocuments()
        guard let doc = snap.documents.first else { return }

        try await doc.reference.updateData([
            "review_status": "changes_requested",
            "updated_at": FieldValue.serverTimestamp(),
        ])

        try await logActivity("task_changes_requested", details: [
            "task_num_id": "\(task.numId)",
            "project": task.project,
        ])
    }

    func deleteTask(_ task: CommanderTask) async throws {
        let q = db.collection("commander_tasks")
            .whereField("num_id", isEqualTo: task.numId)
            .limit(to: 1)
        let snap = try await q.getDocuments()
        guard let doc = snap.documents.first else { return }

        try await doc.reference.delete()

        try await logActivity("task_deleted", details: [
            "task_num_id": "\(task.numId)",
            "project": task.project,
            "task_name": task.task,
        ])
    }

    func sendChatMessage(taskId: String, content: String) async throws {
        let data: [String: Any] = [
            "role": "user",
            "content": content,
            "timestamp": FieldValue.serverTimestamp(),
            "sender_email": currentUser?.email ?? "unknown",
            "sender_name": currentUser?.displayName ?? "User",
            "is_pending": true,
        ]

        try await db.collection("commander_tasks")
            .document(taskId)
            .collection("chat")
            .addDocument(data: data)

        try await logActivity("chat_message_sent", details: [
            "task_id": taskId,
            "message_preview": String(content.prefix(50)),
        ])
    }

    func listenToOutput(taskId: String, onChange: @escaping ([OutputChunk]) -> Void) -> ListenerRegistration {
        let q = db.collection("commander_tasks")
            .document(taskId)
            .collection("output")
            .order(by: "order")
        return q.addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let chunks = docs.compactMap { Self.decodeOutputChunk($0) }
            onChange(chunks)
        }
    }

    func listenToChat(taskId: String, onChange: @escaping ([ChatMessage]) -> Void) -> ListenerRegistration {
        let q = db.collection("commander_tasks")
            .document(taskId)
            .collection("chat")
            .order(by: "timestamp")
        return q.addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let messages = docs.compactMap { Self.decodeChatMessage($0) }
            onChange(messages)
        }
    }

    // MARK: - Activity

    private func logActivity(_ action: String, details: [String: String]) async throws {
        let data: [String: Any] = [
            "action": action,
            "details": details,
            "user_email": currentUser?.email ?? "unknown",
            "user_name": currentUser?.displayName ?? "User",
            "timestamp": FieldValue.serverTimestamp(),
        ]
        try await db.collection("commander_activity").addDocument(data: data)
    }

    // MARK: - Decoders

    private static func decodeTask(_ doc: QueryDocumentSnapshot) -> CommanderTask? {
        let d = doc.data()
        guard let numId = d["num_id"] as? Int else { return nil }
        return CommanderTask(
            id: doc.documentID,
            numId: numId,
            project: d["project"] as? String ?? "",
            path: d["path"] as? String ?? "",
            task: d["task"] as? String ?? "",
            description: d["description"] as? String ?? "",
            dependsOn: d["depends_on"] as? [Int] ?? [],
            status: TaskStatus(rawValue: d["status"] as? String ?? "pending") ?? .pending,
            priority: d["priority"] as? Int ?? 10,
            assignedWorker: d["assigned_worker"] as? String,
            claimedBy: d["claimed_by"] as? String,
            costUsd: d["cost_usd"] as? Double,
            durationMs: d["duration_ms"] as? Int,
            exitCode: d["exit_code"] as? Int,
            error: d["error"] as? String,
            sessionId: d["session_id"] as? String,
            reviewStatus: ReviewStatus(rawValue: d["review_status"] as? String ?? "") ?? .none,
            testStatus: d["test_status"] as? String,
            deployStatus: d["deploy_status"] as? String,
            followUp: d["follow_up"] as? String,
            createdAt: (d["created_at"] as? Timestamp)?.dateValue(),
            startedAt: (d["started_at"] as? Timestamp)?.dateValue(),
            completedAt: (d["completed_at"] as? Timestamp)?.dateValue()
        )
    }

    private static func decodeWorker(_ doc: QueryDocumentSnapshot) -> CommanderWorker? {
        let d = doc.data()
        return CommanderWorker(
            id: doc.documentID,
            hostname: d["hostname"] as? String ?? doc.documentID,
            status: WorkerStatus(rawValue: d["status"] as? String ?? "offline") ?? .offline,
            activeTaskCount: d["active_task_count"] as? Int ?? 0,
            completedTasks: d["completed_tasks"] as? Int ?? 0,
            maxParallel: d["max_parallel"] as? Int ?? 4,
            lastHeartbeat: (d["last_heartbeat"] as? Timestamp)?.dateValue(),
            plan: d["plan"] as? String,
            quotaRemaining: d["quota_remaining"] as? Double,
            rateLimitResetAt: (d["rate_limit_reset_at"] as? Timestamp)?.dateValue(),
            isRateLimited: d["is_rate_limited"] as? Bool ?? false
        )
    }

    private static func decodeOutputChunk(_ doc: QueryDocumentSnapshot) -> OutputChunk? {
        let d = doc.data()
        return OutputChunk(
            id: doc.documentID,
            type: OutputType(rawValue: d["type"] as? String ?? "assistant") ?? .assistant,
            content: d["content"] as? String ?? "",
            timestamp: (d["timestamp"] as? Timestamp)?.dateValue(),
            order: d["order"] as? Int ?? 0
        )
    }

    private static func decodeChatMessage(_ doc: QueryDocumentSnapshot) -> ChatMessage? {
        let d = doc.data()
        return ChatMessage(
            id: doc.documentID,
            role: ChatRole(rawValue: d["role"] as? String ?? "user") ?? .user,
            content: d["content"] as? String ?? "",
            timestamp: (d["timestamp"] as? Timestamp)?.dateValue(),
            senderName: d["sender_name"] as? String,
            isPending: d["is_pending"] as? Bool ?? false
        )
    }

    private static func decodeActivity(_ doc: QueryDocumentSnapshot) -> ActivityEvent? {
        let d = doc.data()
        let details = d["details"] as? [String: String] ?? [:]
        return ActivityEvent(
            id: doc.documentID,
            action: d["action"] as? String ?? "",
            details: details,
            userEmail: d["user_email"] as? String,
            userName: d["user_name"] as? String,
            timestamp: (d["timestamp"] as? Timestamp)?.dateValue()
        )
    }
}

// MARK: - Computed Helpers

extension DataStore {
    var taskCounts: [TaskStatus: Int] {
        var counts: [TaskStatus: Int] = [:]
        for status in TaskStatus.allCases {
            counts[status] = 0
        }
        for task in tasks {
            counts[task.effectiveStatus, default: 0] += 1
        }
        return counts
    }

    var totalCost: Double {
        tasks.reduce(0) { $0 + ($1.costUsd ?? 0) }
    }

    var projectNames: [String] {
        Array(Set(tasks.map { $0.project })).sorted()
    }

    func tasks(for project: String) -> [CommanderTask] {
        tasks.filter { $0.project == project }
    }

    func projectProgress(_ project: String) -> (done: Int, total: Int) {
        let projectTasks = tasks(for: project)
        let done = projectTasks.filter { $0.status == .done }.count
        return (done, projectTasks.count)
    }
}
