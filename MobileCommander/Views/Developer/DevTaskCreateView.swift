import SwiftUI

struct DevTaskCreateView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var form = NewTaskForm()
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if showSuccess {
                        successBanner
                    }

                    if let error = errorMessage {
                        errorBanner(error)
                    }

                    formFields
                    submitButton
                }
                .padding(16)
            }
            .background(Color.commanderBg)
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.commanderSecondary)
                }
            }
        }
    }

    // MARK: - Form Fields

    private var formFields: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                FormField(label: "Project", text: $form.project, placeholder: "e.g. everbnb")
                FormField(label: "Working Directory", text: $form.path, placeholder: "e.g. ~/repos/everbnb")
            }

            FormField(label: "Task Name", text: $form.task, placeholder: "Short task name")

            VStack(alignment: .leading, spacing: 4) {
                Text("Description")
                    .font(.commanderCaption)
                    .foregroundColor(.commanderSecondary)
                TextEditor(text: $form.description)
                    .font(.commanderBody)
                    .foregroundColor(.commanderText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(10)
                    .background(Color.commanderSurface)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.commanderBorder, lineWidth: 0.5)
                    )
            }

            HStack(spacing: 12) {
                FormField(label: "Depends On (IDs)", text: $form.dependsOn, placeholder: "e.g. 1,3")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Priority")
                        .font(.commanderCaption)
                        .foregroundColor(.commanderSecondary)
                    Stepper(value: $form.priority, in: 1...100) {
                        Text("\(form.priority)")
                            .font(.commanderBody)
                            .foregroundColor(.commanderText)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.commanderSurface)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.commanderBorder, lineWidth: 0.5)
                            )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Assign Worker")
                    .font(.commanderCaption)
                    .foregroundColor(.commanderSecondary)

                if store.workers.isEmpty {
                    FormField(label: "", text: $form.assignedWorker, placeholder: "Worker ID (optional)")
                } else {
                    Picker("Worker", selection: $form.assignedWorker) {
                        Text("Any worker").tag("")
                        ForEach(store.workers) { worker in
                            Text(worker.hostname).tag(worker.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.commanderOrange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.commanderSurface)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.commanderBorder, lineWidth: 0.5)
                    )
                }
            }
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "plus.circle.fill")
                }
                Text(isSubmitting ? "Creating..." : "Create Task")
                    .font(.commanderSubhead)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(canSubmit ? Color.commanderOrange : Color.commanderMuted)
            .cornerRadius(12)
        }
        .disabled(!canSubmit || isSubmitting)
    }

    private var canSubmit: Bool {
        !form.project.trimmingCharacters(in: .whitespaces).isEmpty &&
        !form.path.trimmingCharacters(in: .whitespaces).isEmpty &&
        !form.task.trimmingCharacters(in: .whitespaces).isEmpty &&
        !form.description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Banners

    private var successBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.commanderGreen)
            Text("Task created successfully!")
                .font(.commanderCaption)
                .foregroundColor(.commanderGreen)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.commanderGreenDim)
        .cornerRadius(10)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.commanderRed)
            Text(message)
                .font(.commanderCaption)
                .foregroundColor(.commanderRed)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.commanderRedDim)
        .cornerRadius(10)
    }

    // MARK: - Actions

    private func submit() {
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                try await store.createTask(form)
                showSuccess = true
                form = NewTaskForm()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showSuccess = false
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

// MARK: - Form Field

struct FormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !label.isEmpty {
                Text(label)
                    .font(.commanderCaption)
                    .foregroundColor(.commanderSecondary)
            }
            TextField(placeholder, text: $text)
                .font(.commanderBody)
                .foregroundColor(.commanderText)
                .padding(10)
                .background(Color.commanderSurface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.commanderBorder, lineWidth: 0.5)
                )
        }
    }
}

#Preview {
    DevTaskCreateView()
        .environmentObject(DataStore.shared)
}
