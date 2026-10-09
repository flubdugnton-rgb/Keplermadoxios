import GoogleSignInSwift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var auth: GoogleAuthStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    @State private var floating = false
    @State private var appeared = false

    private var intensity: Double { Double(glassIntensityPercent) / 100 }

    var body: some View {
        ZStack {
            AmbientBackground(style: .welcome)

            VStack(spacing: 26) {
                Spacer(minLength: 48)

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 222, height: 222)
                        .kepleraeGlass(intensity: intensity, cornerRadius: 111, interactive: false)

                    Image("KepleraeLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 176, height: 176)
                        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 22, y: 12)
                }
                .offset(y: floating ? -6 : 6)
                .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: floating)

                VStack(spacing: 7) {
                    Text("Kepleræ")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                    Text("Seu espaço de estudos, do seu jeito.")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(.white.opacity(0.10))
                            .frame(height: 64)
                            .kepleraeGlass(intensity: intensity, cornerRadius: 30, interactive: true)

                        GoogleSignInButton {
                            auth.signIn()
                        }
                        .frame(height: 50)
                        .padding(.horizontal, 10)
                        .disabled(auth.isLoading)
                    }

                    if auth.isLoading {
                        ProgressView("Conectando ao Google…")
                            .font(.footnote)
                    }

                    Text("A autenticação usa o SDK oficial do Google. O Kepleræ nunca pede sua senha dentro do app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)

                Spacer()

                Text("Kepleræ 1.2 · SwiftUI · iOS 27")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 20)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.97)
            .offset(y: appeared ? 0 : 16)
        }
        .onAppear {
            floating = true
            withAnimation(.spring(response: 0.65, dampingFraction: 0.86)) { appeared = true }
        }
        .alert("Login Google", isPresented: Binding(get: { auth.errorMessage != nil }, set: { if !$0 { auth.errorMessage = nil } })) {
            Button("OK") { auth.errorMessage = nil }
        } message: {
            Text(auth.errorMessage ?? "")
        }
    }
}
