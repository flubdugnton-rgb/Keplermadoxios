import SwiftUI

struct SettingsView: View {
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 75

    private var intensity: Double { Double(glassIntensityPercent) / 100.0 }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(spacing: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Liquid Glass")
                                .font(.title2.bold())
                            Text("Escolha a intensidade visual usando a roda abaixo.")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 8) {
                            Text("\(glassIntensityPercent)%")
                                .font(.system(size: 34, weight: .semibold, design: .rounded))

                            Picker("Intensidade do Liquid Glass", selection: $glassIntensityPercent) {
                                ForEach(Array(stride(from: 0, through: 100, by: 10)), id: \.self) { value in
                                    Text("\(value)%").tag(value)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 150)
                            .clipped()
                        }
                        .padding(20)
                        .kepleraeGlass(intensity: intensity, cornerRadius: 30, interactive: false)

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Prévia", systemImage: "sparkles")
                                .font(.headline)
                            Text("0% remove o efeito. Valores baixos usam vidro claro e valores maiores usam o Liquid Glass regular, com contorno, brilho e sombra graduais.")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .kepleraeGlass(intensity: intensity, cornerRadius: 30, interactive: false)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Ajustes")
        }
    }
}
