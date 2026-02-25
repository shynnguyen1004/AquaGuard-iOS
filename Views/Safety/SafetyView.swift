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
    // State to toggle carrier selection menu
    @State private var showCarrierSelection = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // --- HEADER LOGO ---
                    LogoHeaderView()

                    Text("Emergency Assistance")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)

                    // --- KHỐI CHỨC NĂNG KHẨN CẤP (MỚI) ---
                    HStack(spacing: 15) {

                        // LEFT COLUMN: Emergency phone numbers
                        VStack(spacing: 10) {
                            EmergencyCallButton(
                                icon: "shield.fill", number: "113", label: "Police", color: .red)
                            EmergencyCallButton(
                                icon: "fire.extinguisher.fill", number: "114",
                                label: "Fire Brigade", color: .red)
                            EmergencyCallButton(
                                icon: "cross.case.fill", number: "115", label: "Ambulance",
                                color: .red)
                        }
                        .frame(maxWidth: .infinity)

                        // RIGHT COLUMN: Universal 4G registration button
                        Button(action: {
                            showCarrierSelection = true
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 64))
                                    .fontWeight(.bold)

                                Text("4G SOS")
                                    //.font(.headline)
                                    .font(.system(size: 16))
                                    .fontWeight(.heavy)

                                Text("Tap to Register")
                                    .font(.caption2)
                                    .opacity(0.8)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)  // Height matches the two buttons combined
                            .background(Color.aquaPrimary)
                            .cornerRadius(16)
                            .shadow(color: .aquaPrimary.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        // Carrier selection menu (shown on button tap)
                        .confirmationDialog(
                            "Select your Carrier", isPresented: $showCarrierSelection,
                            titleVisibility: .visible
                        ) {
                            ForEach(MockData.emergencyPackages, id: \.carrier) { pkg in
                                Button("\(pkg.carrier) - \(pkg.name)") {
                                    SMSHelper.send(number: pkg.number, message: pkg.syntax)
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                    // ----------------------------------------

                    Text("Safety Guides")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)
                        .padding(.top)

                    // Safety guides list
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
                            "Listen to emergency broadcasts",
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
                            "Watch for structural damage",
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
                            "Turn around if water is rising",
                        ]
                    )
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .background(Color.aquaBackground)
        }
    }
}

// MARK: - EmergencyCallButton (left column)
struct EmergencyCallButton: View {
    let icon: String
    let number: String
    let label: String
    let color: Color

    var body: some View {
        Link(destination: URL(string: "tel:\(number)")!) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)

                VStack(alignment: .leading) {
                    Text(label)
                        .font(.caption)
                        .fontWeight(.bold)
                    //.frame(maxWidth: .inftrinity, alignment: .trailing)

                    Text(number)
                        .font(.caption2)
                        .fontWeight(.bold)
                    //.frame(maxWidth: .infinity, alignment: .trailing)

                }

                Spacer()
            }
            .padding(10)
            .foregroundColor(.white)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 2)
        }
    }
}
