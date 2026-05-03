//
//  RescuerRequestsView.swift
//  AquaGuard
//
//  Rescuer "Yêu cầu" tab — shows only pending SOS requests.
//  Simpler version of Dashboard, focused on new incoming requests.
//

import SwiftUI

struct RescuerRequestsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var requests = SosRequest.dummyRequests
    @State private var toastMessage: String?

    private var pendingRequests: [SosRequest] {
        requests.filter { $0.status == "pending" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.aquaBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        // Header
                        HStack(spacing: 10) {
                            Image(systemName: "light.beacon.max.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.red)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Yêu cầu SOS")
                                    .font(.headline)
                                    .foregroundColor(.aquaNavy)
                                Text("\(pendingRequests.count) yêu cầu đang chờ xử lý")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.aquaCard)
                                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                        )
                        .padding(.horizontal, 16)

                        // Request list (pending only)
                        if pendingRequests.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green.opacity(0.4))
                                Text("Không có yêu cầu mới")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 80)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(pendingRequests) { req in
                                    pendingCard(req)
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
                    Text(msg)
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
        }
    }

    private func pendingCard(_ request: SosRequest) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Name + urgency
            HStack {
                Text(request.userName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.aquaNavy)

                Spacer()

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
            }

            if let desc = request.description {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if let loc = request.location {
                HStack(spacing: 5) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text(loc)
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Button(action: {
                if let idx = requests.firstIndex(where: { $0.id == request.id }) {
                    requests[idx].status = "in_progress"
                    showToast("Đã nhận nhiệm vụ")
                }
            }) {
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
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }
}
