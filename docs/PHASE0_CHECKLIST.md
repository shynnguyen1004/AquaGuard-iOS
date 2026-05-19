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

## Next: Phase 2

1. Create `Views/Shared/` and move shared screens
