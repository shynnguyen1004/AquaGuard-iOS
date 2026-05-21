//
//  SettingsView.swift
//  AquaGuard
//
//  Combined Profile + Settings screen used as the Citizen "Profile" tab
//  and as a sheet from Home / Rescuer / Admin.
//

import CoreLocation
import SwiftUI

struct SettingsView: View {
    // MARK: - Dependencies / Environment

    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var devWeatherSettings = DevWeatherSettings.shared
    @StateObject private var homeVM = HomeViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(\.isPresented) var isPresented
    @Environment(\.colorScheme) var colorScheme

    /// Optional injected location service (used by the Profile tab for "Detect").
    /// When nil, a local instance is used.
    var locationService: LocationService? = nil
    @StateObject private var fallbackLocationService = LocationService()
    private var effectiveLocationService: LocationService {
        locationService ?? fallbackLocationService
    }

    private let geocoder = CLGeocoder()

    // MARK: - Profile state (editable)

    @State private var isEditing = false
    @State private var fullName = ""
    @State private var phone = ""
    @State private var emergencyContact = ""
    @State private var selectedGender: Gender = .male
    @State private var dateOfBirth = Date()
    @State private var address = ""
    @State private var gpsCoordinates = ""

    @State private var isSaving: Bool = false
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

    // MARK: - Computed

    private var userRole: String {
        TokenManager.shared.currentUser?.role.capitalized ?? "Citizen"
    }

    private var displayPhone: String {
        phone.isEmpty
            ? (TokenManager.shared.currentUser?.phoneNumber ?? "")
            : phone
    }

    // MARK: - Style

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.aquaBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        LogoHeaderView()

                        profileHeader

                        if !isEditing {
                            editProfileButton
                        }

                        if isEditing {
                            personalInfoSection
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity
                                ))
                        }

                        sectionHeader(languageManager.localize("General"))
                        generalSection

                        sectionHeader(languageManager.localize("Dev Mode"))
                        devModeSection

                        sectionHeader(languageManager.localize("Support"))
                        supportSection

                        signOutButton

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isPresented {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(languageManager.localize("Done")) {
                            dismiss()
                        }
                        .fontWeight(.semibold)
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
            .alert(languageManager.localize("Saved!"), isPresented: $showSaveSuccess) {
                Button(languageManager.localize("OK"), role: .cancel) {}
            } message: {
                Text(languageManager.localize("Your profile has been updated successfully."))
            }
            .onAppear {
                loadProfileFromBackend()
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }

    // MARK: - Profile Header (replaces old plain card)

    private var profileHeader: some View {
        HStack(spacing: 16) {
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

                Text(initialLetter)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                Circle()
                    .fill(Color.green)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.aquaCard, lineWidth: 2))
                    .offset(x: 22, y: 22)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(fullName.isEmpty ? (TokenManager.shared.currentUser?.displayName ?? "") : fullName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.aquaNavy)

                Text(displayPhone)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

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

    private var initialLetter: String {
        let source = fullName.isEmpty
            ? (TokenManager.shared.currentUser?.displayName ?? "?")
            : fullName
        return String(source.prefix(1)).uppercased()
    }

    // MARK: - Edit Profile Button

    private var editProfileButton: some View {
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

    // MARK: - Personal Information (editable)

    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 16))
                    .foregroundColor(.aquaPrimary)
                Text(languageManager.localize("Personal Information"))
                    .font(.headline)
                    .foregroundColor(.aquaNavy)
            }
            .padding(.bottom, 4)

            formField(
                label: languageManager.localize("Full Name"),
                text: $fullName,
                field: .fullName
            )

            formField(
                label: languageManager.localize("Phone Number"),
                text: $phone,
                field: .phone
            )

            formField(
                label: languageManager.localize("Emergency Contact"),
                text: $emergencyContact,
                field: .emergencyContact
            )

            genderField

            dateOfBirthField

            addressField

            HStack(spacing: 12) {
                Button(action: saveChanges) {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15))
                            Text(languageManager.localize("Save Changes"))
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
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
                .disabled(isSaving)

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

    private var genderField: some View {
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
    }

    private var dateOfBirthField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(languageManager.localize("Date of Birth"))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.aquaPrimary)

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
    }

    private var addressField: some View {
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
    }

    private func formField(
        label: String,
        text: Binding<String>,
        field: ProfileField
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.aquaPrimary)

            TextField(label, text: text)
                .font(.subheadline)
                .focused($focusedField, equals: field)
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

    // MARK: - General Section (settings)

    private var generalSection: some View {
        VStack(spacing: 0) {
            Button {
                languageManager.toggle()
            } label: {
                settingsRow(
                    icon: "globe",
                    iconBg: Color.blue.opacity(0.15),
                    iconColor: .blue,
                    title: languageManager.localize("Language"),
                    trailing: AnyView(
                        HStack(spacing: 4) {
                            Text(languageManager.current == .english ? "English" : "Tiếng Việt")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    )
                )
            }

            Divider().padding(.leading, 56)

            VStack(spacing: 12) {
                settingsRow(
                    icon: themeManager.current.icon,
                    iconBg: Color.purple.opacity(0.15),
                    iconColor: .purple,
                    title: languageManager.localize("Theme"),
                    trailing: AnyView(EmptyView())
                )

                HStack(spacing: 0) {
                    ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                themeManager.current = theme
                            }
                        } label: {
                            VStack(spacing: 5) {
                                Image(systemName: theme.icon)
                                    .font(.system(size: 18, weight: .medium))
                                Text(languageManager.localize(theme.displayName))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                themeManager.current == theme
                                    ? Color.aquaPrimary.opacity(0.2)
                                    : Color.clear
                            )
                            .foregroundColor(
                                themeManager.current == theme
                                    ? .aquaPrimary
                                    : .secondary
                            )
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(4)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            Divider().padding(.leading, 56)

            settingsRow(
                icon: "bell.badge.fill",
                iconBg: Color.red.opacity(0.12),
                iconColor: .red,
                title: languageManager.localize("Notifications"),
                trailing: AnyView(
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                )
            )

            Divider().padding(.leading, 56)

            settingsRow(
                icon: "location.fill",
                iconBg: Color.aquaPrimary.opacity(0.15),
                iconColor: .aquaPrimary,
                title: languageManager.localize("Location Services"),
                trailing: AnyView(
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                )
            )
        }
        .background(glassBackground)
        .padding(.horizontal)
    }

    // MARK: - Dev Mode Section

    private var devModeSection: some View {
        VStack(spacing: 0) {
            settingsRow(
                icon: "hammer.fill",
                iconBg: Color.orange.opacity(0.12),
                iconColor: .orange,
                title: languageManager.localize("Simulate weather status"),
                trailing: AnyView(EmptyView())
            )

            VStack(spacing: 6) {
                ForEach(WeatherStatusSimulation.allCases) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            devWeatherSettings.statusSimulation = mode
                        }
                    } label: {
                        HStack(spacing: 10) {
                            simulationIndicator(for: mode)
                            Text(languageManager.localize(mode.settingsTitleKey))
                                .font(.subheadline)
                                .fontWeight(
                                    devWeatherSettings.statusSimulation == mode ? .semibold : .regular
                                )
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 8)
                            if devWeatherSettings.statusSimulation == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.aquaPrimary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            devWeatherSettings.statusSimulation == mode
                                ? Color.aquaPrimary.opacity(0.12)
                                : Color.primary.opacity(0.04)
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            Text(languageManager.localize(
                "Dev mode uses mock location and weather for the Status Card preview."
            ))
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(glassBackground)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func simulationIndicator(for mode: WeatherStatusSimulation) -> some View {
        let size: CGFloat = 10
        switch mode {
        case .real:
            Circle()
                .fill(Color.aquaPrimary)
                .frame(width: size, height: size)
        case .safe:
            Circle()
                .fill(Color.aquaSafe)
                .frame(width: size, height: size)
        case .caution:
            Circle()
                .fill(Color.aquaWarning)
                .frame(width: size, height: size)
        case .danger:
            Circle()
                .fill(Color.aquaDanger)
                .frame(width: size, height: size)
        case .critical:
            Circle()
                .fill(Color.aquaCritical)
                .frame(width: size, height: size)
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        VStack(spacing: 0) {
            settingsRow(
                icon: "questionmark.circle.fill",
                iconBg: Color.orange.opacity(0.12),
                iconColor: .orange,
                title: languageManager.localize("Help & FAQ"),
                trailing: AnyView(
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                )
            )

            Divider().padding(.leading, 56)

            settingsRow(
                icon: "info.circle.fill",
                iconBg: Color.aquaPrimary.opacity(0.15),
                iconColor: .aquaPrimary,
                title: languageManager.localize("About AquaGuard"),
                trailing: AnyView(
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                )
            )

            Divider().padding(.leading, 56)

            settingsRow(
                icon: "checkmark.seal.fill",
                iconBg: Color.green.opacity(0.12),
                iconColor: .green,
                title: languageManager.localize("Version"),
                trailing: AnyView(
                    Text("1.0.0 (Beta)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                )
            )
        }
        .background(glassBackground)
        .padding(.horizontal)
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button {
            homeVM.signOut()
            if isPresented {
                dismiss()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.body)
                Text(languageManager.localize("Sign Out"))
                    .fontWeight(.semibold)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: Color.red.opacity(0.06), radius: 8, x: 0, y: 4)
            )
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Backend

    private func loadProfileFromBackend() {
        if let user = TokenManager.shared.currentUser {
            if fullName.isEmpty { fullName = user.displayName }
            if phone.isEmpty { phone = user.phoneNumber }
            if let ec = user.emergencyContact, !ec.isEmpty { emergencyContact = ec }
            if let g = user.gender, !g.isEmpty {
                selectedGender = Gender.allCases.first(where: { $0.rawValue.lowercased() == g.lowercased() }) ?? .male
            }
            if let addr = user.address, !addr.isEmpty { address = addr }
        }

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
                }
            } catch {
                print("[Settings] Failed to load profile: \(error.localizedDescription)")
            }
        }
    }

    private func detectLocation() {
        isDetectingLocation = true

        switch effectiveLocationService.authorizationStatus {
        case .notDetermined:
            effectiveLocationService.requestPermission()
        case .restricted, .denied:
            address = "Location permission denied"
            isDetectingLocation = false
            return
        default:
            break
        }

        effectiveLocationService.requestCurrentLocation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let coordinate = effectiveLocationService.currentLocation ?? CLLocationCoordinate2D(
                latitude: 10.77269, longitude: 106.65781
            )

            gpsCoordinates = String(
                format: "%.5f, %.5f",
                coordinate.latitude, coordinate.longitude
            )

            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            geocoder.cancelGeocode()
            geocoder.reverseGeocodeLocation(
                location,
                preferredLocale: Locale(identifier: "vi_VN")
            ) { placemarks, _ in
                Task { @MainActor in
                    if let placemark = placemarks?.first {
                        var streetParts: [String] = []
                        if let number = placemark.subThoroughfare { streetParts.append(number) }
                        if let street = placemark.thoroughfare { streetParts.append(street) }

                        var fullParts: [String] = []
                        if !streetParts.isEmpty { fullParts.append(streetParts.joined(separator: " ")) }
                        if let ward = placemark.subLocality { fullParts.append(ward) }
                        if let district = placemark.subAdministrativeArea { fullParts.append(district) }
                        if let city = placemark.locality { fullParts.append(city) }

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
                print("[Settings] Save failed: \(error.localizedDescription)")
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
        loadProfileFromBackend()
    }

    // MARK: - Layout helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(1)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }

    private func settingsRow(
        icon: String,
        iconBg: Color,
        iconColor: Color,
        title: String,
        trailing: AnyView
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconBg)
                .cornerRadius(8)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer()

            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}
