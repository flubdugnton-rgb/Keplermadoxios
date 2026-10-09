import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var studyState: StudyStateStore
    @EnvironmentObject private var auth: GoogleAuthStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    let resetID: UUID

    private var intensity: Double { Double(glassIntensityPercent) / 100 }
    private var completedCount: Int { studyState.completed.intersection(Set(catalog.items.map(\.id))).count }
    private var progress: Double { catalog.items.isEmpty ? 0 : Double(completedCount) / Double(catalog.items.count) }
    private var resumeItem: StudyItem? {
        guard let id = studyState.lastOpenedID else { return catalog.items.first }
        return catalog.items.first(where: { $0.id == id }) ?? catalog.items.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        journeyCard
                        stats
                        subjectsGrid
                        continueCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 118)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .id(resetID)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(auth.displayName.isEmpty ? "Kepleræ" : "Olá, \(auth.displayName.components(separatedBy: " ").first ?? auth.displayName)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("Seu percurso continua daqui.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image("KepleraeLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                .shadow(color: .blue.opacity(0.16), radius: 12, y: 5)
        }
    }

    private var journeyCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label("Seu percurso", systemImage: "sparkles")
                    .font(.title3.bold())
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if let loadError = catalog.loadError {
                Label(loadError, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Text("\(completedCount) de \(catalog.items.count) materiais concluídos")
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(.cyan)

            if let item = resumeItem {
                NavigationLink {
                    StudyItemView(item: item)
                } label: {
                    Label(completedCount == 0 ? "Começar estudo" : "Retomar estudo", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: [.cyan.opacity(0.16), .blue.opacity(0.09), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .kepleraeGlass(intensity: intensity, cornerRadius: 30, interactive: false)
    }

    private var stats: some View {
        HStack(spacing: 12) {
            NavigationLink { LibraryView(initialType: .lesson, embedded: true) } label: {
                StatTile(value: count(.lesson), title: "Aulas", icon: "play.circle.fill", tint: .blue, intensity: intensity)
            }.buttonStyle(.plain)
            NavigationLink { LibraryView(initialType: .pdf, embedded: true) } label: {
                StatTile(value: count(.pdf), title: "PDFs", icon: "doc.text.fill", tint: .purple, intensity: intensity)
            }.buttonStyle(.plain)
            NavigationLink { LibraryView(initialType: .audio, embedded: true) } label: {
                StatTile(value: count(.audio), title: "Áudios", icon: "headphones", tint: .pink, intensity: intensity)
            }.buttonStyle(.plain)
        }
    }

    private var subjectsGrid: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("Suas matérias").font(.title2.bold())
                Spacer()
                NavigationLink {
                    LibraryView(embedded: true)
                } label: {
                    Text("Ver todas")
                        .font(.subheadline.weight(.semibold))
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(catalog.subjects) { subject in
                    NavigationLink {
                        SubjectDetailView(subject: subject)
                    } label: {
                        SubjectHomeCard(subject: subject, count: catalog.count(for: subject), intensity: intensity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var continueCard: some View {
        if let item = resumeItem {
            VStack(alignment: .leading, spacing: 10) {
                Text("Continue de onde parou").font(.title3.bold())
                NavigationLink {
                    StudyItemView(item: item)
                } label: {
                    HStack(spacing: 13) {
                        Image(systemName: item.type.icon)
                            .font(.title3)
                            .foregroundStyle(item.type.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.subheadline.weight(.semibold)).lineLimit(2)
                            Text(catalog.subjects.first(where: { $0.id == item.subjectID })?.title ?? item.type.title)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .padding(16)
                    .kepleraeGlass(intensity: intensity, cornerRadius: 22)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func count(_ type: StudyContentType) -> Int {
        catalog.items.filter { $0.type == type }.count
    }
}

private struct StatTile: View {
    let value: Int
    let title: String
    let icon: String
    let tint: Color
    let intensity: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon).foregroundStyle(tint).font(.title3)
            Text("\(value)").font(.title.bold()).monospacedDigit()
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .kepleraeGlass(intensity: intensity, cornerRadius: 24, interactive: false)
    }
}

private struct SubjectHomeCard: View {
    let subject: Subject
    let count: Int
    let intensity: Double

    var body: some View {
        let palette = SubjectPalette.forSubject(subject.id)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle().fill(.white.opacity(0.28)).frame(width: 45, height: 45)
                    Image(systemName: subject.icon).font(.title3.bold())
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 2)
            Text(subject.title)
                .font(.subheadline.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text("\(count) materiais")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(colors: [palette.primary.opacity(0.28), palette.secondary.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .kepleraeGlass(intensity: intensity, cornerRadius: 26)
    }
}
