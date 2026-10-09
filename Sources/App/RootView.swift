import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Início", systemImage: "house.fill") }

            LibraryView()
                .tabItem { Label("Biblioteca", systemImage: "books.vertical.fill") }

            DashboardView()
                .tabItem { Label("Progresso", systemImage: "chart.xyaxis.line") }

            SettingsView()
                .tabItem { Label("Ajustes", systemImage: "slider.horizontal.3") }
        }
    }
}
