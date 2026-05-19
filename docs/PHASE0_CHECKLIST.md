# Phase 0 Checklist

- [x] Git: `refactor/rbac-mvvm-structure` created from `main` @ `4011565`
- [x] Remote sync: `origin/main` fetched — **not behind** (local ahead by 1 commit on `main`)
- [x] Target structure documented in `docs/RBAC_STRUCTURE.md`
- [x] Baseline build: **BUILD SUCCEEDED** (`xcodebuild`, iPhone 17 Pro Simulator)
- [ ] Team review of `RBAC_STRUCTURE.md` before Phase 1

## Phase 1 — Done

- [x] Orphan + Admin views → `Views/_Legacy/`
- [x] Legacy view models → `ViewModels/_Legacy/`
- [x] `AdminAccessBlockedView` + login reject for admin role
- [x] Build verified

## Phase 2 — Done

- [x] `Views/Shared/` — Auth, Main, Map, Settings, Components, Helpers

## Phase 3 — Done

- [x] `Views/Citizen/` — Home, Emergency, Safety, Profile
- [x] `Views/Rescuer/` — Requests, Dashboard, Team (+ RescuerContentView)

## Phase 4 — Done

- [x] `ViewModels/Shared/` — AuthenticationViewModel, MapViewModel
- [x] `ViewModels/Citizen/` — Emergency, Family, Home
- [x] `ViewModels/Rescuer/` — RescuerViewModel, RescuerTeamViewModel
- [x] `ViewModels/_Legacy/` — (from Phase 1)

## Next: Phase 5–7

1. Models `_Legacy` (optional), smoke test, PR
