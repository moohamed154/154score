# ⚽ 154Score — Real-Time Football App

<div align="center">

**A production-quality football application built with Flutter, MVVM + BLoC Clean Architecture, and real-time Socket.IO WebSockets.**

[![Flutter](https://img.shields.io/badge/Flutter-3.47.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.0-0175C2?logo=dart)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM%20%2B%20Clean%20%2B%20BLoC-success)](#architecture)
[![WebSocket](https://img.shields.io/badge/Real--Time-Socket.IO-brightgreen)](#api--websocket)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-blue)](#quick-start)

</div>

---

## 🌟 Features

| Category | Details |
|---|---|
| ⚡ **Live Scores** | Real-time WebSocket updates for scores, match minutes, goals, cards & substitutions with animated transitions |
| 📱 **Multi-Platform** | Mobile (Bottom Nav), Tablet (Navigation Rail), Desktop/Web (Sidebar + multi-column dashboard) |
| 🌐 **Bilingual (AR / EN)** | Full RTL/LTR support with Arabic & English typography, date formatting, and locale-aware WebSocket rooms |
| 🎨 **Material 3 Theming** | Dark, Light, and System theme modes with curated sports color palette |
| 🏟️ **Match Center** | Live score header, Events Timeline, Statistics bars, Match metadata (referee, broadcaster, stadium), News feed |
| 📊 **League Standings** | Live tables with UCL / UEL / Europa Conference League / Relegation color indicators |
| 🏆 **Leagues & Teams** | Dedicated league and team detail pages |
| 👤 **Player Profiles** | Full player cards with stats and metadata |
| 🔄 **Transfer Market** | Live tracker with player details, transfer fees, and club movements |
| 🎥 **Video Feed** | Highlights and goal clips, filterable by championship |
| 👥 **Profiles** | Stadium, Referee, and Commentator profile centers |
| ⭐ **Local Favorites** | On-device favorites for teams, competitions, and matches via `shared_preferences` |
| 🔍 **Global Search** | Fuzzy search across teams, competitions, and matches |
| 🛠️ **Diagnostics** | Built-in API health check, ping latency test, and server metrics viewer |
| 🔒 **No Firebase / Supabase** | Strictly powered by the custom 154score API + local `shared_preferences` |

---

## 🏗️ Architecture

The codebase follows **Clean Architecture + Flutter MVVM** with strict layer separation:

```text
lib/
├── app/                    # Router (GoRouter), theme, root app widget, responsive scaffold
├── core/                   # Shared infrastructure
│   ├── constants/          # API endpoints, colors, typography, dimensions
│   ├── di/                 # GetIt dependency injection container
│   ├── errors/             # Failures & exceptions
│   ├── localization/       # AR (RTL) & EN (LTR) localizations
│   ├── network/            # Dio ApiClient, ApiResult<T>, NetworkInfo
│   ├── storage/            # LocalStorageService (SharedPreferences)
│   ├── theme/              # Material 3 light & dark AppTheme
│   ├── utils/              # DateFormatter, ScoreHelper
│   ├── websocket/          # Socket.IO WebSocketService & LiveMatchUpdate model
│   └── widgets/            # AppImage, SkeletonLoader, LivePulseBadge, ErrorView, EmptyView
└── features/               # Feature-first modules (data → domain → presentation)
    ├── splash/             # Splash / onboarding screen
    ├── home/               # Dashboard, live carousel, popular competitions, highlights
    ├── matches/            # Matches center, date strip, filters, real-time cards
    ├── match_details/      # Overview, Events, Stats, Info, News tabs
    ├── standings/          # League tables
    ├── leagues/            # League detail pages
    ├── teams/              # Team detail pages
    ├── players/            # Player profile pages
    ├── transfers/          # Transfer market cards & club movements
    ├── videos/             # Video feed, categories, video detail viewer
    ├── profiles/           # Stadium, Referee & Commentator profiles
    ├── favorites/          # On-device favorites management
    ├── search/             # Global fuzzy search
    └── settings/           # Appearance, language, time format, timezone, diagnostics
```

> For detailed diagrams and data-flow sequences, see [docs/architecture.md](docs/architecture.md).

---

## 📦 Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_bloc` | `^8.1.6` | State management (Bloc / Cubit) |
| `dio` | `^5.7.0` | HTTP client with interceptors |
| `socket_io_client` | `^2.0.3+1` | Real-time WebSocket (Socket.IO) |
| `go_router` | `^14.6.2` | Declarative deep-link routing |
| `get_it` | `^8.0.2` | Service locator / dependency injection |
| `equatable` | `^2.0.7` | Value equality for states & entities |
| `shared_preferences` | `^2.3.3` | Local persistence (favorites & settings) |
| `cached_network_image` | `^3.4.1` | Efficient image caching |
| `google_fonts` | `^6.2.1` | Custom typography |
| `skeletonizer` | `^3.0.0` | Skeleton loading placeholders |
| `connectivity_plus` | `^6.1.0` | Network connectivity detection |
| `url_launcher` | `^6.3.1` | Opening external links |
| `share_plus` | `^13.3.0` | Native share sheet |
| `intl` | `^0.20.2` | Date & number formatting / i18n |

**Dev:** `bloc_test`, `mocktail`, `flutter_lints`

---

## 🔌 API & WebSocket

| | Value |
|---|---|
| **REST Base URL** | `https://moohamed154-154score-api.hf.space` |
| **WebSocket URL** | `https://moohamed154-154score-api.hf.space` (Socket.IO) |
| **WS Room (Arabic)** | `live_matches_ar` |
| **WS Room (English)** | `live_matches_en` |

### REST Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/api/matches` | `GET` | Matches grouped by league (`lang`, `date`, `utc-offset`) |
| `/api/matches/:id/events` | `GET` | Timeline: goals, cards, subs, VAR |
| `/api/matches/:id/stats` | `GET` | Possession, shots, corners, etc. |
| `/api/matches/:id/details` | `GET` | Venue, referee, commentator, channel |
| `/api/matches/:id/news` | `GET` | Match-specific news feed |
| `/api/leagues/:id/standings` | `GET` | League standings table |
| `/api/transfers` | `GET` | Transfer market movements |
| `/api/videos` | `GET` | Video highlights (filterable by `champ_id`) |
| `/api/videos/:id` | `GET` | Video detail & related clips |
| `/api/stadium/:id/:slug` | `GET` | Stadium profile |
| `/api/referee/:id/:slug` | `GET` | Referee profile |
| `/api/commentator/:id/:slug` | `GET` | Commentator profile |
| `/api/config?type=health` | `GET` | Server health check |
| `/ping` | `GET` | Server awake / latency check |
| `/api/metrics` | `GET` | Server performance metrics |

> Full specs: [docs/api.md](docs/api.md) · [docs/websocket.md](docs/websocket.md)

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK `≥ 3.47.0` (Dart `≥ 3.13.0`)
- Android Studio / Xcode for mobile targets
- Google Chrome / Edge for web

### 1. Clone & Install

```bash
git clone <repo-url>
cd ysscores
flutter pub get
```

### 2. Environment Configuration (optional)

Copy `.env.example` and adjust if needed:

```bash
cp .env.example .env
```

```env
API_BASE_URL=https://moohamed154-154score-api.hf.space
WEBSOCKET_URL=https://moohamed154-154score-api.hf.space
SOCKET_ROOM_AR=live_matches_ar
SOCKET_ROOM_EN=live_matches_en
CONNECT_TIMEOUT_MS=15000
RECEIVE_TIMEOUT_MS=15000
```

### 3. Run

```bash
# Web (Chrome)
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

---

## 🧪 Testing & Quality

```bash
# Unit & widget tests
flutter test

# Static analysis
flutter analyze

# Auto-fix lint issues
dart fix --apply
```

---

## 📦 Production Builds

```bash
# Web
flutter build web --release

# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🔑 Key Design Decisions

- **Zero `BuildContext` in ViewModels** — navigation, dialogs, and snackbars are strictly handled in the View layer via `BlocListener`.
- **`ApiResult<T>` sealed class** — all network calls return `Success<T>` or `Failure<T>`, eliminating unhandled exceptions.
- **Immutable state + `copyWith`** — every Bloc state uses `Equatable` + `copyWith` for predictable, testable transitions.
- **Scoped rebuilds** — `BlocBuilder` with `buildWhen` / `BlocSelector` ensures only the minimal widget subtree re-renders.
- **`const` everywhere** — all stateless widget trees are fully `const` for maximum 60/120 FPS rendering efficiency.

---

## 📖 Documentation

| Document | Description |
|---|---|
| [docs/architecture.md](docs/architecture.md) | Architecture blueprint, layer diagrams, data flow |
| [docs/api.md](docs/api.md) | REST API endpoint specifications |
| [docs/websocket.md](docs/websocket.md) | WebSocket events & real-time guide |
| [docs/development.md](docs/development.md) | Development, build & release commands |
| [docs/realtime-websocket-changelog.md](docs/realtime-websocket-changelog.md) | WebSocket implementation changelog |
