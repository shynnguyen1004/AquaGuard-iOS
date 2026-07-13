//
//  SosSortFilter.swift
//  AquaGuard
//
//  Sort + filter for SOS request lists — mirrors the web's Rescue Requests
//  queue panel (sort by priority/newest/oldest/age, filter by age group,
//  gender, and city). Shared between "Yêu cầu" (RescuerRequestsView) and
//  "Nhiệm vụ" (RescuerDashboardView).
//
//  City is extracted from the address string only (no reverse-geocoding
//  network call) — matches the web's regex fallback, not its Nominatim path.
//

import SwiftUI

// MARK: - Sort

enum SosSortKey: String, CaseIterable, Identifiable {
    case priority, newest, oldest, ageAsc, ageDesc

    var id: String { rawValue }

    var label: String {
        switch self {
        case .priority: return "Ưu tiên"
        case .newest: return "Mới nhất"
        case .oldest: return "Cũ nhất"
        case .ageAsc: return "Tuổi: Thấp–Cao"
        case .ageDesc: return "Tuổi: Cao–Thấp"
        }
    }
}

// MARK: - Age Group

struct SosAgeGroup: Identifiable {
    let key: String
    let label: String
    let min: Int
    let max: Int
    var id: String { key }
}

let sosAgeGroups: [SosAgeGroup] = [
    SosAgeGroup(key: "0-16", label: "0-16", min: 0, max: 16),
    SosAgeGroup(key: "16-30", label: "16-30", min: 16, max: 30),
    SosAgeGroup(key: "30-50", label: "30-50", min: 30, max: 50),
    SosAgeGroup(key: "50-90", label: "50-90", min: 50, max: 90),
]

// MARK: - Gender

enum SosGenderFilter: String, CaseIterable, Identifiable {
    case male, female, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .male: return "Nam"
        case .female: return "Nữ"
        case .other: return "Khác"
        }
    }
}

// MARK: - City extraction (address string only, no network)

/// Pulls a city name out of a Vietnamese address string, e.g.
/// "Hẻm 15A Lê Thánh Tôn, Thành phố Thủ Đức" → "Thủ Đức".
/// Requests whose address doesn't contain "thành phố ..." won't get a city —
/// this is a lighter-weight stand-in for the web's GPS reverse-geocoding.
func extractCity(fromLocation location: String?) -> String? {
    guard let location, !location.isEmpty else { return nil }
    guard let range = location.range(of: #"th[àa]nh ph[ốo]\s+([^,]+)"#, options: [.regularExpression, .caseInsensitive]) else {
        return nil
    }
    let match = String(location[range])
    let prefixPattern = #"^th[àa]nh ph[ốo]\s+"#
    let withoutPrefix = match.replacingOccurrences(of: prefixPattern, with: "", options: [.regularExpression, .caseInsensitive])
    let trimmed = withoutPrefix.trimmingCharacters(in: .whitespaces)
    return trimmed.isEmpty ? nil : trimmed
}

// MARK: - Filtering + Sorting

func sosFilterAndSort(
    _ requests: [SosRequest],
    sortKey: SosSortKey,
    ageGroups: Set<String>,
    genders: Set<String>,
    cities: Set<String>
) -> [SosRequest] {
    let filtered = requests.filter { request in
        let passAge: Bool = {
            guard !ageGroups.isEmpty else { return true }
            guard let age = request.userAge else { return false }
            return ageGroups.contains { key in
                guard let group = sosAgeGroups.first(where: { $0.key == key }) else { return false }
                return age >= group.min && age < group.max
            }
        }()

        let passGender: Bool = {
            guard !genders.isEmpty else { return true }
            guard let gender = request.userGender else { return false }
            return genders.contains(gender)
        }()

        let passCity: Bool = {
            guard !cities.isEmpty else { return true }
            guard let city = extractCity(fromLocation: request.location) else { return false }
            return cities.contains(city)
        }()

        return passAge && passGender && passCity
    }

    return filtered.sorted { a, b in
        switch sortKey {
        case .newest:
            return a.createdAt > b.createdAt
        case .oldest:
            return a.createdAt < b.createdAt
        case .ageAsc:
            return (a.userAge ?? Int.max) < (b.userAge ?? Int.max)
        case .ageDesc:
            return (a.userAge ?? -1) > (b.userAge ?? -1)
        case .priority:
            let statusPriority: (String) -> Int = { $0 == "pending" ? 2 : $0 == "in_progress" ? 1 : 0 }
            let sp = statusPriority(a.status) - statusPriority(b.status)
            if sp != 0 { return sp > 0 }
            let urgencyRank: [String: Int] = ["critical": 3, "high": 2, "medium": 1, "low": 0]
            let ur = (urgencyRank[a.urgency] ?? 0) - (urgencyRank[b.urgency] ?? 0)
            if ur != 0 { return ur > 0 }
            return a.createdAt > b.createdAt
        }
    }
}

/// Unique city names present in the given list, for populating the city filter's options.
func sosCityOptions(for requests: [SosRequest]) -> [String] {
    let cities = requests.compactMap { extractCity(fromLocation: $0.location) }
    return Array(Set(cities)).sorted()
}
