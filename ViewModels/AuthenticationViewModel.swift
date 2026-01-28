//
//  AuthenticationViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 28/1/26.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn // 1. Import thêm cái này
import SwiftUI
import Combine

class AuthenticationViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    
    // Hàm đăng nhập Google
    @MainActor
    func signInWithGoogle() {
        // Lấy màn hình hiện tại để hiển thị popup đăng nhập Google
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        isLoading = true
        
        // 1. Gọi thư viện Google Sign-In
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.alertMessage = "Lỗi Google: \(error.localizedDescription)"
                self.showAlert = true
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.isLoading = false
                return
            }
            
            let accessToken = user.accessToken.tokenString
            
            // 2. Tạo Credential để gửi cho Firebase
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: accessToken)
            
            // 3. Đăng nhập vào Firebase
            Auth.auth().signIn(with: credential) { authResult, error in
                self.isLoading = false
                if let error = error {
                    self.alertMessage = "Lỗi Firebase: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                print("Đăng nhập Google thành công: \(authResult?.user.email ?? "")")
            }
        }
    }
}
