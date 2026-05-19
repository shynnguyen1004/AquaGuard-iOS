//
//  ProfileView.swift
//  AquaGuard
//
//  User profile tab — displays user info, editable personal
//  information, activity stats, and quick access to settings.
//  Now uses backend data via TokenManager + API.
//

import CoreLocation
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.colorScheme) var colorScheme

    // Shared location service (same as SOS tab)
    var locationService: LocationService
    private let geocoder = CLGeocoder()

    // Settings navigation
    @State private var showSettings = false
    @State private var isEditing = false

    // Editable personal info — loaded from backend on appear
    @State private var fullName = ""
    @State private var phone = ""
    @State private var emergencyContact = ""
    @State private var selectedGender: Gender = .male
    @State private var dateOfBirth = Date()
    @State private var address = ""
    @State private var gpsCoordinates = ""

    // Stats from backend
    @State private var sosSentCount: Int = 0
    @State private var sosResolvedCount: Int = 0
    @State private var familyCount: Int = 0
    @State private var memberSince: String = ""
    @State private var recentRequests: [APIRescueRequest] = []
    @State private var isSaving: Bool = false

    // User role from TokenManager
    private var userRole: String {
        TokenManager.shared.currentUser?.role.capitalized ?? "Citizen"
    }

    // UI states
    @State private var showSaveSuccess = false
    @State private var isDetectingLocation = false
    @State private var showDatePicker = false
    @FocusState private var focusedField: ProfileField?

    enum ProfileField {
        case fullName, phone, emergencyContact, address
    }

    enum Gender: String, CaseIterable {
        case male = "Nam"
        case female = "Nữ"
        case other = "Khác"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Profile Header ────────────────────────────
                    profileHeader

                    // ── Edit Profile Button (only when NOT editing) ──
                    if !isEditing {
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isEditing = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 16))
                                Text(languageManager.localize("Edit Profile"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.aquaPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.aquaPrimary.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.aquaPrimary.opacity(0.25), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal, 16)
                    }

                    // ── Personal Information (only when editing) ──
                    if isEditing {
                        personalInfoSection
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            ))
                    }

                    // ── Stats Cards ──────────────────────────────
                    statsGrid

                    // ── Recent Activity ───────────────────────────
                    recentActivity

                    // ── Menu Items ────────────────────────────────
                    menuSection

                    Spacer(minLength: 30)
                }
                .padding(.top, 10)
            }
            .background(Color.aquaBackground)
            .navigationTitle(languageManager.localize("Profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.aquaPrimary)
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(languageManager.localize("Done")) {
                        focusedField = nil
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.aquaPrimary)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(languageManager)
            }
            .alert(languageManager.localize("Saved!"), isPresented: $showSaveSuccess) {
                Button(languageManager.localize("OK"), role: .cancel) {}
            } message: {
                Text(languageManager.localize("Your profile has been updated successfully."))
            }
            .onAppear {
                loadProfileFromBackend()
            }
        }
    }

    // MARK: - Load Profile from Backend

    private func loadProfileFromBackend() {
        // Pre-fill from TokenManager (instant, no network)
        if let user = TokenManager.shared.currentUser {
            if fullName.isEmpty { fullName = user.displayName }
            if phone.isEmpty { phone = user.phoneNumber }
            if let ec = user.emergencyContact, !ec.isEmpty { emergencyContact = ec }
            if let g = user.gender, !g.isEmpty {
                selectedGender = Gender.allCases.first(where: { $0.rawValue.lowercased() == g.lowercased() }) ?? .male
            }
            if let addr = user.address, !addr.isEmpty { address = addr }
            if let createdAt = user.createdAt {
                let year = String(createdAt.prefix(4))
                memberSince = year
            }
        }

        // Fetch fresh profile from backend
        Task {
            do {
                let response: APIResponse<APIUser> = try await APIService.shared.getRaw("/auth/profile")
                if let profile = response.data {
                    fullName = profile.displayName
                    phone = profile.phoneNumber
                    if let ec = profile.emergencyContact, !ec.isEmpty { emergencyContact = ec }
                    if let g = profile.gender, !g.isEmpty {
                        selectedGender = Gender.allCases.first(where: { $0.rawValue.lowercased() == g.lowercased() }) ?? .male
                    }
                    if let dobStr = profile.dateOfBirth, !dobStr.isEmpty {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        if let dob = formatter.date(from: String(dobStr.prefix(10))) {
                            dateOfBirth = dob
                        }
                    }
                    if let addr = profile.address, !addr.isEmpty { address = addr }
                    if let lat = profile.latitude, let lng = profile.longitude {
                        gpsCoordinates = String(format: "%.5f, %.5f", lat, lng)
                    }
                    if let createdAt = profile.createdAt {
                        memberSince = String(createdAt.prefix(4))
                    }
                }
            } catch {
                print("[Profile] Failed to load profile: \(error.localizedDescription)")
            }
        }

        // Fetch SOS stats
        Task {
            do {
                let response: APIResponse<[APIRescueRequest]> = try await APIService.shared.getRaw("/sos/my")
                if let requests = response.data {
                    sosSentCount = requests.count
                    sosResolvedCount = requests.filter { $0.status == "resolved" }.count
                    recentRequests = Array(requests.prefix(4))
                }
            } catch {
                print("[Profile] Failed to load SOS stats: \(error.localizedDescription)")
            }
        }

        // Fetch family count
        Task {
            do {
                let response: APIResponse<[APIFamilyMember]> = try await APIService.shared.getRaw("/family/members")
                if let members = response.data {
                    familyCount = members.count
                }
            } catch {
                print("[Profile] Failed to load family count: \(error.localizedDescription)")
            }
        }

    }

    // MARK: - Profile Header (compact card like reference)

    private var profileHeader: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.aquaPrimary, .aquaPrimary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Text(String(fullName.prefix(1)).uppercased())
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                // Online dot
                Circle()
                    .fill(Color.green)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.aquaCard, lineWidth: 2))
                    .offset(x: 22, y: 22)
            }

            // Info
            VStack(alignment: .leading, spacing: 5) {
                Text(fullName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.aquaNavy)

                Text(phone)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Role badge
                Text(userRole)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                    .background(Color.aquaPrimary)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.aquaCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.aquaInputBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Personal Information (editable form)

    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Section header
            HStack(spacing: 10) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 16))
                    .foregroundColor(.aquaPrimary)
                Text(languageManager.localize("Personal Information"))
                    .font(.headline)
                    .foregroundColor(.aquaNavy)
            }
            .padding(.bottom, 4)

            // Row 1: Full Name (full width)
            formField(
                label: languageManager.localize("Full Name"),
                text: $fullName,
                icon: nil,
                field: .fullName
            )

            // Row 2: Phone Number
            formField(
                label: languageManager.localize("Phone Number"),
                text: $phone,
                icon: nil,
                field: .phone
            )

            // Row 3: Emergency Contact
            formField(
                label: languageManager.localize("Emergency Contact"),
                text: $emergencyContact,
                icon: nil,
                field: .emergencyContact
            )

            // Row 4: Gender
            VStack(alignment: .leading, spacing: 6) {
                Text(languageManager.localize("Gender"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.aquaPrimary)

                Menu {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Button(action: { selectedGender = gender }) {
                            HStack {
                                Text(gender.rawValue)
                                if selectedGender == gender {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedGender.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.aquaNavy)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.aquaInputBg)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.aquaInputBorder, lineWidth: 1)
                    )
                }
            }

            // Row 5: Date of Birth (full year)
            VStack(alignment: .leading, spacing: 6) {
                Text(languageManager.localize("Date of Birth"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.aquaPrimary)

                // Formatted date button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showDatePicker.toggle()
                    }
                }) {
                    HStack {
                        Text({
                            let formatter = DateFormatter()
                            formatter.dateFormat = "dd/MM/yyyy"
                            return formatter.string(from: dateOfBirth)
                        }())
                        .font(.subheadline)
                        .foregroundColor(.aquaNavy)

                        Spacer()

                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.aquaPrimary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.aquaInputBg)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.aquaInputBorder, lineWidth: 1)
                    )
                }

                // Expandable date picker
                if showDatePicker {
                    DatePicker(
                        "",
                        selection: $dateOfBirth,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(.aquaPrimary)
                    .padding(8)
                    .background(Color.aquaInputBg)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.aquaInputBorder, lineWidth: 1)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }

            // Row 4: Address (full width) + Detect Location button
            VStack(alignment: .leading, spacing: 6) {
                Text(languageManager.localize("Address"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.aquaPrimary)

                HStack(spacing: 10) {
                    TextField(
                        languageManager.localize("Enter your address"),
                        text: $address
                    )
                    .font(.subheadline)
                    .focused($focusedField, equals: .address)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.aquaInputBg)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.aquaInputBorder, lineWidth: 1)
                    )

                    // Detect location button
                    Button(action: detectLocation) {
                        HStack(spacing: 6) {
                            if isDetectingLocation {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(.white)
                            } else {
                                Image(systemName: "location.viewfinder")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            Text(languageManager.localize("Detect"))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.25, green: 0.35, blue: 0.50),
                                    Color(red: 0.30, green: 0.40, blue: 0.55),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(isDetectingLocation)
                }

                // GPS coordinates row
                if !gpsCoordinates.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "mappin")
                            .font(.system(size: 11))
                            .foregroundColor(.aquaPrimary)
                        Text(gpsCoordinates)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
            }

            // Save + Cancel buttons
            HStack(spacing: 12) {
                Button(action: saveChanges) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15))
                        Text(languageManager.localize("Save Changes"))
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.aquaPrimary, Color(red: 0.28, green: 0.65, blue: 0.68)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: .aquaPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
                }

                Button(action: cancelEditing) {
                    Text(languageManager.localize("Cancel"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(14)
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.aquaCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.aquaInputBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Form Field Helper

    private func formField(
        label: String,
        text: Binding<String>,
        icon: String?,
        field: ProfileField
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.aquaPrimary)

            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                TextField(label, text: text)
                    .font(.subheadline)
                    .focused($focusedField, equals: field)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.aquaInputBg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.aquaInputBorder, lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions

    private func detectLocation() {
        isDetectingLocation = true

        // Request GPS from LocationService
        switch locationService.authorizationStatus {
        case .notDetermined:
            locationService.requestPermission()
        case .restricted, .denied:
            address = "Location permission denied"
            isDetectingLocation = false
            return
        default:
            break
        }

        locationService.requestCurrentLocation()

        // Wait briefly for GPS fix, then geocode
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
            let coordinate = locationService.currentLocation ?? CLLocationCoordinate2D(
                latitude: 10.77269, longitude: 106.65781
            )

            // Update GPS string
            gpsCoordinates = String(
                format: "%.5f, %.5f",
                coordinate.latitude, coordinate.longitude
            )

            // Reverse geocode to address (Vietnamese locale)
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            geocoder.cancelGeocode()
            geocoder.reverseGeocodeLocation(
                location,
                preferredLocale: Locale(identifier: "vi_VN")
            ) { placemarks, error in
                Task { @MainActor in
                    if let placemark = placemarks?.first {
                        var streetParts: [String] = []
                        if let number = placemark.subThoroughfare {
                            streetParts.append(number)
                        }
                        if let street = placemark.thoroughfare {
                            streetParts.append(street)
                        }

                        var fullParts: [String] = []
                        if !streetParts.isEmpty {
                            fullParts.append(streetParts.joined(separator: " "))
                        }
                        if let ward = placemark.subLocality {
                            fullParts.append(ward)
                        }
                        if let district = placemark.subAdministrativeArea {
                            fullParts.append(district)
                        }
                        if let city = placemark.locality {
                            fullParts.append(city)
                        }

                        if fullParts.count >= 2 {
                            address = fullParts.joined(separator: ", ")
                        } else if let name = placemark.name, !name.isEmpty {
                            address = name
                        } else {
                            address = fullParts.joined(separator: ", ")
                        }
                    } else {
                        address = "Unable to resolve address"
                    }
                    isDetectingLocation = false
                }
            }
        }
    }

    private func saveChanges() {
        focusedField = nil
        isSaving = true

        Task {
            do {
                let dobFormatter = DateFormatter()
                dobFormatter.dateFormat = "yyyy-MM-dd"
                let dobString = dobFormatter.string(from: dateOfBirth)

                // Map gender to backend format
                let genderMap: [Gender: String] = [.male: "male", .female: "female", .other: "other"]

                let body: [String: Any] = [
                    "displayName": fullName,
                    "emergencyContact": emergencyContact,
                    "gender": genderMap[selectedGender] ?? "male",
                    "dateOfBirth": dobString,
                    "address": address,
                ]

                let _: APIResponse<APIUser> = try await APIService.shared.putRaw("/auth/profile", body: body)

                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isEditing = false
                }
                isSaving = false
                showSaveSuccess = true
            } catch {
                print("[Profile] Save failed: \(error.localizedDescription)")
                isSaving = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isEditing = false
                }
            }
        }
    }

    private func cancelEditing() {
        focusedField = nil
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isEditing = false
        }
        // Reload from backend to discard changes
        loadProfileFromBackend()
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localize("Activity Summary"))
                .font(.headline)
                .foregroundColor(.aquaNavy)
                .padding(.horizontal, 20)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatCard(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .aquaDanger,
                    value: "\(sosSentCount)",
                    label: languageManager.localize("SOS Sent"),
                    trend: nil
                )
                StatCard(
                    icon: "checkmark.shield.fill",
                    iconColor: .aquaSafe,
                    value: "\(sosResolvedCount)",
                    label: languageManager.localize("Resolved"),
                    trend: nil
                )
                StatCard(
                    icon: "person.2.fill",
                    iconColor: .aquaPrimary,
                    value: "\(familyCount)",
                    label: languageManager.localize("Family"),
                    trend: nil
                )
                StatCard(
                    icon: "calendar",
                    iconColor: .orange,
                    value: memberSince.isEmpty ? "-" : memberSince,
                    label: languageManager.localize("Member Since"),
                    trend: nil
                )
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Recent Activity

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(languageManager.localize("Recent Activity"))
                    .font(.headline)
                    .foregroundColor(.aquaNavy)
                Spacer()
            }
            .padding(.horizontal, 20)

            if recentRequests.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text(languageManager.localize("No recent activity"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.aquaCard)
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
                )
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentRequests.enumerated()), id: \.element.id) { index, request in
                        let statusIcon: String = {
                            switch request.status {
                            case "resolved": return "checkmark.circle.fill"
                            case "in_progress": return "arrow.triangle.2.circlepath"
                            case "assigned": return "person.badge.clock"
                            default: return "exclamationmark.triangle.fill"
                            }
                        }()
                        let statusColor: Color = {
                            switch request.status {
                            case "resolved": return .green
                            case "in_progress": return .aquaPrimary
                            case "assigned": return .orange
                            default: return .red
                            }
                        }()

                        HStack(spacing: 14) {
                            Image(systemName: statusIcon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(statusColor)
                                .frame(width: 34, height: 34)
                                .background(statusColor.opacity(0.12))
                                .cornerRadius(10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("SOS Request")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.aquaNavy)
                                Text(request.location ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(request.sosStatus.displayName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(statusColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(statusColor.opacity(0.12))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if index < recentRequests.count - 1 {
                            Divider()
                                .padding(.leading, 64)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.aquaCard)
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
                )
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Menu Section

    private var menuSection: some View {
        VStack(spacing: 0) {
            menuRow(icon: "bell.badge.fill", iconColor: .red, title: languageManager.localize("Notifications"), badge: "3")
            Divider().padding(.leading, 60)
            menuRow(icon: "shield.checkered", iconColor: .aquaPrimary, title: languageManager.localize("Privacy & Security"), badge: nil)
            Divider().padding(.leading, 60)
            menuRow(icon: "questionmark.circle.fill", iconColor: .orange, title: languageManager.localize("Help & Support"), badge: nil)
            Divider().padding(.leading, 60)
            menuRow(icon: "info.circle.fill", iconColor: .blue, title: languageManager.localize("About AquaGuard"), badge: nil)
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .padding(.horizontal, 16)
    }

    private func menuRow(icon: String, iconColor: Color, title: String, badge: String?) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 34, height: 34)
                .background(iconColor.opacity(0.12))
                .cornerRadius(10)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.aquaNavy)

            Spacer()

            if let badge = badge {
                Text(badge)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.aquaDanger)
                    .cornerRadius(10)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let trend: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
                    .frame(width: 30, height: 30)
                    .background(iconColor.opacity(0.12))
                    .cornerRadius(8)
                Spacer()
                if let trend = trend {
                    Text(trend)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.aquaSafe)
                }
            }

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.aquaNavy)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.aquaCard)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
}

