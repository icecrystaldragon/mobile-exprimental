import SwiftUI

struct OwnerTaskCreateView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedProject = ""
    @State private var taskDescription = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private let quickTemplates = [
        ("Fix a bug", "bug.fill", "There's a bug where [describe what's broken]. It should [describe expected behavior] instead."),
        ("Add a feature", "plus.rectangle.fill", "I'd like to add [describe the feature]. It should [describe how it works]."),
        ("Update content", "doc.text.fill", "Update the [page/section] to say [new content]. Currently it says [old content]."),
        ("Improve design", "paintbrush.fill", "The [page/component] needs visual improvements: [describe what to change]."),
    ]

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
            Text("Describe what you need done and a worker will handle it.")
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

            projectPicker
            templateSection
            descriptionField
            submitButton
        }
    }

    // MARK: - Project Picker

    private var projectPicker: some View {
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.projectNames, id: \.self) { project in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedProject = selectedProject == project ? "" : project
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 12))
                                    Text(project)
                                        .font(.commanderCaptionMedium)
                                }
                                .foregroundColor(selectedProject == project ? .white : .commanderSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(selectedProject == project ? Color.commanderOrange : Color.commanderSurface)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            selectedProject == project ? Color.commanderOrange : Color.commanderBorder,
                                            lineWidth: 0.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

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

    // MARK: - Quick Templates

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What kind of task?")
                .font(.commanderSubhead)
                .foregroundColor(.commanderText)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
            ], spacing: 8) {
                ForEach(quickTemplates, id: \.0) { template in
                    Button {
                        if taskDescription.isEmpty {
                            taskDescription = template.2
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: template.1)
                                .font(.system(size: 14))
                                .foregroundColor(.commanderOrange)
                            Text(template.0)
                                .font(.commanderCaptionMedium)
                                .foregroundColor(.commanderText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.commanderSurface)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.commanderBorder, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Description

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Describe what you need")
                .font(.commanderSubhead)
                .foregroundColor(.commanderText)
            Text("Be specific — the more detail, the better the result.")
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

            HStack(spacing: 4) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.commanderAmber)
                Text("Tip: Include what you expect to see when it's done")
                    .font(.commanderSmall)
                    .foregroundColor(.commanderMuted)
            }
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
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

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 40)

            ZStack {
                Circle()
                    .fill(Color.commanderGreenDim)
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.commanderGreen)
            }

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
