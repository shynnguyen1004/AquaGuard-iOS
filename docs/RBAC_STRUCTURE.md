# AquaGuard iOS — RBAC MVVM Structure (Target)

> Branch: `refactor/rbac-mvvm-structure`  
> Last updated: Phase 0 setup  
> Source of truth for the Views / ViewModels refactor.

## Product decisions (team sync)

| Decision | Detail |
|----------|--------|
| **No Admin on mobile** | Admin workflows live on **web only**. |
| **Admin login on iOS** | Reject with message: *"Đăng nhập với tài khoản Citizen hoặc Rescuer"* (or localized equivalent). |
| **Mobile roles** | `citizen` \| `rescuer` only. |
| **Views layout** | `Shared` / `Citizen` / `Rescuer` / `_Legacy` (orphans, temporary). |
| **ViewModels layout** | `Shared` / `Citizen` / `Rescuer` / `_Legacy` (same rule). |
| **Models** | Domain-based; no role folders. Legacy types → `Models/_Legacy/`. |

---

## Target folder tree

```
Views/
├── Shared/                         # ≥2 roles OR pre-auth / shell
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── RegisterView.swift
│   ├── Main/
│   │   ├── SplashScreenView.swift
│   │   └── ContentView.swift          # Citizen tab shell (rename → CitizenTabView optional)
│   ├── Map/
│   │   ├── FloodMapView.swift
│   │   ├── WindyMapView.swift
│   │   └── WeatherLayerPanel.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   ├── Components/
│   │   ├── LogoHeaderView.swift
│   │   └── Extensions.swift
│   └── Helpers/
│       ├── ImagePicker.swift
│       └── CameraPreviewView.swift
│
├── Citizen/                        # Citizen-only screens
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── FamilyView.swift
│   ├── Emergency/
│   │   ├── EmergencyTabView.swift
│   │   ├── RequestHistoryCard.swift
│   │   ├── QuickSOSPreview.swift
│   │   └── LiveTrackingSheet.swift
│   ├── Safety/
│   │   └── SafetyView.swift
│   └── Profile/
│       └── ProfileView.swift
│
├── Rescuer/
│   ├── RescuerContentView.swift
│   ├── Requests/
│   │   ├── RescuerRequestsView.swift
│   │   └── RescuerLiveTrackingSheet.swift
│   ├── Dashboard/
│   │   └── RescuerDashboardView.swift
│   └── Team/
│       └── RescuerTeamView.swift
│
└── _Legacy/                        # Orphan / unused — delete after review
    ├── Rescue/
    │   └── SOSTabView.swift
    ├── Report/
    │   ├── ReportView.swift
    │   ├── RescueTabView.swift
    │   ├── InstantCaptureView.swift
    │   ├── CommunityFeedView.swift
    │   └── FloodReportCard.swift
    ├── Emergency/
    │   └── DetailedRequestSheet.swift
    └── Admin/                      # Mobile admin UI — deprecated
        ├── AdminContentView.swift
        ├── AdminDashboardView.swift
        ├── AdminSOSView.swift
        ├── AdminAnalyticsView.swift
        ├── AdminUsersView.swift
        └── AdminTeamsView.swift

ViewModels/
├── Shared/
│   ├── AuthenticationViewModel.swift
│   └── MapViewModel.swift
├── Citizen/
│   ├── EmergencyViewModel.swift
│   ├── FamilyViewModel.swift
│   └── HomeViewModel.swift
├── Rescuer/
│   ├── RescuerViewModel.swift
│   └── RescuerTeamViewModel.swift
└── _Legacy/
    ├── FloodReportViewModel.swift
    ├── ReportViewModel.swift
    ├── RescueRequestViewModel.swift
    └── RescueDashboardViewModel.swift

Models/                             # Domain-based (no Citizen/Rescuer split)
├── UserRole.swift                  # AppState; mobile uses .citizen | .rescuer only
├── APIModels.swift
├── Models.swift
├── FamilyMember.swift
└── _Legacy/
    ├── FloodReport.swift
    └── CommunityReport.swift

Services/                           # Unchanged
AquaGuard/                          # App entry, assets, plist
```

---

## Placement rules

| Condition | Folder |
|-----------|--------|
| Pre-auth (login, splash) | `Views/Shared/` |
| Used by Citizen **and** Rescuer | `Views/Shared/` |
| Citizen only | `Views/Citizen/` |
| Rescuer only | `Views/Rescuer/` |
| Not referenced in active navigation | `Views/_Legacy/` |
| ViewModel: 2+ roles | `ViewModels/Shared/` |
| ViewModel: one role | `ViewModels/Citizen/` or `Rescuer/` |
| Unused VM | `ViewModels/_Legacy/` |

---

## App routing (target)

```swift
// AquaGuardApp.swift (after refactor)
if tokenManager.isAuthenticated {
    switch appState.currentRole {
    case .citizen:
        ContentView()           // Views/Shared/Main or Citizen/
    case .rescuer:
        RescuerContentView()    // Views/Rescuer/
    case .admin:
        AdminBlockedView()      // OR alert at login — no Admin shell
    }
}
```

**Login (`AuthenticationViewModel`):** if `authData.user.role == "admin"` → show error, do not save session.

---

## File migration map (current → target)

### Views — Shared

| Current | Target |
|---------|--------|
| `Views/Authentication/LoginView.swift` | `Views/Shared/Auth/LoginView.swift` |
| `Views/Authentication/RegisterView.swift` | `Views/Shared/Auth/RegisterView.swift` |
| `Views/Main/SplashScreenView.swift` | `Views/Shared/Main/SplashScreenView.swift` |
| `Views/Main/ContentView.swift` | `Views/Shared/Main/ContentView.swift` |
| `Views/Map/*` | `Views/Shared/Map/*` |
| `Views/Home/SettingsView.swift` | `Views/Shared/Settings/SettingsView.swift` |
| `Views/Shared/*` | `Views/Shared/Components/*` |
| `Views/Helpers/*` | `Views/Shared/Helpers/*` |

### Views — Citizen

| Current | Target |
|---------|--------|
| `Views/Home/HomeView.swift` | `Views/Citizen/Home/HomeView.swift` |
| `Views/Home/FamilyView.swift` | `Views/Citizen/Home/FamilyView.swift` |
| `Views/Emergency/*` (except DetailedRequestSheet) | `Views/Citizen/Emergency/*` |
| `Views/Safety/SafetyView.swift` | `Views/Citizen/Safety/SafetyView.swift` |
| `Views/Profile/ProfileView.swift` | `Views/Citizen/Profile/ProfileView.swift` |

### Views — Rescuer

| Current | Target |
|---------|--------|
| `Views/Rescuer/*` | `Views/Rescuer/` (reorganize subfolders) |

### Views — _Legacy

| Current | Target |
|---------|--------|
| `Views/Rescue/SOSTabView.swift` | `Views/_Legacy/Rescue/SOSTabView.swift` |
| `Views/Report/*` | `Views/_Legacy/Report/*` |
| `Views/Emergency/DetailedRequestSheet.swift` | `Views/_Legacy/Emergency/DetailedRequestSheet.swift` |
| `Views/Admin/*` | `Views/_Legacy/Admin/*` |

### ViewModels

| Current | Target |
|---------|--------|
| `AuthenticationViewModel.swift` | `ViewModels/Shared/` |
| `MapViewModel.swift` | `ViewModels/Shared/` |
| `EmergencyViewModel.swift` | `ViewModels/Citizen/` |
| `FamilyViewModel.swift`, `HomeViewModel.swift` | `ViewModels/Citizen/` |
| `RescuerViewModel.swift`, `RescuerTeamViewModel.swift` | `ViewModels/Rescuer/` |
| `FloodReportViewModel`, `ReportViewModel`, `RescueRequestViewModel`, `RescueDashboardViewModel` | `ViewModels/_Legacy/` |

---

## Refactor phases

| Phase | Scope | Status |
|-------|--------|--------|
| **0** | Branch, this doc, baseline build | Done |
| **1** | Move orphans + Admin views → `Views/_Legacy/`; legacy VMs → `ViewModels/_Legacy/`; block admin on mobile | Done |
| **2** | Create `Views/Shared/`, move shared views |
| **3** | Create `Views/Citizen/`, `Views/Rescuer/` |
| **4** | Reorganize `ViewModels/` (Shared / Citizen / Rescuer / _Legacy) |
| **5** | Block admin login + remove `AdminContentView` from `AquaGuardApp` |
| **6** | `Models/_Legacy/`, optional APIModels split |
| **7** | Build + manual RBAC smoke test |

---

## Inventory (Phase 0 — current repo)

### Active views (in navigation)

- **Pre-auth:** `SplashScreenView`, `LoginView`, `RegisterView`
- **Citizen:** `ContentView` → `HomeView`, `FloodMapView`, `EmergencyTabView`, `SafetyView`, `ProfileView` (+ `FamilyView`, `SettingsView` sheets)
- **Rescuer:** `RescuerContentView` → `FloodMapView`, `RescuerRequestsView`, `RescuerDashboardView`, `RescuerTeamView`, `SettingsView`

### Orphan / legacy views (→ `_Legacy` in Phase 1)

- `SOSTabView`, `ReportView`, `RescueTabView`, `InstantCaptureView`, `CommunityFeedView`, `FloodReportCard`, `DetailedRequestSheet`
- All `Views/Admin/*` (6 files)

### ViewModels

- **Active:** `AuthenticationViewModel`, `MapViewModel`, `EmergencyViewModel`, `FamilyViewModel`, `HomeViewModel`, `RescuerViewModel`, `RescuerTeamViewModel`
- **Legacy:** `FloodReportViewModel`, `ReportViewModel`, `RescueRequestViewModel`, `RescueDashboardViewModel`

---

## Git (Phase 0)

- Base branch: `main` @ `4011565` (ahead of `origin/main` by 1 commit)
- Work branch: `refactor/rbac-mvvm-structure`
- Remote: up to date with `origin/main` after fetch; no pull required before refactor
