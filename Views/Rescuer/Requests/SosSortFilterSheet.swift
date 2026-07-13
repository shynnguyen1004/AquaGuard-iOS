//
//  SosSortFilterSheet.swift
//  AquaGuard
//
//  Sort + filter bottom sheet for SOS request lists — mirrors the web's
//  Rescue Requests queue panel (Sort / Age Group / Gender / City). Shared
//  between "Yêu cầu" (RescuerRequestsView) and "Nhiệm vụ" (RescuerDashboardView).
//

import SwiftUI

// MARK: - Trigger button (shows current sort, opens the sheet)

struct SosSortFilterTrigger: View {
    let sortKey: SosSortKey
    let hasActiveFilters: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 12, weight: .semibold))
                Text(sortKey.label)
                    .font(.system(size: 13, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))

                if hasActiveFilters {
                    Circle()
                        .fill(Color.aquaPrimary)
                        .frame(width: 6, height: 6)
                }
            }
            .foregroundColor(.aquaNavy)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.aquaCard)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.aquaInputBorder, lineWidth: 1)
            )
        }
    }
}

// MARK: - Sheet

struct SosSortFilterSheet: View {
    @Binding var sortKey: SosSortKey
    @Binding var selectedAgeGroups: Set<String>
    @Binding var selectedGenders: Set<String>
    @Binding var selectedCities: Set<String>
    let cityOptions: [String]
    @Environment(\.dismiss) var dismiss

    private var hasActiveFilters: Bool {
        !selectedAgeGroups.isEmpty || !selectedGenders.isEmpty || !selectedCities.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    sortSection
                    ageGroupSection
                    genderSection
                    if !cityOptions.isEmpty {
                        citySection
                    }

                    if hasActiveFilters {
                        Button(action: {
                            selectedAgeGroups.removeAll()
                            selectedGenders.removeAll()
                            selectedCities.removeAll()
                        }) {
                            Text("Xóa bộ lọc")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.aquaSubtitle)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.aquaInputBg)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.aquaBackground)
            .navigationTitle("Sắp xếp & Lọc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(.aquaPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Sections

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("SẮP XẾP")
            VStack(spacing: 2) {
                ForEach(SosSortKey.allCases) { key in
                    Button(action: { sortKey = key }) {
                        HStack {
                            Text(key.label)
                                .font(.subheadline)
                                .fontWeight(sortKey == key ? .bold : .regular)
                                .foregroundColor(sortKey == key ? .aquaPrimary : .aquaNavy)
                            Spacer()
                            if sortKey == key {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.aquaPrimary)
                            }
                        }
                        .padding(.vertical, 11)
                        .padding(.horizontal, 12)
                        .background(sortKey == key ? Color.aquaPrimary.opacity(0.08) : Color.clear)
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    private var ageGroupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("NHÓM TUỔI")
            pillsGrid(
                items: sosAgeGroups.map { ($0.key, $0.label) },
                selected: $selectedAgeGroups
            )
        }
    }

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("GIỚI TÍNH")
            pillsGrid(
                items: SosGenderFilter.allCases.map { ($0.rawValue, $0.label) },
                selected: $selectedGenders
            )
        }
    }

    private var citySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("THÀNH PHỐ")
            pillsGrid(
                items: cityOptions.map { ($0, $0) },
                selected: $selectedCities
            )
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.aquaSubtitle)
    }

    private func pillsGrid(items: [(key: String, label: String)], selected: Binding<Set<String>>) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.key) { item in
                let isSelected = selected.wrappedValue.contains(item.key)
                Button(action: {
                    if isSelected {
                        selected.wrappedValue.remove(item.key)
                    } else {
                        selected.wrappedValue.insert(item.key)
                    }
                }) {
                    Text(item.label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? .white : .aquaNavy)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.aquaPrimary : Color.aquaInputBg)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.clear : Color.aquaInputBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
