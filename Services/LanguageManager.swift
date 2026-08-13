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
        "Location:": [.english: "Location:", .vietnamese: "Vị trí:"],
        "Location unavailable": [.english: "Location unavailable", .vietnamese: "Chưa có vị trí"],
        "Updating weather...": [.english: "Updating weather...", .vietnamese: "Đang cập nhật thời tiết..."],
        "Enable location to see your local risk": [
            .english: "Enable location to see your local risk",
            .vietnamese: "Bật vị trí để xem mức rủi ro tại chỗ bạn",
        ],
        "Could not load weather data": [
            .english: "Could not load weather data",
            .vietnamese: "Không tải được dữ liệu thời tiết",
        ],
        "Weather unavailable": [
            .english: "Weather unavailable",
            .vietnamese: "Chưa có dữ liệu thời tiết",
        ],
        "Rain": [.english: "Rain", .vietnamese: "Mưa"],
        "Wind": [.english: "Wind", .vietnamese: "Gió"],
        "Humidity": [.english: "Humidity", .vietnamese: "Độ ẩm"],
        "Humidity unavailable": [
            .english: "—",
            .vietnamese: "—",
        ],
        "Conditions look stable near you": [
            .english: "Conditions look stable near you",
            .vietnamese: "Thời tiết ổn định quanh bạn",
        ],
        "Stay alert for changing weather": [
            .english: "Stay alert for changing weather",
            .vietnamese: "Theo dõi thời tiết thay đổi",
        ],
        "Limit travel and prepare for flooding": [
            .english: "Limit travel and prepare for flooding",
            .vietnamese: "Hạn chế di chuyển và chuẩn bị chống ngập",
        ],
        "Take immediate precautions": [
            .english: "Take immediate precautions",
            .vietnamese: "Cần phòng ngừa ngay",
        ],

        // MARK: Dev Mode
        "Dev Mode": [.english: "Dev Mode", .vietnamese: "Chế độ Dev"],
        "Simulate weather status": [
            .english: "Simulate weather status",
            .vietnamese: "Giả lập trạng thái thời tiết",
        ],
        "Real (current location)": [
            .english: "Real (current location)",
            .vietnamese: "Thật (vị trí hiện tại)",
        ],
        "Preview: Safe": [.english: "Preview: Safe", .vietnamese: "Xem thử: An toàn"],
        "Preview: Caution": [.english: "Preview: Caution", .vietnamese: "Xem thử: Cảnh giác"],
        "Preview: Danger": [.english: "Preview: Danger", .vietnamese: "Xem thử: Nguy hiểm"],
        "Preview: Critical": [.english: "Preview: Critical", .vietnamese: "Xem thử: Nghiêm trọng"],
        "Dev mode uses mock location and weather for the Status Card preview.": [
            .english: "Dev mode uses mock location and weather for the Status Card preview.",
            .vietnamese: "Chế độ Dev dùng vị trí và thời tiết giả lập để xem thử thẻ trạng thái.",
        ],

        // MARK: SafetyView
        "Emergency Assistance": [.english: "Emergency Assistance", .vietnamese: "Hỗ trợ khẩn cấp"],
        "Police": [.english: "Police", .vietnamese: "Công an"],
        "Fire Brigade": [.english: "Fire Brigade", .vietnamese: "Cứu hỏa"],
        "Ambulance": [.english: "Ambulance", .vietnamese: "Cấp cứu"],
        "Tap to Register": [.english: "Tap to Register", .vietnamese: "Nhấn để đăng ký"],
        "Select your Carrier": [.english: "Select your Carrier", .vietnamese: "Chọn nhà mạng"],
        "Cancel": [.english: "Cancel", .vietnamese: "Hủy"],
        "Safety Guides": [.english: "Safety Guides", .vietnamese: "Hướng dẫn an toàn"],
        "Before a Flood": [.english: "Before a Flood", .vietnamese: "Trước khi lũ đến"],
        "During a Flood": [.english: "During a Flood", .vietnamese: "Trong lúc lũ lụt"],
        "After a Flood": [.english: "After a Flood", .vietnamese: "Sau lũ lụt"],
        "Health & Hygiene After Flooding": [
            .english: "Health & Hygiene After Flooding", .vietnamese: "Sức khỏe & vệ sinh sau lũ",
        ],
        "Vehicle Safety": [.english: "Vehicle Safety", .vietnamese: "An toàn phương tiện"],
        "Medium": [.english: "Medium", .vietnamese: "Trung bình"],
        "High": [.english: "High", .vietnamese: "Cao"],

        // Safety steps - Before a Flood
        "Prepare an emergency kit with flashlight, batteries, first aid, medications, and at least 3 days of water and food": [
            .english: "Prepare an emergency kit with flashlight, batteries, first aid, medications, and at least 3 days of water and food",
            .vietnamese: "Chuẩn bị túi đồ khẩn cấp gồm đèn pin, pin dự phòng, dụng cụ sơ cứu, thuốc men, và ít nhất 3 ngày nước uống, thức ăn",
        ],
        "Know your evacuation route in advance and agree on a safe meeting point with your family": [
            .english: "Know your evacuation route in advance and agree on a safe meeting point with your family",
            .vietnamese: "Xác định trước lộ trình sơ tán và thống nhất với gia đình một điểm hẹn an toàn",
        ],
        "Keep your phone charged and turn on flood alerts so you're notified the moment your area is at risk": [
            .english: "Keep your phone charged and turn on flood alerts so you're notified the moment your area is at risk",
            .vietnamese: "Luôn sạc đầy điện thoại và bật cảnh báo lũ để được thông báo ngay khi khu vực của bạn có nguy cơ",
        ],
        "Move valuables and important documents to higher shelves or an upper floor before water starts rising": [
            .english: "Move valuables and important documents to higher shelves or an upper floor before water starts rising",
            .vietnamese: "Di chuyển đồ có giá trị và giấy tờ quan trọng lên kệ cao hoặc tầng trên trước khi nước bắt đầu dâng",
        ],

        // Safety steps - During a Flood
        "Move to higher ground or the highest floor of your home right away — floodwater can rise faster than expected, so don't wait until it looks dangerous to act": [
            .english: "Move to higher ground or the highest floor of your home right away — floodwater can rise faster than expected, so don't wait until it looks dangerous to act",
            .vietnamese: "Di chuyển đến vùng cao hoặc tầng cao nhất của nhà ngay lập tức — nước lũ có thể dâng nhanh hơn bạn nghĩ, đừng chờ đến khi tình hình trông nguy hiểm mới hành động",
        ],
        "Avoid walking or driving through flood waters no matter how shallow they look — just 15cm of moving water can knock an adult off their feet, and 60cm can sweep away a car": [
            .english: "Avoid walking or driving through flood waters no matter how shallow they look — just 15cm of moving water can knock an adult off their feet, and 60cm can sweep away a car",
            .vietnamese: "Tránh đi bộ hoặc lái xe qua vùng nước ngập dù trông có vẻ nông — chỉ 15cm nước chảy xiết cũng có thể khiến người lớn ngã, và 60cm có thể cuốn trôi cả ô tô",
        ],
        "Stay away from downed power lines and any standing water near them, since electricity can travel through water and cause electrocution from a distance": [
            .english: "Stay away from downed power lines and any standing water near them, since electricity can travel through water and cause electrocution from a distance",
            .vietnamese: "Tránh xa đường dây điện bị đứt và vùng nước đọng gần đó, vì điện có thể truyền qua nước và gây điện giật dù đứng cách xa",
        ],
        "Keep a battery-powered or hand-crank radio nearby for emergency broadcasts, since cell networks and electricity often fail first during severe flooding": [
            .english: "Keep a battery-powered or hand-crank radio nearby for emergency broadcasts, since cell networks and electricity often fail first during severe flooding",
            .vietnamese: "Chuẩn bị sẵn radio dùng pin hoặc quay tay để theo dõi thông báo khẩn cấp, vì mạng di động và điện thường mất trước tiên khi lũ lớn xảy ra",
        ],

        // Safety steps - After a Flood
        "Return home only after authorities officially confirm it's safe — floodwater can hide structural damage and contamination that isn't visible from outside": [
            .english: "Return home only after authorities officially confirm it's safe — floodwater can hide structural damage and contamination that isn't visible from outside",
            .vietnamese: "Chỉ về nhà sau khi chính quyền chính thức xác nhận an toàn — nước lũ có thể che giấu hư hại kết cấu và ô nhiễm mà mắt thường không thấy được",
        ],
        "Document all damage with clear photos and videos before starting cleanup, since this is essential for insurance claims and relief assistance": [
            .english: "Document all damage with clear photos and videos before starting cleanup, since this is essential for insurance claims and relief assistance",
            .vietnamese: "Chụp ảnh và quay video rõ ràng toàn bộ thiệt hại trước khi dọn dẹp, vì đây là bằng chứng cần thiết để yêu cầu bảo hiểm và hỗ trợ cứu trợ",
        ],
        "Clean and disinfect everything that got wet, including floors and furniture, since floodwater often carries sewage and bacteria that can cause illness": [
            .english: "Clean and disinfect everything that got wet, including floors and furniture, since floodwater often carries sewage and bacteria that can cause illness",
            .vietnamese: "Vệ sinh và khử trùng mọi thứ bị ướt, kể cả sàn nhà và đồ nội thất, vì nước lũ thường mang theo nước thải và vi khuẩn gây bệnh",
        ],
        "Inspect your home for structural damage such as cracked foundations or a sagging roof before staying inside, and leave immediately if you notice any": [
            .english: "Inspect your home for structural damage such as cracked foundations or a sagging roof before staying inside, and leave immediately if you notice any",
            .vietnamese: "Kiểm tra kỹ nhà xem có hư hại kết cấu như nứt móng hay mái nhà võng xuống trước khi ở lại, và rời đi ngay nếu phát hiện dấu hiệu bất thường",
        ],

        // Safety steps - Health & Hygiene After Flooding
        "Only drink boiled or bottled water until authorities confirm the local water supply is safe again": [
            .english: "Only drink boiled or bottled water until authorities confirm the local water supply is safe again",
            .vietnamese: "Chỉ uống nước đã đun sôi hoặc nước đóng chai cho đến khi chính quyền xác nhận nguồn nước sinh hoạt đã an toàn trở lại",
        ],
        "Wash your hands frequently with soap, especially after any contact with floodwater, to avoid infection": [
            .english: "Wash your hands frequently with soap, especially after any contact with floodwater, to avoid infection",
            .vietnamese: "Rửa tay thường xuyên bằng xà phòng, đặc biệt sau khi tiếp xúc với nước lũ, để tránh nhiễm khuẩn",
        ],
        "Watch for signs of waterborne illness such as fever, diarrhea, or skin infections, and see a doctor promptly if they appear": [
            .english: "Watch for signs of waterborne illness such as fever, diarrhea, or skin infections, and see a doctor promptly if they appear",
            .vietnamese: "Chú ý các dấu hiệu bệnh do nguồn nước như sốt, tiêu chảy, hoặc nhiễm trùng da, và đi khám ngay nếu xuất hiện",
        ],
        "Throw away any food that touched floodwater, including canned goods with damaged or bulging seals": [
            .english: "Throw away any food that touched floodwater, including canned goods with damaged or bulging seals",
            .vietnamese: "Bỏ toàn bộ thực phẩm đã tiếp xúc với nước lũ, kể cả đồ hộp có nắp bị móp hoặc phồng",
        ],

        // Safety steps - Vehicle Safety
        "Never drive through flooded roads, even ones you know well — floodwater can hide missing manhole covers, washed-out pavement, and downed power lines": [
            .english: "Never drive through flooded roads, even ones you know well — floodwater can hide missing manhole covers, washed-out pavement, and downed power lines",
            .vietnamese: "Không bao giờ lái xe qua đường ngập, kể cả những đoạn đường quen thuộc — nước lũ có thể che giấu nắp cống bị mất, mặt đường bị cuốn trôi, và dây điện bị đứt",
        ],
        "If water starts rising around your car, turn around immediately and head for higher ground rather than trying to push through": [
            .english: "If water starts rising around your car, turn around immediately and head for higher ground rather than trying to push through",
            .vietnamese: "Nếu nước bắt đầu dâng quanh xe, hãy quay đầu ngay và tìm đến vùng cao thay vì cố đi tiếp",
        ],
        "If your car stalls or starts floating in rising water, get out right away and move to higher ground on foot instead of staying inside": [
            .english: "If your car stalls or starts floating in rising water, get out right away and move to higher ground on foot instead of staying inside",
            .vietnamese: "Nếu xe chết máy hoặc bắt đầu nổi trong nước dâng, hãy ra khỏi xe ngay lập tức và đi bộ đến vùng cao thay vì ở lại trong xe",
        ],

        // MARK: Rescue tab content
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

        // MARK: Admin (mobile blocked)
        "Admin Web Only Title": [
            .english: "Admin — Web Only",
            .vietnamese: "Quản trị — chỉ trên Web",
        ],
        "Admin Web Only Message": [
            .english: "Please sign in with a Citizen or Rescuer account. Admin access is available on the web platform only.",
            .vietnamese: "Vui lòng đăng nhập với tài khoản Citizen hoặc Rescuer. Quản trị viên chỉ sử dụng trên nền tảng web.",
        ],
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
