import SwiftUI

struct QuestionsView: View {
    @EnvironmentObject private var store: QuestionsStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    @State private var selectedSubject: UUID?
    @State private var showCreate = false
    @State private var showAdd = false
    private var intensity: Double { Double(glassIntensityPercent) / 100 }
    private var filteredRecords: [QuestionRecord] { store.records.filter { selectedSubject == nil || $0.subjectID == selectedSubject } }
    private var totals: (correct: Int, wrong: Int, total: Int, accuracy: Double) { store.totals(subjectID: selectedSubject) }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Questões").font(.largeTitle.bold())
                                Text("Registre acertos e erros para acompanhar sua evolução.").foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button { showCreate = true } label: { Image(systemName: "folder.badge.plus") }.buttonStyle(.bordered)
                        }

                        ScrollView(.horizontal) {
                            HStack {
                                FilterChip(title: "Geral", selected: selectedSubject == nil) { selectedSubject = nil }
                                ForEach(store.subjects) { subject in FilterChip(title: subject.name, selected: selectedSubject == subject.id) { selectedSubject = subject.id } }
                            }
                        }.scrollIndicators(.hidden)

                        HStack(spacing: 10) {
                            MetricCard(title: "Questões", value: totals.total, intensity: intensity)
                            MetricCard(title: "Acertos", value: totals.correct, intensity: intensity)
                            MetricCard(title: "Erros", value: totals.wrong, intensity: intensity)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Taxa de acerto").font(.subheadline).foregroundStyle(.secondary)
                            Text(totals.total == 0 ? "—" : String(format: "%.1f%%", totals.accuracy)).font(.system(size: 34, weight: .bold, design: .rounded))
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(20).kepleraeGlass(intensity: intensity, cornerRadius: 24, interactive: false)

                        Button {
                            if store.subjects.isEmpty { showCreate = true } else { showAdd = true }
                        } label: {
                            Label("Registrar e calcular", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
                        }.buttonStyle(.borderedProminent).controlSize(.large)

                        Text("Histórico").font(.title2.bold())
                        if filteredRecords.isEmpty {
                            ContentUnavailableView("Sem registros", systemImage: "chart.line.uptrend.xyaxis", description: Text("Adicione uma matéria e registre sua primeira sessão."))
                        } else {
                            ForEach(filteredRecords.sorted(by: { $0.recordedAt > $1.recordedAt })) { record in
                                QuestionHistoryRow(record: record, subject: store.subjects.first(where: { $0.id == record.subjectID }), onDelete: { store.deleteRecord(record.id) }, intensity: intensity)
                            }
                        }
                    }.padding(20)
                }
            }.toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showCreate) { CreateQuestionSubjectSheet { id in selectedSubject = id; showCreate = false } }
        .sheet(isPresented: $showAdd) { AddQuestionRecordSheet(initialSubject: selectedSubject) }
    }
}

private struct FilterChip: View {
    let title: String; let selected: Bool; let action: () -> Void
    var body: some View { Button(action: action) { Text(title).font(.subheadline.weight(.medium)).padding(.horizontal, 12).padding(.vertical, 8).background(selected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08), in: Capsule()) }.buttonStyle(.plain) }
}

private struct MetricCard: View {
    let title: String; let value: Int; let intensity: Double
    var body: some View { VStack(alignment: .leading, spacing: 4) { Text(title).font(.caption).foregroundStyle(.secondary); Text("\(value)").font(.title2.bold()) }.frame(maxWidth: .infinity, alignment: .leading).padding(14).kepleraeGlass(intensity: intensity, cornerRadius: 20, interactive: false) }
}

private struct QuestionHistoryRow: View {
    let record: QuestionRecord; let subject: QuestionSubject?; let onDelete: () -> Void; let intensity: Double
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(subject?.name ?? "Matéria").font(.headline)
                Text(record.recordedAt.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary)
                Text("\(record.correct) acertos • \(record.wrong) erros • \(String(format: "%.1f%%", record.accuracy))")
                    .font(.subheadline)
            }
            Spacer(); Button(role: .destructive, action: onDelete) { Image(systemName: "trash") }.buttonStyle(.plain)
        }.padding(17).kepleraeGlass(intensity: intensity, cornerRadius: 22, interactive: false)
    }
}

private struct CreateQuestionSubjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: QuestionsStore
    @State private var name = ""; @State private var error: String?
    let onCreated: (UUID) -> Void
    var body: some View {
        NavigationStack {
            Form { Section("Nova matéria") { TextField("Nome do bloco", text: $name); if let error { Text(error).foregroundStyle(.red) } } }
                .navigationTitle("Criar bloco")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Criar") { do { onCreated(try store.createSubject(name)); dismiss() } catch { self.error = error.localizedDescription } } } }
        }
    }
}

private struct AddQuestionRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: QuestionsStore
    @State private var selected: UUID?; @State private var correct = ""; @State private var wrong = ""; @State private var error: String?
    let initialSubject: UUID?
    var body: some View {
        NavigationStack {
            Form {
                Section("Matéria") { Picker("Matéria", selection: $selected) { ForEach(store.subjects) { Text($0.name).tag(Optional($0.id)) } } }
                Section("Resultado") {
                    TextField("Acertos", text: $correct).keyboardType(.numberPad)
                    TextField("Erros", text: $wrong).keyboardType(.numberPad)
                    if let error { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Registrar questões")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Salvar") { save() } } }
            .onAppear { selected = initialSubject ?? store.subjects.first?.id }
        }
    }
    private func save() {
        guard let selected, let c = Int(correct), let w = Int(wrong) else { error = "Preencha os números e escolha uma matéria."; return }
        do { try store.add(subjectID: selected, correct: c, wrong: w); dismiss() } catch { self.error = error.localizedDescription }
    }
}
