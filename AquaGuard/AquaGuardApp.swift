import SwiftUI
import FirebaseAuth
import FirebaseCore // 1. Import cái này

// 2. Tạo một cái Adapter để kết nối AppDelegate cũ với SwiftUI mới
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure() // 3. Dòng code kích hoạt Firebase
    print("AquaGuard Firebase Configured!") // In ra để biết đã chạy
    return true
  }
// --- BỔ SUNG 2 HÀM DƯỚI ĐÂY ---

    // Hàm 1: Đăng ký nhận thông báo (APNs Token)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Gửi token của máy lên cho Firebase Auth
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    }

    // Hàm 2: Xử lý khi có thông báo chạy ngầm (Silent Push)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Kiểm tra xem thông báo này có phải của Firebase Auth gửi không
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        // Nếu không phải thì xử lý như thông báo bình thường
    }
}

@main
struct AquaGuardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var userID: String? = nil // Dùng cái này để check login
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if userID != nil {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .onAppear {
                // Lắng nghe: Cứ ai đăng nhập/đăng xuất là code này chạy
                Auth.auth().addStateDidChangeListener { auth, user in
                    if let user = user {
                        self.userID = user.uid
                        print("App: User is signed in: \(user.uid)")
                    } else {
                        self.userID = nil
                        print("App: User is signed out")
                    }
                }
            }
        }
    }
}
