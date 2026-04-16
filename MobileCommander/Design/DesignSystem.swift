import SwiftUI

// MARK: - Colors

extension Color {
    static let commanderBg = Color(red: 0.039, green: 0.039, blue: 0.059)          // #0a0a0f
    static let commanderSurface = Color(red: 0.067, green: 0.071, blue: 0.106)     // #111218 — gray-900
    static let commanderCard = Color(red: 0.098, green: 0.102, blue: 0.141)        // #191a24
    static let commanderText = Color.white
    static let commanderSecondary = Color(red: 0.612, green: 0.639, blue: 0.686)   // #9ca3af — gray-400
    static let commanderMuted = Color(red: 0.42, green: 0.45, blue: 0.49)          // gray-500
    static let commanderOrange = Color(red: 0.976, green: 0.451, blue: 0.086)      // #f97316 — orange-500
    static let commanderOrangeDim = Color(red: 0.976, green: 0.451, blue: 0.086).opacity(0.15)
    static let commanderGreen = Color(red: 0.063, green: 0.725, blue: 0.506)       // #10b981 — emerald-500
    static let commanderGreenDim = Color(red: 0.063, green: 0.725, blue: 0.506).opacity(0.15)
    static let commanderRed = Color(red: 0.937, green: 0.267, blue: 0.267)         // #ef4444
    static let commanderRedDim = Color(red: 0.937, green: 0.267, blue: 0.267).opacity(0.15)
    static let commanderAmber = Color(red: 0.961, green: 0.620, blue: 0.043)       // #f59e0b
    static let commanderAmberDim = Color(red: 0.961, green: 0.620, blue: 0.043).opacity(0.15)
    static let commanderPurple = Color(red: 0.659, green: 0.333, blue: 0.969)      // #a855f7
    static let commanderPurpleDim = Color(red: 0.659, green: 0.333, blue: 0.969).opacity(0.15)
    static let commanderBorder = Color(red: 0.216, green: 0.255, blue: 0.318)      // #374151 — gray-700
}

// MARK: - Typography

extension Font {
    static let commanderTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let commanderHeadline = Font.system(size: 20, weight: .semibold, design: .default)
    static let commanderSubhead = Font.system(size: 15, weight: .medium, design: .default)
    static let commanderBody = Font.system(size: 15, weight: .regular, design: .default)
    static let commanderCaption = Font.system(size: 13, weight: .regular, design: .default)
    static let commanderCaptionMedium = Font.system(size: 13, weight: .medium, design: .default)
    static let commanderSmall = Font.system(size: 11, weight: .medium, design: .default)
    static let commanderMono = Font.system(size: 13, weight: .regular, design: .monospaced)
    static let commanderMonoSmall = Font.system(size: 11, weight: .regular, design: .monospaced)
}

// MARK: - Card Components

struct CommanderCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .background(Color.commanderSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.commanderBorder, lineWidth: 0.5)
        )
    }
}

struct CommanderAccentCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .background(Color.commanderSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.commanderOrange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: TaskStatus

    var body: some View {
        Text(status.displayName)
            .font(.commanderSmall)
            .foregroundColor(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.color.opacity(0.15))
            .cornerRadius(6)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let label: String
    let value: Int
    let color: Color
    var isSelected: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.commanderSmall)
                    .foregroundColor(.commanderSecondary)
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.commanderSurface.opacity(0.6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.commanderOrange.opacity(0.6) : Color.commanderBorder,
                        lineWidth: isSelected ? 1 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress Bar

struct CommanderProgressBar: View {
    let done: Int
    let total: Int
    var label: String = "Progress"

    private var fraction: Double {
        total > 0 ? Double(done) / Double(total) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderSecondary)
                Spacer()
                Text("\(done)/\(total)")
                    .font(.commanderCaptionMedium)
                    .foregroundColor(.commanderSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.commanderBorder.opacity(0.3))
                        .frame(height: 6)
                    Capsule()
                        .fill(Color.commanderGreen)
                        .frame(width: geo.size.width * fraction, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Live Dot

struct LiveDot: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.commanderGreen.opacity(0.4))
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 2 : 1)
                .opacity(isAnimating ? 0 : 0.75)
            Circle()
                .fill(Color.commanderGreen)
                .frame(width: 8, height: 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.commanderMuted)
            Text(title)
                .font(.commanderSubhead)
                .foregroundColor(.commanderText)
            Text(subtitle)
                .font(.commanderCaption)
                .foregroundColor(.commanderSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Date Extensions

extension Date {
    var commanderTimeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: self).lowercased()
    }

    var commanderRelative: String {
        let seconds = Int(-self.timeIntervalSinceNow)
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }

    var commanderDateString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f.string(from: self)
    }
}
