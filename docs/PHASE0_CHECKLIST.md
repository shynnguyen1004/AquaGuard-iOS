# Phase 0 Checklist

- [x] Git: `refactor/rbac-mvvm-structure` created from `main` @ `4011565`
- [x] Remote sync: `origin/main` fetched — **not behind** (local ahead by 1 commit on `main`)
- [x] Target structure documented in `docs/RBAC_STRUCTURE.md`
- [x] Baseline build: **BUILD SUCCEEDED** (`xcodebuild`, iPhone 17 Pro Simulator)
- [ ] Team review of `RBAC_STRUCTURE.md` before Phase 1

## Next: Phase 1

1. Move orphan + Admin views → `Views/_Legacy/`
2. Move orphan view models → `ViewModels/_Legacy/`
3. Remove `AdminContentView` branch from app (Phase 5) — **after** legacy move
4. Block admin at login (Phase 5)
