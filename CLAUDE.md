# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project overview

**AquaGuard** is a flood alert & rescue system for communities. It is developed as
**two parallel client apps that share a single backend**:

| Surface  | Tech            | Hosting                         | This repo? |
|----------|-----------------|---------------------------------|:----------:|
| Web app  | React (ReactJS) | **Vercel**                      | ❌ (separate repo) |
| Mobile   | Swift / SwiftUI | App Store / TestFlight          | ✅ **this repo** |
| Backend  | REST API + WebSocket | **Render** (`aquaguard-api.onrender.com`) | ❌ (separate repo) |

**Important:** The iOS app and the React web app talk to the **same backend**. The
web is deployed to Vercel; the backend is deployed to Render. This iOS app connects
to that **Render** backend in production. Any change to the API contract affects both
clients — keep parity in mind and avoid breaking shared endpoints.

This repository contains **only the iOS (Swift) app**.

## Backend connection

Network configuration is centralized in [`Services/NetworkConfig.swift`](Services/NetworkConfig.swift):

- `useProduction = true` → uses the deployed **Render** backend
  (`https://aquaguard-api.onrender.com/api`, WebSocket `wss://aquaguard-api.onrender.com`).
- `useProduction = false` → uses a **local Docker** backend
  (`http://<devHost>:5001/api`). `devHost` is `localhost` on Simulator, or a LAN IP on a
  physical device (currently `192.168.1.74`).

Do not scatter base URLs elsewhere — always read them from `NetworkConfig`.

- `Services/APIService.swift` — shared HTTP client; attaches the JWT, decodes responses,
  maps status codes to `APIError`.
- `Services/WebSocketService.swift` — real-time tracking over WebSocket.
- `Services/TokenManager.swift` — auth token storage.

## Backend reference copy (read-only)

A copy of the backend source is present in `backend/` (git-ignored, see `.gitignore`) so
Claude can read the real API implementation — endpoints, validation, business logic, DB schema.

**Backend stack:** Node.js + Express, PostgreSQL (`db.js` + `migrations/`), Redis
(`redisClient.js`), JWT auth (`middleware/`), Dockerfile. Routes live in `backend/routes/`
(`auth`, `sos`, `family`, `analytics`, `locations`, `notifications`, `rtc`) and are all
mounted under `/api/*` in `backend/index.js`.

**Rules:**

- **Read-only.** This is a *reference copy*. The source of truth is the separate backend
  repo that is deployed to Render (and shared with the React web app). **Do not edit**
  files under `backend/` here — real API changes must be made in that backend repo.
- It is **not built or run** by the iOS app and is **not committed** to this repo.
- It may be **stale** — it is a snapshot, not a live link. It does not affect what the app
  connects to; runtime connection is always decided by `NetworkConfig` → Render.
- The copy may contain secrets (`.env`, keys). Keep the folder name as `backend/` or
  `aquaguard-backend/` so `.gitignore` keeps excluding it — never commit it.

When redesigning UI or adding features, read `backend/` to confirm the exact request
shape and response fields before touching `Services/`/`Models/`.

## API Contract

Base URL from `NetworkConfig.apiBaseURL` (all routes are under `/api`). iOS DTOs live in
[`Models/APIModels.swift`](Models/APIModels.swift). This is the contract the React web
client also depends on — changing it affects both clients. The list below reflects the
actual backend routes (`backend/routes/*`); the iOS app currently consumes a subset.

**Auth** (`/api/auth`)
- `POST /register`, `POST /login` → token + `APIUser`
- `GET  /profile`, `PUT /profile`
- `POST /forgot-password`, `POST /verify-otp`, `POST /reset-password`
- `GET  /users`, `PUT /users/:id/role` — admin
- `GET  /rescuers`
- Rescue groups: `GET /rescue-groups/all`, `GET /rescue-groups/my`, `POST /rescue-groups`,
  `PUT /rescue-groups/:id`, `DELETE /rescue-groups/:id`, `GET /rescue-groups/:id/stats`,
  `POST /rescue-groups/:id/leave`, `POST /rescue-groups/:id/invite`,
  `PUT /rescue-groups/:id/members/:userId/role`, `DELETE /rescue-groups/:id/members/:userId`
- Invites: `POST /rescue-group-invites/:id/accept`, `POST /rescue-group-invites/:id/decline`

**SOS / rescue** (`/api/sos`)
- `POST /` — submit SOS (multipart: location, water level, photos)
- `GET  /my`, `GET /all`, `GET /team`, `GET /stats`
- `PUT  /:id/assign`, `PUT /:id/accept`, `PUT /:id/cancel`, `PUT /:id/complete`

**Family** (`/api/family`)
- `GET  /search`, `GET /members`, `GET /requests`
- `POST /request`, `PUT /requests/:id/accept`, `PUT /requests/:id/reject`
- `DELETE /members/:connectionId`
- `PUT  /status`, `PUT /location` — presence & live location sharing

**Analytics** (`/api/analytics`) — admin dashboards
- `GET /overview`, `GET /users`, `GET /rescue`

**Locations** (`/api/locations`) — live tracking (pairs with WebSocket)
- `GET /live`, `GET /live/:userId`, `GET /nearby`

**Notifications** (`/api/notifications`)
- `GET /`, `PUT /read-all`, `PUT /:id/read`, `DELETE /:id`, `POST /admin/send`

**RTC** (`/api/rtc`) — WebRTC signaling (see `backend/routes/rtc.js`)

**Key iOS DTOs:** `APIResponse<T>` (envelope), `APIUser`, `APIRescueRequest`, `SOSStats`,
`APIFamilyMember`, `APIFamilyRequest`, `APIRescueGroup`, `APIGroupMember`, `APIGroupInvite`,
`APIAnalyticsOverview`, `APIRescueAnalytics`. See `Models/APIModels.swift` for full fields.

> `backend/routes/*` is the authoritative reference for exact request/response payloads.
> Rate limits apply to `login`, `register`, `forgot-password`, and `notifications/admin/send`.

## Architecture (iOS)

SwiftUI app using **MVVM**. Source is organized by layer, then by role:

- `Models/` — data models & API DTOs (`APIModels.swift`, `CommunityReport.swift`,
  `FamilyMember.swift`, `UserRole.swift`, `Weather/`).
- `ViewModels/` — split by role: `Citizen/`, `Rescuer/`, `Shared/`.
- `Views/` — split by role: `Citizen/`, `Rescuer/`, `Shared/`.
- `Services/` — networking, camera, location, SMS, theme/language managers, weather.
- `AquaGuard/` — app entry point (`AquaGuardApp.swift`), assets, `Info.plist`, Firebase config.
- `infrastructure/` — local backend for development (`docker-compose.yml`, nginx, DB init).
  Use this to run the backend locally when `useProduction = false`.

`_Legacy/` folders hold pre-refactor code that is being phased out — prefer the
role-based structure for new work.

### Roles (RBAC)

The product has two primary roles — **Citizen** and **Rescuer** — reflected in the
`Citizen/` vs `Rescuer/` folder split. See [`docs/RBAC_STRUCTURE.md`](docs/RBAC_STRUCTURE.md).

### Weather

Weather comes from **Open-Meteo** (free tier, no API key) via `Services/Weather/`
(`OpenMeteoService`, `WeatherCache`, `WeatherRiskCalculator`). Responses are cached for
15 minutes (`weatherCacheTTL`). Weather feeds the risk Status Card.

## Tech stack

- Swift 5.9, SwiftUI (MVVM), MapKit + CoreLocation
- Minimum iOS 26.0+, Xcode 16
- Firebase (see `AquaGuard/GoogleService-Info.plist`)

## Building & running

- Open `AquaGuard.xcodeproj` in Xcode, select a Development Team under
  Signing & Capabilities, then build & run (`⌘R`).
- Tests: `AquaGuardTests/` (unit) and `AquaGuardUITests/` (UI).

## Conventions

- Keep the API contract in sync with the React web client — the backend is shared.
- Route all network/base-URL logic through `NetworkConfig` + `APIService`.
- New features follow the role-based `Citizen/` / `Rescuer/` / `Shared/` layout.
- Match the style, naming, and comment density of surrounding Swift files.
