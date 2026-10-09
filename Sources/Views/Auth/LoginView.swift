import GoogleSignInSwift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var auth: GoogleAuthStore
    @AppStorage("glassIntensityPercent") private var glassIntensityPercent = 85
    @State private var animateGlow = false
    @State private var twinkle = false

    private var intensity: Double { Double(glassIntensityPercent) / 100 }

    var body: some View {
        ZStack {
            AmbientBackground(style: .welcome)

            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: max(34, proxy.size.height * 0.075))

                        brandBlock

                        VStack(spacing: 16) {
                            GoogleSignInButton(scheme: .light, style: .wide, state: auth.isLoading ? .disabled : .normal) {
                                auth.signIn()
                            }
                            .frame(height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .disabled(auth.isLoading)

                            if auth.isLoading {
                                ProgressView("Conectando com Google…")
                                    .font(.subheadline)
                            }

                            if let error = auth.errorMessage, !error.isEmpty {
                                Label(error, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "lock.shield.fill")
                                Text("Login oficial do Google. Sua senha nunca passa pelo Kepleræ.")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        }
                        .padding(18)
                        .frame(maxWidth: 520)
                        .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .kepleraeGlass(intensity: intensity, cornerRadius: 28, interactive: false)
                        .padding(.top, 30)

                        Spacer(minLength: 38)

                        Text("Kepleræ 1.3 · SwiftUI · iOS 27")
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.72))
                            .padding(.bottom, 20)
                    }
                    .frame(minHeight: proxy.size.height)
                    .padding(.horizontal, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
        .onAppear {
            animateGlow = true
            twinkle = true
        }
    }

    private var brandBlock: some View {
        VStack(spacing: 18) {
            ZStack {
                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "star.fill")
                        .font(.system(size: CGFloat(8 + (index % 3) * 3)))
                        .foregroundStyle(index.isMultiple(of: 2) ? Color.cyan : Color.purple)
                        .opacity(twinkle ? 0.22 + Double(index % 3) * 0.22 : 0.8)
                        .offset(
                            x: CGFloat([-112, -82, -48, 64, 98, 116][index]),
                            y: CGFloat([-62, 66, -96, -82, 48, 4][index])
                        )
                        .animation(.easeInOut(duration: 1.2 + Double(index) * 0.18).repeatForever(autoreverses: true), value: twinkle)
                }

                Image("KepleraeLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 158, height: 158)
                    .clipShape(RoundedRectangle(cornerRadius: 37, style: .continuous))
                    .shadow(color: .cyan.opacity(animateGlow ? 0.28 : 0.12), radius: animateGlow ? 28 : 12, y: 9)
                    .scaleEffect(animateGlow ? 1.015 : 0.985)
                    .offset(y: animateGlow ? -3 : 3)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateGlow)
            }
            .frame(height: 180)

            VStack(spacing: 7) {
                Text("Kepleræ")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("Seu espaço de estudos, do seu jeito.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
