import SwiftUI
import FirebaseCore

// MARK: - AppDelegate Adapter for SwiftUI
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        print("AquaGuard Configured (JWT Backend + Firebase)")
        return true
    }
}

@main
struct AquaGuardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var tokenManager = TokenManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var appState = AppState.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSplash: Bool = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                } else {
                    Group {
                        if tokenManager.isAuthenticated {
                            switch appState.currentRole {
                            case .citizen:
                                ContentView()
                            case .rescuer:
                                RescuerContentView()
                            case .admin:
                                AdminAccessBlockedView()
                            }
                        } else {
                            LoginView()
                        }
                    }
                    .transition(.opacity)
                }
            }
            .environmentObject(languageManager)
            .environmentObject(tokenManager)
            .preferredColorScheme(themeManager.colorScheme)
            .task {
                // Present the call UI in its own high-level window so it floats
                // above sheets (e.g. the live-tracking sheet), not behind them.
                CallOverlayWindow.shared.start()

                // Keep the signaling socket alive whenever logged in so incoming
                // calls can ring even without a tracking sheet open.
                if tokenManager.isAuthenticated {
                    WebSocketService.shared.connect()
                }
            }
            .onChange(of: tokenManager.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    WebSocketService.shared.connect()
                } else {
                    WebSocketService.shared.disconnect()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                // iOS kills the socket when the app is backgrounded — reconnect
                // on return so incoming calls can ring again.
                if phase == .active && tokenManager.isAuthenticated {
                    WebSocketService.shared.ensureConnected()
                }
            }
            .onAppear {
                // Dismiss splash after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
