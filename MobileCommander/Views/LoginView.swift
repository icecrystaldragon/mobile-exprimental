import SwiftUI

struct LoginView: View {
    @EnvironmentObject var store: DataStore
    @State private var isSigningIn = false
    @State private var error: String?

    var body: some View {
        ZStack {
            Color.commanderBg.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.commanderOrange.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.commanderOrange)
                    }

                    Text("Commander")
                        .font(.commanderTitle)
                        .foregroundColor(.commanderText)

                    Text("AI Task Execution Platform")
                        .font(.commanderCaption)
                        .foregroundColor(.commanderSecondary)
                }

                Spacer()

                // Sign in button
                VStack(spacing: 16) {
                    if let error = error {
                        Text(error)
                            .font(.commanderCaption)
                            .foregroundColor(.commanderRed)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.commanderRedDim)
                            .cornerRadius(8)
                    }

                    Button {
                        signIn()
                    } label: {
                        HStack(spacing: 12) {
                            if isSigningIn {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 20))
                            }
                            Text(isSigningIn ? "Signing in..." : "Sign in with Google")
                                .font(.commanderSubhead)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.commanderOrange)
                        .cornerRadius(12)
                    }
                    .disabled(isSigningIn)
                    .opacity(isSigningIn ? 0.7 : 1)
                }
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 60)
            }
        }
    }

    private func signIn() {
        isSigningIn = true
        error = nil
        Task {
            do {
                try await store.signInWithGoogle()
            } catch {
                self.error = error.localizedDescription
            }
            isSigningIn = false
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(DataStore.shared)
}
