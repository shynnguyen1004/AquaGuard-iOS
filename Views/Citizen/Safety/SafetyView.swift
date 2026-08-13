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
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // --- HEADER LOGO ---
                    LogoHeaderView()

                    Text(languageManager.localize("Emergency Assistance"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)

                    // --- KHỐI CHỨC NĂNG KHẨN CẤP (MỚI) ---
                    HStack(spacing: 15) {

                        // LEFT COLUMN: Emergency phone numbers
                        VStack(spacing: 10) {
                            EmergencyCallButton(
                                icon: "shield.fill", number: "113",
                                label: languageManager.localize("Police"), color: .red)
                            EmergencyCallButton(
                                icon: "fire.extinguisher.fill", number: "114",
                                label: languageManager.localize("Fire Brigade"), color: .red)
                            EmergencyCallButton(
                                icon: "cross.case.fill", number: "115",
                                label: languageManager.localize("Ambulance"),
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

                                Text(languageManager.localize("Tap to Register"))
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
                            languageManager.localize("Select your Carrier"),
                            isPresented: $showCarrierSelection,
                            titleVisibility: .visible
                        ) {
                            ForEach(MockData.emergencyPackages, id: \.carrier) { pkg in
                                Button("\(pkg.carrier) - \(pkg.name)") {
                                    SMSHelper.send(number: pkg.number, message: pkg.syntax)
                                }
                            }
                            Button(languageManager.localize("Cancel"), role: .cancel) {}
                        }
                    }
                    // ----------------------------------------

                    Text(languageManager.localize("Safety Guides"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.aquaNavy)
                        .padding(.top)

                    // Safety guides list
                    SafetySection(
                        icon: "backpack.fill",
                        iconColor: .indigo,
                        title: languageManager.localize("Before a Flood"),
                        tag: languageManager.localize("High"),
                        tagColor: .orange,
                        steps: [
                            languageManager.localize("Prepare an emergency kit with flashlight, batteries, first aid, medications, and at least 3 days of water and food"),
                            languageManager.localize("Know your evacuation route in advance and agree on a safe meeting point with your family"),
                            languageManager.localize("Keep your phone charged and turn on flood alerts so you're notified the moment your area is at risk"),
                            languageManager.localize("Move valuables and important documents to higher shelves or an upper floor before water starts rising"),
                        ]
                    )
                    .padding(.horizontal)

                    SafetySection(
                        icon: "house.fill",
                        iconColor: .red,
                        title: languageManager.localize("During a Flood"),
                        tag: languageManager.localize("Critical"),
                        tagColor: .red,
                        steps: [
                            languageManager.localize("Move to higher ground or the highest floor of your home right away — floodwater can rise faster than expected, so don't wait until it looks dangerous to act"),
                            languageManager.localize(
                                "Avoid walking or driving through flood waters no matter how shallow they look — just 15cm of moving water can knock an adult off their feet, and 60cm can sweep away a car"),
                            languageManager.localize("Stay away from downed power lines and any standing water near them, since electricity can travel through water and cause electrocution from a distance"),
                            languageManager.localize("Keep a battery-powered or hand-crank radio nearby for emergency broadcasts, since cell networks and electricity often fail first during severe flooding"),
                        ]
                    )
                    .padding(.horizontal)

                    SafetySection(
                        icon: "doc.text.fill",
                        iconColor: .green,
                        title: languageManager.localize("After a Flood"),
                        tag: languageManager.localize("Medium"),
                        tagColor: .blue,
                        steps: [
                            languageManager.localize(
                                "Return home only after authorities officially confirm it's safe — floodwater can hide structural damage and contamination that isn't visible from outside"),
                            languageManager.localize("Document all damage with clear photos and videos before starting cleanup, since this is essential for insurance claims and relief assistance"),
                            languageManager.localize("Clean and disinfect everything that got wet, including floors and furniture, since floodwater often carries sewage and bacteria that can cause illness"),
                            languageManager.localize("Inspect your home for structural damage such as cracked foundations or a sagging roof before staying inside, and leave immediately if you notice any"),
                        ]
                    )
                    .padding(.horizontal)

                    SafetySection(
                        icon: "cross.vial.fill",
                        iconColor: .teal,
                        title: languageManager.localize("Health & Hygiene After Flooding"),
                        tag: languageManager.localize("Medium"),
                        tagColor: .blue,
                        steps: [
                            languageManager.localize("Only drink boiled or bottled water until authorities confirm the local water supply is safe again"),
                            languageManager.localize("Wash your hands frequently with soap, especially after any contact with floodwater, to avoid infection"),
                            languageManager.localize("Watch for signs of waterborne illness such as fever, diarrhea, or skin infections, and see a doctor promptly if they appear"),
                            languageManager.localize("Throw away any food that touched floodwater, including canned goods with damaged or bulging seals"),
                        ]
                    )
                    .padding(.horizontal)

                    SafetySection(
                        icon: "car.fill",
                        iconColor: .purple,
                        title: languageManager.localize("Vehicle Safety"),
                        tag: languageManager.localize("High"),
                        tagColor: .orange,
                        steps: [
                            languageManager.localize("Never drive through flooded roads, even ones you know well — floodwater can hide missing manhole covers, washed-out pavement, and downed power lines"),
                            languageManager.localize("If water starts rising around your car, turn around immediately and head for higher ground rather than trying to push through"),
                            languageManager.localize("If your car stalls or starts floating in rising water, get out right away and move to higher ground on foot instead of staying inside"),
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
