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
    @State private var userID: String? = nil
    @State private var authHandle: AuthStateDidChangeListenerHandle?

    var body: some Scene {
        WindowGroup {
            ZStack {
                if userID != nil {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(languageManager)
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
