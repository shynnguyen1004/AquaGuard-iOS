//
//  RescuerDashboardView.swift
//  AquaGuard
//
//  Rescuer Dashboard — main mission view.
//  Header, stats row, 3-tab request list.
//  Uses dummy data matching guide.md spec.
//

import SwiftUI

// MARK: - Shared SOS Data Model

struct SosRequest: Identifiable {
    let id: Int
    let userName: String
    let description: String?
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let urgency: String    // "critical" | "high" | "medium" | "low"
    var status: String     // "pending" | "assigned" | "in_progress" | "resolved"
    let assignedName: String?
    let createdAt: String

    // Urgency display
    var urgencyLabel: String {
        switch urgency {
        case "critical": return "Nguy cấp"
        case "high": return "Cao"
        case "medium": return "Trung bình"
        default: return "Thấp"
        }
    }

    var urgencyColor: Color {
        switch urgency {
        case "critical": return .purple
        case "high": return .red
        case "medium": return .orange
        default: return .green
        }
    }

    var urgencyIcon: String {
        switch urgency {
        case "critical": return "bolt.fill"
        case "high": return "exclamationmark.2"
        case "medium": return "exclamationmark.triangle.fill"
        default: return "exclamationmark.circle"
        }
    }

    // Status display
    var statusLabel: String {
        switch status {
        case "pending": return "Chờ xử lý"
        case "assigned": return "Đã nhận"
        case "in_progress": return "Đang cứu"
        default: return "Hoàn thành"
        }
    }

    var statusColor: Color {
        switch status {
        case "pending": return .orange
        case "assigned": return .blue
        case "in_progress": return .aquaPrimary
        default: return .green
        }
    }

    // Dummy data
    static var dummyRequests: [SosRequest] = [
        SosRequest(id: 1, userName: "Nguyễn Văn Minh", description: "Nước dâng cao 1m, gia đình 4 người cần giải cứu khẩn cấp", location: "123 Nguyễn Huệ, Quận 1, TP.HCM", latitude: 10.7769, longitude: 106.7009, urgency: "critical", status: "pending", assignedName: nil, createdAt: "2025-05-03T08:30:00Z"),
        SosRequest(id: 2, userName: "Trần Thị Lan", description: "Bị kẹt trên tầng 2, cần ca nô cứu hộ", location: "45 Lê Lợi, Quận 5, TP.HCM", latitude: 10.7540, longitude: 106.6633, urgency: "high", status: "pending", assignedName: nil, createdAt: "2025-05-03T09:15:00Z"),
        SosRequest(id: 3, userName: "Phạm Văn Đức", description: "Người già cần di chuyển đến nơi an toàn", location: "78 Trần Hưng Đạo, Quận 10", latitude: 10.7628, longitude: 106.6714, urgency: "medium", status: "assigned", assignedName: "Đội Alpha", createdAt: "2025-05-03T07:00:00Z"),
        SosRequest(id: 4, userName: "Lê Thị Hồng", description: "Đã được cứu, đang ở điểm tập kết", location: "Trường THPT Nguyễn Du", latitude: 10.7865, longitude: 106.6950, urgency: "low", status: "resolved", assignedName: "Đội Alpha", createdAt: "2025-05-02T14:00:00Z"),
        SosRequest(id: 5, userName: "Hoàng Minh Tuấn", description: "Xe bị ngập, cần hỗ trợ kéo xe và di chuyển", location: "Đường Võ Văn Kiệt, Quận 6", latitude: 10.7481, longitude: 106.6350, urgency: "high", status: "in_progress", assignedName: "Tôi", createdAt: "2025-05-03T06:45:00Z"),
        SosRequest(id: 6, userName: "Võ Thị Mai", description: "Trẻ em 2 tuổi bị sốt cao, cần y tế khẩn", location: "Hẻm 220 Lý Thường Kiệt, Quận 11", latitude: 10.7700, longitude: 106.6500, urgency: "critical", status: "pending", assignedName: nil, createdAt: "2025-05-03T10:00:00Z"),
    ]
}

// MARK: - Rescuer Dashboard View

struct RescuerDashboardView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedTab = 0
    @State private var requests = SosRequest.dummyRequests
    @State private var toastMessage: String?

    private var pendingRequests: [SosRequest] {
        requests.filter { $0.status == "pending" }
    }

    private var myMissions: [SosRequest] {
        requests.filter { $0.status == "assigned" || $0.status == "in_progress" }
    }

    private var completedRequests: [SosRequest] {
        requests.filter { $0.status == "resolved" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.aquaBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Header Row
                        headerRow

                        // 2. Stats Row (3 cards)
                        statsRow

                        // 3. Tab bar
                        Picker("", selection: $selectedTab) {
                            Text("Đang chờ (\(pendingRequests.count))").tag(0)
                            Text("Đang làm (\(myMissions.count))").tag(1)
                            Text("Hoàn thành (\(completedRequests.count))").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)

                        // 4. Request list
                        let currentList: [SosRequest] = {
                            switch selectedTab {
                            case 0: return pendingRequests
                            case 1: return myMissions
                            default: return completedRequests
                            }
                        }()

                        if currentList.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(currentList.enumerated()), id: \.element.id) { index, req in
                                    rescuerRequestCard(req)
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                        .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.08), value: selectedTab)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .bottom) {
                if let msg = toastMessage {
                    toastView(msg)
                }
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.aquaPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Xin chào 🚒")
                        .font(.headline)
                        .foregroundColor(.aquaNavy)
                    Text("Nguyễn Bảo Khang")
                        .font(.caption)
                        .foregroundColor(.aquaSubtitle)
                }
            }

            Spacer()

            // Badge
            Text("CỨU HỘ")
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(.aquaPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.aquaPrimary.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.aquaPrimary.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(icon: "exclamationmark.triangle.fill", label: "SOS đang chờ", value: "\(pendingRequests.count)", color: .red)
            statCard(icon: "doc.text.fill", label: "Nhiệm vụ", value: "\(myMissions.count)", color: .aquaPrimary)
            statCard(icon: "checkmark.circle.fill", label: "Hoàn thành", value: "\(completedRequests.count)", color: .green)
        }
        .padding(.horizontal, 16)
    }

    private func statCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.aquaNavy)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.aquaSubtitle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.12))
        )
    }

    // MARK: - Request Card

    private func rescuerRequestCard(_ request: SosRequest) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Row 1: Name + urgency badge + status badge
            HStack {
                Text(request.userName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.aquaNavy)

                Spacer()

                // Urgency badge
                HStack(spacing: 4) {
                    Image(systemName: request.urgencyIcon)
                        .font(.system(size: 9, weight: .bold))
                    Text(request.urgencyLabel)
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(request.urgencyColor)
                .cornerRadius(6)

                // Status badge
                Text(request.statusLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(request.statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(request.statusColor.opacity(0.1))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(request.statusColor.opacity(0.2), lineWidth: 1)
                    )
            }

            // Row 2: Description
            if let desc = request.description {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.aquaSubtitle)
                    .lineLimit(2)
            }

            // Row 3: Location
            if let loc = request.location {
                HStack(spacing: 5) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.aquaSubtitle.opacity(0.7))
                    Text(loc)
                        .font(.caption)
                        .foregroundColor(.aquaSubtitle)
                        .lineLimit(1)
                }
            }

            // Actions
            if selectedTab == 0 {
                // Pending: "Nhận nhiệm vụ"
                Button(action: { acceptRequest(request) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 12))
                        Text("Nhận nhiệm vụ")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.aquaPrimary)
                    .cornerRadius(10)
                }
            } else if selectedTab == 1 {
                // Active: "Hoàn thành" + "Huỷ"
                HStack(spacing: 10) {
                    Button(action: { completeRequest(request) }) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Hoàn thành")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.aquaPrimary)
                        .cornerRadius(10)
                    }

                    Button(action: { cancelRequest(request) }) {
                        HStack(spacing: 5) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Huỷ")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.aquaSubtitle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.aquaInputBg)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.aquaInputBorder, lineWidth: 1)
                        )
                    }
                }
            }
            // Tab 2 (completed): no actions
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundColor(.aquaSubtitle.opacity(0.4))
            Text("Không có yêu cầu nào")
                .font(.subheadline)
                .foregroundColor(.aquaSubtitle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Actions

    private func acceptRequest(_ req: SosRequest) {
        if let idx = requests.firstIndex(where: { $0.id == req.id }) {
            requests[idx].status = "in_progress"
            showToast("Đã nhận nhiệm vụ")
        }
    }

    private func completeRequest(_ req: SosRequest) {
        if let idx = requests.firstIndex(where: { $0.id == req.id }) {
            requests[idx].status = "resolved"
            showToast("Hoàn thành")
        }
    }

    private func cancelRequest(_ req: SosRequest) {
        if let idx = requests.firstIndex(where: { $0.id == req.id }) {
            requests[idx].status = "pending"
            showToast("Đã huỷ")
        }
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }

    private func toastView(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.aquaPrimary)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            .padding(.bottom, 30)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
