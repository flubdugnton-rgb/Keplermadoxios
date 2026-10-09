import Foundation
import GoogleSignIn
import UIKit

@MainActor
final class GoogleAuthStore: ObservableObject {
    @Published private(set) var isSignedIn = false
    @Published private(set) var displayName = ""
    @Published private(set) var email = ""
    @Published private(set) var photoURL = ""
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let driveFileScope = "https://www.googleapis.com/auth/drive.file"
    private let googleCanceledErrorCode = -5

    init() {
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
           !clientID.isEmpty {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        restorePreviousSignIn()
    }

    func signIn() {
        guard let rootViewController = Self.rootViewController() else {
            errorMessage = "Não foi possível abrir a tela de login do Google."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await GIDSignIn.sharedInstance.signIn(
                    withPresenting: rootViewController,
                    hint: nil,
                    additionalScopes: [driveFileScope]
                )

                apply(result.user)
                isLoading = false
            } catch {
                isLoading = false

                let nsError = error as NSError
                if nsError.domain == kGIDSignInErrorDomain,
                   nsError.code == googleCanceledErrorCode {
                    return
                }

                errorMessage = error.localizedDescription
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()

        displayName = ""
        email = ""
        photoURL = ""
        isSignedIn = false

        UserDefaults.standard.removeObject(forKey: "googleDisplayName")
        UserDefaults.standard.removeObject(forKey: "googleEmail")
        UserDefaults.standard.removeObject(forKey: "googlePhotoURL")
    }

    func handle(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    private func restorePreviousSignIn() {
        isLoading = true

        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, _ in
            let restoredName = user?.profile?.name ?? ""
            let restoredEmail = user?.profile?.email ?? ""
            let restoredPhotoURL = user?.profile?.imageURL(withDimension: 320)?.absoluteString ?? ""
            let restoredSignedIn = user != nil

            Task { @MainActor [weak self] in
                guard let self else { return }

                if restoredSignedIn {
                    self.applyProfile(
                        name: restoredName,
                        email: restoredEmail,
                        photoURL: restoredPhotoURL
                    )
                } else {
                    self.displayName = UserDefaults.standard.string(forKey: "googleDisplayName") ?? ""
                    self.email = UserDefaults.standard.string(forKey: "googleEmail") ?? ""
                    self.photoURL = UserDefaults.standard.string(forKey: "googlePhotoURL") ?? ""
                    self.isSignedIn = false
                }

                self.isLoading = false
            }
        }
    }

    private func apply(_ user: GIDGoogleUser) {
        applyProfile(
            name: user.profile?.name ?? "",
            email: user.profile?.email ?? "",
            photoURL: user.profile?.imageURL(withDimension: 320)?.absoluteString ?? ""
        )
    }

    private func applyProfile(name: String, email: String, photoURL: String) {
        displayName = name
        self.email = email
        self.photoURL = photoURL
        isSignedIn = true

        UserDefaults.standard.set(displayName, forKey: "googleDisplayName")
        UserDefaults.standard.set(self.email, forKey: "googleEmail")
        UserDefaults.standard.set(self.photoURL, forKey: "googlePhotoURL")
    }

    private static func rootViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

        guard let root = scenes
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController
        else {
            return nil
        }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }

        return top
    }
}
