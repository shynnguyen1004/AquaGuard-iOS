//
//  SosRequestComponents.swift
//  AquaGuard
//
//  Shared pieces reused between "Yêu cầu" (RescuerRequestsView) and
//  "Nhiệm vụ" (RescuerDashboardView) detail sheets — the photo carousel
//  citizens attach to an SOS report, plus its fullscreen viewer.
//

import SwiftUI

// MARK: - Photo Carousel

struct SosPhotoCarousel: View {
    let imageURLs: [String]
    @State private var fullscreenURL: String?

    var body: some View {
        if !imageURLs.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 12))
                    Text("Hình ảnh (\(imageURLs.count))")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.aquaSubtitle)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(imageURLs, id: \.self) { urlString in
                            AsyncImage(url: URL(string: urlString)) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(width: 220, height: 150)
                                        .overlay(ProgressView())
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 220, height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .onTapGesture { fullscreenURL = urlString }
                                case .failure:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(width: 220, height: 150)
                                        .overlay(
                                            Image(systemName: "photo.fill")
                                                .foregroundColor(.gray.opacity(0.4))
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
            }
            .fullScreenCover(item: Binding<SosFullscreenImage?>(
                get: { fullscreenURL.map { SosFullscreenImage(url: $0) } },
                set: { fullscreenURL = $0?.url }
            )) { item in
                SosFullscreenImageView(urlString: item.url)
            }
        }
    }
}

private struct SosFullscreenImage: Identifiable {
    let url: String
    var id: String { url }
}

private struct SosFullscreenImageView: View {
    let urlString: String
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: URL(string: urlString)) { phase in
                switch phase {
                case .empty:
                    ProgressView().tint(.white)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in scale = value.magnification }
                                .onEnded { _ in withAnimation { scale = 1.0 } }
                        )
                case .failure:
                    VStack(spacing: 12) {
                        Image(systemName: "photo.fill")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Không tải được ảnh")
                            .foregroundColor(.gray)
                    }
                @unknown default:
                    EmptyView()
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(16)
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Compact badge helpers

struct SosUrgencyBadge: View {
    let request: SosRequest

    var body: some View {
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
}

struct SosStatusBadge: View {
    let request: SosRequest

    var body: some View {
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
}
