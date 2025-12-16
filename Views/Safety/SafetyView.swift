//
//  SafetyView.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 16/12/25.
//

import SwiftUI

struct SafetyStep: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundColor(.aquaPrimary.opacity(0.5))
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.aquaNavy.opacity(0.8))
        }
    }
}

struct SafetySection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let tag: String
    let tagColor: Color
    let steps: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor)
                        .frame(width: 45, height: 45)
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.title3)
                }
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.aquaNavy)
                    Text(tag)
                        .font(.caption2).bold()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tagColor.opacity(0.1))
                        .foregroundColor(tagColor)
                        .cornerRadius(4)
                }
                Spacer()
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(steps, id: \.self) { step in
                    SafetyStep(text: step)
                }
            }
            .padding()
        }
        .background(Color.aquaCard)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 10)
    }
}

struct SafetyView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Emergency Contacts Header
                    VStack(alignment: .leading, spacing: 15) {
                        Label("Emergency Contacts", systemImage: "phone.fill")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        VStack(spacing: 1) {
                            ContactRow(name: "Emergency Services", phone: "113, 114, 115")
                            Divider()
                            ContactRow(name: "Flood Hotline", phone: "1800 6132")
                        }
                        .background(Color.aquaCard)
                        .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    
                    // Safety Sections
                    SafetySection(
                        icon: "house.fill",
                        iconColor: .red,
                        title: "During a Flood",
                        tag: "Critical",
                        tagColor: .red,
                        steps: [
                            "Move to higher ground immediately",
                            "Avoid walking or driving through flood waters",
                            "Stay away from downed power lines",
                            "Listen to emergency broadcasts"
                        ]
                    )
                    .padding(.horizontal)
                    
                    SafetySection(
                        icon: "doc.text.fill",
                        iconColor: .green,
                        title: "After a Flood",
                        tag: "Medium",
                        tagColor: .blue,
                        steps: [
                            "Return home only when authorities say it's safe",
                            "Document damage with photos",
                            "Clean and disinfect everything that got wet",
                            "Watch for structural damage"
                        ]
                    )
                    .padding(.horizontal)
                    
                    SafetySection(
                        icon: "car.fill",
                        iconColor: .purple,
                        title: "Vehicle Safety",
                        tag: "High",
                        tagColor: .orange,
                        steps: [
                            "Never drive through flooded roads",
                            "Turn around if water is rising"
                        ]
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.aquaBackground)
            .navigationTitle("AquaGuard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ContactRow: View {
    let name: String
    let phone: String
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name).font(.subheadline).bold()
                Text(phone).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
        }
        .padding()
    }
}
