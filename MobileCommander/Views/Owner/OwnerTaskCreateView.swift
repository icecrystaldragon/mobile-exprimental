import SwiftUI

struct OwnerTaskCreateView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedProject = ""
    @State private var taskDescription = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    if showSuccess {
                        successView
                    } else {
                        formContent
                    }
                }
                .padding(16)
            }
            .background(Color.commanderBg)
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("New Task")
                .font(.commanderTitle)
                .foregroundColor(.commanderText)
            Text("Describe what you need done and we'll take care of it.")
                .font(.commanderCaption)
                .foregroundColor(.commanderSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Form

    private var formContent: some View {
        VStack(spacing: 20) {
            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.commanderRed)
                    Text(error)
                        .font(.commanderCaption)
                        .foregroundColor(.commanderRed)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.commanderRedDim)
                .cornerRadius(10)
            }

            // Project Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Project")
                    .font(.commanderSubhead)
                    .foregroundColor(.commanderText)
                Text("Which project is this for?")
                    .font(.commanderCaption)
                    .foregroundColor(.commanderSecondary)

                if store.projectNames.isEmpty {
                    TextField("Project name", text: $selectedProject)
                        .font(.commanderBody)
                        .foregroundColor(.commanderText)
                        .padding(14)
                        .background(Color.commanderSurface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.commanderBorder, lineWidth: 0.5)
                        )
                } else {
                    VStack(spacing: 6) {
                        ForEach(store.projectNames, id: \.self) { project in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedProject = project
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.commanderOrange)
                                    Text(project)
                                        .font(.commanderBody)
                                        .foregroundColor(.commanderText)
                                    Spacer()
                                    if selectedProject == project {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.commanderOrange)
                                    }
                                }
                                .padding(14)
                                .background(selectedProject == project ? Color.commanderOrangeDim : Color.commanderSurface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            selectedProject == project ? Color.commanderOrange.opacity(0.4) : Color.commanderBorder,
                                            lineWidth: 0.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Custom project option
                        TextField("Or type a new project name", text: $selectedProject)
                            .font(.commanderBody)
                            .foregroundColor(.commanderText)
                            .padding(14)
                            .background(Color.commanderSurface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.commanderBorder, lineWidth: 0.5)
                            )
                    }
                }
            }

            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("What do you need?")
                    .font(.commanderSubhead)
                    .foregroundColor(.commanderText)
                Text("Be specific about what you want changed or added.")
                    .font(.commanderCaption)
                    .foregroundColor(.commanderSecondary)

                TextEditor(text: $taskDescription)
                    .font(.commanderBody)
                    .foregroundColor(.commanderText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .padding(14)
                    .background(Color.commanderSurface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.commanderBorder, lineWidth: 0.5)
                    )

                Text("Examples: \"Fix the class booking timezone bug\" or \"Add a member check-in screen with QR code support\"")
                    .font(.commanderSmall)
                    .foregroundColor(.commanderMuted)
                    .italic()
            }

            // Submit
            Button {
                submit()
            } label: {
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text(isSubmitting ? "Sending..." : "Submit Task")
                        .font(.commanderSubhead)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSubmit ? Color.commanderOrange : Color.commanderMuted)
                .cornerRadius(14)
            }
            .disabled(!canSubmit || isSubmitting)
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 40)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.commanderGreen)

            Text("Task Submitted!")
                .font(.commanderHeadline)
                .foregroundColor(.commanderText)

            Text("Your task has been added to the queue. A worker will pick it up shortly.")
                .font(.commanderBody)
                .foregroundColor(.commanderSecondary)
                .multilineTextAlignment(.center)

            Button {
                showSuccess = false
                selectedProject = ""
                taskDescription = ""
            } label: {
                Text("Create Another")
                    .font(.commanderSubhead)
                    .foregroundColor(.commanderOrange)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.commanderOrangeDim)
                    .cornerRadius(10)
            }
        }
    }

    // MARK: - Logic

    private var canSubmit: Bool {
        !selectedProject.trimmingCharacters(in: .whitespaces).isEmpty &&
        !taskDescription.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submit() {
        isSubmitting = true
        errorMessage = nil

        let description = taskDescription.trimmingCharacters(in: .whitespaces)
        let taskName = String(description.prefix(60))

        let form = NewTaskForm(
            project: selectedProject.trimmingCharacters(in: .whitespaces),
            path: "~/repos/\(selectedProject.trimmingCharacters(in: .whitespaces))",
            task: taskName,
            description: description,
            dependsOn: "",
            priority: 10,
            assignedWorker: ""
        )

        Task {
            do {
                try await store.createTask(form)
                withAnimation {
                    showSuccess = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

#Preview {
    OwnerTaskCreateView()
        .environmentObject(DataStore.shared)
}
