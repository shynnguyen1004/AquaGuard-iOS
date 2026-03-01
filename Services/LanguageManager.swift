//
//  LanguageManager.swift
//  AquaGuard
//
//  Manages the app's language preference (English / Vietnamese).
//

import Combine
import Foundation

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case vietnamese = "vi"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .vietnamese: return "🇻🇳"
        }
    }
}

@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "app_language")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        self.current = AppLanguage(rawValue: saved) ?? .english
    }

    func toggle() {
        current = (current == .english) ? .vietnamese : .english
    }

    // MARK: - Localize

    func localize(_ key: String) -> String {
        AppStrings.translations[key]?[current] ?? key
    }
}

// MARK: - Translations (module-level, no actor isolation)

enum AppStrings {
    static let translations: [String: [AppLanguage: String]] = [
        // MARK: Tab labels
        "Home": [.english: "Home", .vietnamese: "Trang chủ"],
        "Map": [.english: "Map", .vietnamese: "Bản đồ"],
        "Report": [.english: "Report", .vietnamese: "Báo cáo"],
        "Safety": [.english: "Safety", .vietnamese: "An toàn"],
        "Rescue": [.english: "Rescue", .vietnamese: "Cứu hộ"],

        // MARK: HomeView
        "Welcome back,": [.english: "Welcome back,", .vietnamese: "Chào mừng trở lại,"],
        "Responder Alpha": [.english: "Responder Alpha", .vietnamese: "Nhân viên Alpha"],
        "Sign Out": [.english: "Sign Out", .vietnamese: "Đăng xuất"],
        "Quick Actions": [.english: "Quick Actions", .vietnamese: "Thao tác nhanh"],
        "Shelter": [.english: "Shelter", .vietnamese: "Nơi trú ẩn"],
        "Family": [.english: "Family", .vietnamese: "Gia đình"],
        "Active Alerts": [.english: "Active Alerts", .vietnamese: "Cảnh báo"],
        "Active": [.english: "Active", .vietnamese: "Đang hoạt động"],
        "SOS Sent": [.english: "SOS Sent", .vietnamese: "Đã gửi SOS"],
        "SOS Message": [
            .english: "Your information is sent! Stay at your current position and wait for help",
            .vietnamese: "Thông tin của bạn đã được gửi! Hãy ở nguyên vị trí và chờ cứu hộ",
        ],

        // MARK: StatusCard
        "Safe": [.english: "Safe", .vietnamese: "An toàn"],
        "Caution": [.english: "Caution", .vietnamese: "Cảnh giác"],
        "Danger": [.english: "Danger", .vietnamese: "Nguy hiểm"],
        "Critical": [.english: "Critical", .vietnamese: "Nghiêm trọng"],
        "Current Risk Level": [.english: "Current Risk Level", .vietnamese: "Mức độ nguy hiểm"],

        // MARK: SafetyView
        "Emergency Assistance": [.english: "Emergency Assistance", .vietnamese: "Hỗ trợ khẩn cấp"],
        "Police": [.english: "Police", .vietnamese: "Công an"],
        "Fire Brigade": [.english: "Fire Brigade", .vietnamese: "Cứu hỏa"],
        "Ambulance": [.english: "Ambulance", .vietnamese: "Cấp cứu"],
        "Tap to Register": [.english: "Tap to Register", .vietnamese: "Nhấn để đăng ký"],
        "Select your Carrier": [.english: "Select your Carrier", .vietnamese: "Chọn nhà mạng"],
        "Cancel": [.english: "Cancel", .vietnamese: "Hủy"],
        "Safety Guides": [.english: "Safety Guides", .vietnamese: "Hướng dẫn an toàn"],
        "During a Flood": [.english: "During a Flood", .vietnamese: "Trong lúc lũ lụt"],
        "After a Flood": [.english: "After a Flood", .vietnamese: "Sau lũ lụt"],
        "Vehicle Safety": [.english: "Vehicle Safety", .vietnamese: "An toàn phương tiện"],
        "Medium": [.english: "Medium", .vietnamese: "Trung bình"],
        "High": [.english: "High", .vietnamese: "Cao"],

        // Safety steps - During a Flood
        "Move to higher ground immediately": [
            .english: "Move to higher ground immediately",
            .vietnamese: "Di chuyển đến vùng cao ngay lập tức",
        ],
        "Avoid walking or driving through flood waters": [
            .english: "Avoid walking or driving through flood waters",
            .vietnamese: "Tránh đi bộ hoặc lái xe qua vùng ngập",
        ],
        "Stay away from downed power lines": [
            .english: "Stay away from downed power lines",
            .vietnamese: "Tránh xa đường dây điện bị đứt",
        ],
        "Listen to emergency broadcasts": [
            .english: "Listen to emergency broadcasts", .vietnamese: "Theo dõi thông báo khẩn cấp",
        ],

        // Safety steps - After a Flood
        "Return home only when authorities say it's safe": [
            .english: "Return home only when authorities say it's safe",
            .vietnamese: "Chỉ về nhà khi chính quyền thông báo an toàn",
        ],
        "Document damage with photos": [
            .english: "Document damage with photos", .vietnamese: "Chụp ảnh ghi nhận thiệt hại",
        ],
        "Clean and disinfect everything that got wet": [
            .english: "Clean and disinfect everything that got wet",
            .vietnamese: "Vệ sinh và khử trùng mọi thứ bị ướt",
        ],
        "Watch for structural damage": [
            .english: "Watch for structural damage", .vietnamese: "Kiểm tra hư hại cấu trúc",
        ],

        // Safety steps - Vehicle Safety
        "Never drive through flooded roads": [
            .english: "Never drive through flooded roads",
            .vietnamese: "Không lái xe qua đường ngập",
        ],
        "Turn around if water is rising": [
            .english: "Turn around if water is rising", .vietnamese: "Quay đầu nếu nước đang dâng",
        ],

        // MARK: RescueView
        "Resource Availability": [
            .english: "Resource Availability", .vietnamese: "Nguồn lực sẵn có",
        ],
        "Rescue Requests": [.english: "Rescue Requests", .vietnamese: "Yêu cầu cứu hộ"],
        "Pending": [.english: "Pending", .vietnamese: "Chờ xử lý"],
        "In Progress": [.english: "In Progress", .vietnamese: "Đang xử lý"],
        "Completed": [.english: "Completed", .vietnamese: "Hoàn thành"],
        "people": [.english: "people", .vietnamese: "người"],
        "Track": [.english: "Track", .vietnamese: "Theo dõi"],
        "Complete": [.english: "Complete", .vietnamese: "Hoàn tất"],
        "Assign Team": [.english: "Assign Team", .vietnamese: "Phân đội"],
        "Rescue Boats": [.english: "Rescue Boats", .vietnamese: "Thuyền cứu hộ"],
        "Shelters Open": [.english: "Shelters Open", .vietnamese: "Nơi trú ẩn"],
        "Medical Teams": [.english: "Medical Teams", .vietnamese: "Đội y tế"],
        "Active Rescues": [.english: "Active Rescues", .vietnamese: "Đang cứu hộ"],

        // MARK: ReportView
        "Location": [.english: "Location", .vietnamese: "Vị trí"],
        "Enter location or pin on map": [
            .english: "Enter location or pin on map",
            .vietnamese: "Nhập vị trí hoặc ghim trên bản đồ",
        ],
        "Water Level": [.english: "Water Level", .vietnamese: "Mực nước"],
        "Low": [.english: "Low", .vietnamese: "Thấp"],
        "Description": [.english: "Description", .vietnamese: "Mô tả"],
        "Add Photo (Optional)": [
            .english: "Add Photo (Optional)", .vietnamese: "Thêm ảnh (Tùy chọn)",
        ],
        "Tap to upload": [.english: "Tap to upload", .vietnamese: "Nhấn để tải ảnh"],
        "Submit Report": [.english: "Submit Report", .vietnamese: "Gửi báo cáo"],
        "Success": [.english: "Success", .vietnamese: "Thành công"],
        "Your report has been submitted successfully.": [
            .english: "Your report has been submitted successfully.",
            .vietnamese: "Báo cáo của bạn đã được gửi thành công.",
        ],
        "Error": [.english: "Error", .vietnamese: "Lỗi"],
        "Select Photo": [.english: "Select Photo", .vietnamese: "Chọn ảnh"],
        "Camera": [.english: "Camera", .vietnamese: "Máy ảnh"],
        "Photo Library": [.english: "Photo Library", .vietnamese: "Thư viện ảnh"],
        "Done": [.english: "Done", .vietnamese: "Xong"],

        // MARK: LoginView
        "Welcome to AquaGuard": [
            .english: "Welcome to AquaGuard", .vietnamese: "Chào mừng đến AquaGuard",
        ],
        "Sign in to access flood alerts and rescue features": [
            .english: "Sign in to access flood alerts and rescue features",
            .vietnamese: "Đăng nhập để truy cập cảnh báo lũ lụt và cứu hộ",
        ],
        "Sign in with Google": [
            .english: "Sign in with Google", .vietnamese: "Đăng nhập bằng Google",
        ],
        "OK": [.english: "OK", .vietnamese: "OK"],
    ]
}

// MARK: - String Extension for Localization

extension String {
    /// Returns the localized version of the string using the current language setting.
    var localized: String {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        let lang = AppLanguage(rawValue: saved) ?? .english
        return AppStrings.translations[self]?[lang] ?? self
    }
}
