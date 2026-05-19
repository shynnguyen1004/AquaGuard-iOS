# AquaGuard iOS — RBAC Smoke Test (Phase 7)

Run on simulator or device after refactor branch merges.

## Pre-auth

- [ ] Cold launch shows splash, then login within ~3s
- [ ] Register creates **citizen** account and lands on citizen tabs
- [ ] Invalid credentials show error alert

## Admin blocked (mobile)

- [ ] Login with **admin** account → error: Citizen or Rescuer only (no JWT saved)
- [ ] If admin JWT already on device → `AdminAccessBlockedView` + Sign out works

## Citizen (`citizen` role)

- [ ] **Home** — loads, family shortcut opens `FamilyView`
- [ ] **Map** — Apple map + optional Windy overlay
- [ ] **Emergency** — camera/SOS flow; history uses `GET /api/sos/my`
- [ ] **Safety** — content visible
- [ ] **Profile** — profile loads; Recent Activity shows SOS from `/api/sos/my`

## Rescuer (`rescuer` role)

- [ ] **Map** tab loads shared `FloodMapView`
- [ ] **Yêu cầu** — list loads from API; accept/detail sheet
- [ ] **Nhiệm vụ** — dashboard visible
- [ ] **Đội** — team view loads
- [ ] **Cài đặt** — theme/language/logout

## Regression

- [ ] No crash switching tabs (citizen + rescuer)
- [ ] Logout returns to login
- [ ] Relaunch restores session for citizen/rescuer

## Automated build

```bash
xcodebuild -scheme AquaGuard -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: **BUILD SUCCEEDED**

> Unit test target (`AquaGuardTests`) may need Xcode target dependency cleanup before `build test` works reliably.
