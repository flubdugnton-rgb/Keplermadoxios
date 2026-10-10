import SwiftUI

struct NotesView: View {
    @EnvironmentObject private var store: NotesStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85

    @State private var query = ""
    @State private var selectedTag: UUID?
    @State private var editing: StudyNote?
    @State private var showNew = false
    @State private var showTag = false

    private var intensity: Double {
        Double(glassIntensityPercent) / 100
    }

    private var visible: [StudyNote] {
        store.visible(tagID: selectedTag, query: query)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Notas")
                                    .font(.largeTitle.bold())

                                Text("Resumos, macetes e lembretes.")
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                showTag = true
                            } label: {
                                Image(systemName: "folder.badge.plus")
                            }
                            .buttonStyle(.bordered)
                        }

                        TextField("Buscar nas notas", text: $query)
                            .textFieldStyle(.roundedBorder)

                        ScrollView(.horizontal) {
                            HStack {
                                NoteFilterChip(
                                    title: "Todas",
                                    selected: selectedTag == nil
                                ) {
                                    selectedTag = nil
                                }

                                ForEach(store.tags) { tag in
                                    NoteFilterChip(
                                        title: "#\(tag.name)",
                                        selected: selectedTag == tag.id
                                    ) {
                                        selectedTag = tag.id
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)

                        Button {
                            showNew = true
                        } label: {
                            Label("Nova nota", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        if visible.isEmpty {
                            ContentUnavailableView(
                                "Nenhuma anotação",
                                systemImage: "note.text",
                                description: Text(
                                    query.isEmpty
                                    ? "Crie sua primeira anotação."
                                    : "Tente outro termo ou bloco."
                                )
                            )
                            .padding(.top, 50)
                        } else {
                            ForEach(visible) { note in
                                Button {
                                    editing = note
                                } label: {
                                    NoteCard(
                                        note: note,
                                        tag: store.tags.first(where: { $0.id == note.tagID }),
                                        intensity: intensity
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 96)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showNew) {
            NoteEditorView(note: nil)
        }
        .sheet(item: $editing) { note in
            NoteEditorView(note: note)
        }
        .sheet(isPresented: $showTag) {
            CreateNoteTagSheet()
        }
    }
}

private struct NoteFilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(selected ? Color.accentColor : Color.secondary)
    }
}

private struct NoteCard: View {
    let note: StudyNote
    let tag: NoteTag?
    let intensity: Double

    private let tones: [Color] = [.yellow, .mint, .cyan, .purple, .orange]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(note.title.isEmpty ? "Sem título" : note.title)
                    .font(.headline)

                Spacer()

                if let tag {
                    Text("#\(tag.name)")
                        .font(.caption.weight(.semibold))
                }
            }

            Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)

            if !note.body.isEmpty {
                Text(note.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            tones[note.tone % tones.count].opacity(0.09),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .kepleraeGlass(
            intensity: intensity,
            cornerRadius: 24,
            interactive: true
        )
    }
}

private struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: NotesStore

    let note: StudyNote?

    @State private var title = ""
    @State private var noteText = ""
    @State private var tagID: UUID?
    @State private var tone = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Título", text: $title)

                    TextEditor(text: $noteText)
                        .frame(minHeight: 220)
                }

                Section("Bloco") {
                    Picker("Bloco", selection: $tagID) {
                        Text("Sem bloco")
                            .tag(Optional<UUID>.none)

                        ForEach(store.tags) { tag in
                            Text("#\(tag.name)")
                                .tag(Optional(tag.id))
                        }
                    }
                }

                Section("Cor") {
                    Picker("Cor", selection: $tone) {
                        ForEach(0..<5, id: \.self) {
                            Text("Cor \($0 + 1)")
                                .tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if note != nil {
                    Section {
                        Button("Excluir nota", role: .destructive) {
                            if let note {
                                store.delete(note.id)
                            }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(note == nil ? "Nova nota" : "Editar nota")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        save()
                    }
                    .disabled(
                        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                        noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
            .onAppear {
                if let note {
                    title = note.title
                    noteText = note.body
                    tagID = note.tagID
                    tone = note.tone
                }
            }
        }
    }

    private func save() {
        let now = Date()

        let value = StudyNote(
            id: note?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: noteText,
            tagID: tagID,
            tone: tone,
            createdAt: note?.createdAt ?? now,
            updatedAt: now
        )

        store.upsert(value)
        dismiss()
    }
}

private struct CreateNoteTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: NotesStore

    @State private var name = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Novo bloco") {
                    TextField("Nome", text: $name)

                    if let error {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Bloco de notas")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Criar") {
                        do {
                            _ = try store.createTag(name)
                            dismiss()
                        } catch {
                            self.error = error.localizedDescription
                        }
                    }
                }
            }
        }
    }
}
