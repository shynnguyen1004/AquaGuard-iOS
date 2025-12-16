# 🌊 AquaGuard - Flood Alert & Rescue System

![Platform](https://img.shields.io/badge/Platform-iOS-000000.svg?style=for-the-badge&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-F05138.svg?style=for-the-badge&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-2.0-007AFF.svg?style=for-the-badge&logo=swift)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

**AquaGuard** is a native iOS application designed to protect communities during flood disasters. It provides real-time alerts, safety guides, and a crowdsourced reporting system to coordinate rescue efforts effectively.

> **Status:** 🚧 MVP / Beta Development

---

## 📱 Screenshots

|               Home Dashboard               |                 Flood Map                 |               Incident Report               |                  Rescue Ops                  |
| :----------------------------------------: | :---------------------------------------: | :------------------------------------------: | :------------------------------------------: |
| `<img src="docs/home.png" width="200"/>` | `<img src="docs/map.png" width="200"/>` | `<img src="docs/report.png" width="200"/>` | `<img src="docs/rescue.png" width="200"/>` |

---

## ✨ Key Features

### 🚨 Real-time Alerts

- **Risk Status Card:** Visual indicators (Safe/Warning/Danger) based on current location.
- **Active Alerts:** Receive instant updates on heavy rainfall and rising water levels.

### 🗺️ Interactive Flood Map

- **Live Tracking:** View flooded zones with color-coded pins (🔴 Severe / 🟡 Moderate).
- **Navigation:** Integrated with **MapKit** for accurate location tracking.

### 📝 Crowdsourced Reporting

- **Quick Report:** Submit flood incidents with location, water level slider, and photos.
- **Geolocation:** Auto-detect user coordinates for precise rescue targeting.

### ⛑️ Rescue Dashboard

- **Resource Management:** Track available rescue boats, shelters, and medical teams.
- **Mission Control:** View pending rescue requests and assign teams efficiently.

---

## 🛠 Tech Stack

* **Language:** Swift 5.9
* **UI Framework:** SwiftUI (MVVM Architecture)
* **Maps:** MapKit & CoreLocation
* **Compatibility:** iOS 16.0+
* **Tools:** Xcode 16

---

## 🚀 Getting Started

### Prerequisites

* Mac with macOS Sonoma or later.
* Xcode 15/16 installed.

### Installation

1. Clone the repository:
   ```bash
   git clone [https://github.com/your-username/AquaGuard-iOS.git](https://github.com/your-username/AquaGuard-iOS.git)
   ```
2. Open the project in Xcode:
   ```bash
   cd AquaGuard-iOS
   open AquaGuard.xcodeproj
   ```
3. Select your Development Team in **Signing & Capabilities**.
4. Build and Run (⌘+R) on a Simulator or Real Device.

---

## 🔮 Roadmap

- [X] UI/UX Implementation (SwiftUI)
- [X] Map Interface with Dummy Data
- [X] Reporting Form Logic
- [ ] **Backend Integration:** Connect with Supabase/Firebase.
- [ ] **Offline Mode:** Local database for reporting without internet.
- [ ] **Push Notifications:** Alert users when entering danger zones.
- [ ] **AI Analysis:** Predict flood trends using NASA/NOAA data.

---

## 🤝 Contributing

Contributions are always welcome! Please follow these steps:

1. Fork the project.
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the Branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

**Built with ❤️ for a safer community.**
