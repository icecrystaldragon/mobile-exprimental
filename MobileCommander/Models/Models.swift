import SwiftUI

// MARK: - App Mode

enum AppMode: String, CaseIterable {
    case developer = "Developer"
    case owner = "Owner"

    var description: String {
        switch self {
        case .developer: return "Full control over tasks, workers, and activity"
        case .owner: return "Create tasks and track progress"
        }
    }

    var icon: String {
        switch self {
        case .developer: return "terminal"
        case .owner: return "person.crop.circle"
        }
    }
}

// MARK: - Task Status

enum TaskStatus: String, CaseIterable, Codable {
    case pending
    case claimed
    case running
    case done
    case failed
    case blocked
    case needsReview = "needs_review"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .claimed: return "Claimed"
        case .running: return "Running"
        case .done: return "Done"
        case .failed: return "Failed"
        case .blocked: return "Blocked"
        case .needsReview: return "Needs Review"
        }
    }

    var color: Color {
        switch self {
        case .pending, .claimed: return .commanderSecondary
        case .running: return .commanderAmber
        case .done: return .commanderGreen
        case .failed: return .commanderRed
        case .blocked: return .commanderOrange
        case .needsReview: return .commanderPurple
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .claimed: return "hand.raised"
        case .running: return "play.circle.fill"
        case .done: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .blocked: return "exclamationmark.triangle.fill"
        case .needsReview: return "eye.circle.fill"
        }
    }
}

// MARK: - Review Status

enum ReviewStatus: String, CaseIterable, Codable {
    case none = ""
    case needsReview = "needs_review"
    case approved
    case changesRequested = "changes_requested"

    var displayName: String {
        switch self {
        case .none: return "—"
        case .needsReview: return "Needs Review"
        case .approved: return "Approved"
        case .changesRequested: return "Changes Requested"
        }
    }
}

// MARK: - Commander Task

struct CommanderTask: Identifiable, Codable {
    var id: String
    var numId: Int
    var project: String
    var path: String
    var task: String
    var description: String
    var dependsOn: [Int]
    var status: TaskStatus
    var priority: Int
    var assignedWorker: String?
    var claimedBy: String?
    var costUsd: Double?
    var durationMs: Int?
    var exitCode: Int?
    var error: String?
    var sessionId: String?
    var reviewStatus: ReviewStatus
    var testStatus: String?
    var deployStatus: String?
    var followUp: String?
    var createdAt: Date?
    var startedAt: Date?
    var completedAt: Date?

    var effectiveStatus: TaskStatus {
        if reviewStatus == .needsReview && status == .done {
            return .needsReview
        }
        return status
    }

    var durationString: String? {
        guard let ms = durationMs else { return nil }
        let totalSeconds = ms / 1000
        if totalSeconds < 60 { return "\(totalSeconds)s" }
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes < 60 { return "\(minutes)m \(seconds)s" }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }

    var costString: String? {
        guard let cost = costUsd, cost > 0 else { return nil }
        return String(format: "$%.2f", cost)
    }
}

// MARK: - Commander Worker

struct CommanderWorker: Identifiable, Codable {
    var id: String
    var hostname: String
    var status: WorkerStatus
    var activeTaskCount: Int
    var completedTasks: Int
    var maxParallel: Int
    var lastHeartbeat: Date?
    var plan: String?
    var quotaRemaining: Double?
    var rateLimitResetAt: Date?
    var isRateLimited: Bool

    var isOnline: Bool {
        guard let hb = lastHeartbeat else { return false }
        return Date().timeIntervalSince(hb) < 120
    }
}

enum WorkerStatus: String, Codable {
    case busy
    case online
    case offline

    var color: Color {
        switch self {
        case .busy: return .commanderAmber
        case .online: return .commanderGreen
        case .offline: return .commanderSecondary
        }
    }

    var icon: String {
        switch self {
        case .busy: return "bolt.fill"
        case .online: return "checkmark.circle.fill"
        case .offline: return "moon.fill"
        }
    }
}

// MARK: - Output Chunk

struct OutputChunk: Identifiable, Codable {
    var id: String
    var type: OutputType
    var content: String
    var timestamp: Date?
    var order: Int
}

enum OutputType: String, Codable {
    case assistant
    case toolUse = "tool_use"
    case toolResult = "tool_result"
    case system
}

// MARK: - Chat Message

struct ChatMessage: Identifiable, Codable {
    var id: String
    var role: ChatRole
    var content: String
    var timestamp: Date?
    var senderName: String?
    var isPending: Bool
}

enum ChatRole: String, Codable {
    case user
    case assistant
}

// MARK: - Activity Event

struct ActivityEvent: Identifiable, Codable {
    var id: String
    var action: String
    var details: [String: String]
    var userEmail: String?
    var userName: String?
    var timestamp: Date?

    var icon: String {
        switch action {
        case "task_created": return "plus.circle.fill"
        case "task_retried": return "arrow.clockwise.circle.fill"
        case "chat_message_sent": return "bubble.left.fill"
        case "task_status_changed": return "arrow.triangle.2.circlepath"
        case "task_deleted": return "trash.fill"
        case "task_approved": return "checkmark.seal.fill"
        case "task_changes_requested": return "arrow.uturn.backward.circle.fill"
        default: return "circle.fill"
        }
    }

    var color: Color {
        switch action {
        case "task_created": return .commanderGreen
        case "task_retried": return .commanderAmber
        case "chat_message_sent": return .commanderPurple
        case "task_status_changed": return .commanderOrange
        case "task_deleted": return .commanderRed
        case "task_approved": return .commanderGreen
        case "task_changes_requested": return .commanderAmber
        default: return .commanderSecondary
        }
    }

    var displayAction: String {
        action.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - New Task Form

struct NewTaskForm {
    var project: String = ""
    var path: String = ""
    var task: String = ""
    var description: String = ""
    var dependsOn: String = ""
    var priority: Int = 10
    var assignedWorker: String = ""
}
