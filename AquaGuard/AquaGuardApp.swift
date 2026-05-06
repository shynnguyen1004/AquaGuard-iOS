import FirebaseAuth
import FirebaseCore
import SwiftUI

// MARK: - AppDelegate Adapter for SwiftUI
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        print("AquaGuard Firebase Configured!")
        return true
    }
    // MARK: Remote Notifications

    // Register APNs device token with Firebase Auth
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Forward device token to Firebase Auth
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    }

    // Handle silent push notifications
    func application(
        _ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Check if notification belongs to Firebase Auth
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        // Otherwise handle as a regular notification
    }
}

@main
struct AquaGuardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var languageManager = LanguageManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var userID: String? = nil
    @State private var authHandle: AuthStateDidChangeListenerHandle?
    @State private var showSplash: Bool = true

    // DEV: set to true to skip login
    @AppStorage("devSkipLogin") private var devSkipLogin: Bool = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                } else {
                    Group {
                        if userID != nil || devSkipLogin {
                            switch AppState.shared.currentRole {
                            case .citizen:
                                ContentView()
                            case .rescuer:
                                RescuerContentView()
                            case .admin:
                                AdminContentView()
                            }
                        } else {
                            LoginView()
                        }
                    }
                    .transition(.opacity)
                }
            }
            .environmentObject(languageManager)
            .preferredColorScheme(themeManager.colorScheme)
            .onAppear {
                authHandle = Auth.auth().addStateDidChangeListener { auth, user in
                    if let user = user {
                        self.userID = user.uid
                        print("App: User is signed in: \(user.uid)")
                    } else {
                        self.userID = nil
                        print("App: User is signed out")
                    }
                }

                // Dismiss splash after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
            .onDisappear {
                if let handle = authHandle {
                    Auth.auth().removeStateDidChangeListener(handle)
                    authHandle = nil
                }
            }
        }
    }
}
