# ⚽ 154Score — Production-Grade Football Application

<div align="center">

**A state-of-the-art, high-performance football platform built with Flutter, MVVM + BLoC Clean Architecture, Real-Time Socket.IO WebSockets, and Shorebird CodePush OTA updates.**

[![Flutter](https://img.shields.io/badge/Flutter-3.47.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.0-0175C2?logo=dart)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%2B%20MVVM%20%2B%20BLoC-success)](#-architectural-blueprint)
[![Real-Time](https://img.shields.io/badge/Real--Time-Socket.IO%20Gateway-brightgreen)](#-api--real-time-engine)
[![Live Activity](https://img.shields.io/badge/Live%20Activity-iOS%20ActivityKit%20%7C%20Android%20RemoteViews-orange)](#-live-activity--lock-screen-widgets)
[![OTA Updates](https://img.shields.io/badge/OTA-Shorebird%20CodePush-blueviolet)](https://shorebird.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-blue)](#-quick-start)

</div>

---

## 📖 Overview

**154Score** is an enterprise-grade sports application delivering instant match scores, chronological timeline events, interactive tactical pitch lineups, detailed player performance ratings, league standings tables, and transfer market feeds. 

Built Arabic-first with seamless English bilingual parity, the application is engineered for butter-smooth **60/120 FPS** interactions, featuring strict **0ms first-paint caching**, resilient offline network detection, and cross-platform lock screen tracking via Apple **ActivityKit** and Android **RemoteViews**.

---

## 🌟 Core Feature Catalog & Implementation Details

### 1. ⚡ Live Match Center & Live Clock Standard
* **Instant Delta Streaming**: Subscribes dynamically to `live_matches_ar` and `live_matches_en` Socket.IO rooms, applying live score and minute mutations seamlessly without UI flicker or scroll jumping via `RealtimeMergeEngine`.
* **Standardized Live Clock (`MM:SS`)**: Matches display running chronometers formatted strictly as `MM:SS` (e.g. `65:30`).
* **Intermission & Extra Time Localization**:
  * Half-Time is localized as **`"استراحة"`** (`HT`).
  * Penalty Shootouts are localized as **`"ترجيح"`** (`Penalties`).
* **Symmetrical Event Slots**: Timeline event slots are symmetrically balanced across home and away teams in both RTL and LTR viewports.

### 2. 📱 Live Activity & Lock Screen Widgets (`features/live_activity/`)
* **iOS Dynamic Island & Lock Screen (ActivityKit)**: Displays ongoing match scores, team logos, and live running timers directly on the lock screen and Dynamic Island. Brand logos are embedded in base64 to guarantee zero load failures.
* **Android Live Notification (RemoteViews)**: Persistent, low-importance ongoing notification using stable `FrameLayout` containers, eliminating RemoteViews XML inflation crashes.
* **Stabilized Chronometer Horizon**: Set to a 180-minute interval horizon with fixed base timestamps, preventing timers from freezing or resetting at 55 minutes.
* **Smart Power Management**: Disabled by default to save battery; toggleable in Settings and Developer Diagnostics. Auto-terminates when matches end, cancel, or postpone.

### 3. 📋 Tactical Lineup Pitch & Match Player Statistics (`features/match_details/`)
* **Realistic Pitch Painter (`match_pitch_widget.dart`)**: Dynamic 2D pitch board with markings, penalty boxes, and center circle. Dynamically renders tactical formations (4-3-3, 4-2-3-1, 3-5-2, 5-3-2, etc.).
* **Player Nodes (`pitch_player_node.dart`)**: Shows player avatar photo, jersey number, captain `(C)` badge, card badges, goal indicators, and color-coded rating pills.
* **Match Player Statistics Bottom Sheet (`player_match_stats_sheet.dart`)**: Tapping any starting or substitute player opens a detailed statistics modal:
  * Overall match rating badge.
  * Minutes played and substitution timestamps.
  * Goals, assists, shots on target, pass volume and accuracy %.
  * Duels won, tackles, fouls committed, and fouls suffered.

### 4. 🛡️ Match Status Safeguards & Tab Filtering Matrix
* **Upcoming Matches (`لم تبدأ`)**: Automatically suppresses both the Events (`الأحداث`) and Statistics (`الإحصائيات`) tabs, presenting only relevant pre-match information `[التفاصيل, التشكيلة, الترتيب, الهدافون, الصناع, الأخبار]`.
* **Cancelled (`ألغيت`) & Postponed (`تأجلت`) Matches**:
  * Suppresses Events and Statistics tabs.
  * Replaces dummy `"0 - 0"` scores with high-contrast status pills and scheduled kickoff times.
  * Safeguarded against timeline placeholder overwrites.

### 5. 🎯 Vector Iconography Catalog & Penalty Standard
* **Scored Penalties**: Treated visually as **Goals** with a green circular badge (`AppColors.primary`), white soccer ball icon, minute badge, and Arabic label `"ركلة جزاء مسجلة"`.
* **Missed Penalties**: Red badge with cross/miss indicator (`AppColors.relegationRed`) and label `"ركلة جزاء ضائعة"`.
* **Special Event Icons**: Custom vector icons for woodwork/crossbar hits, missed chances, VAR reviews, twin cyan substitution arrows, and yellow/red cards.

### 6. 📊 Standings & Two-Tier 0ms Cache (`features/standings/`)
* **Instant First Paint (0ms)**: Reads from an in-memory map cache (`_cachedStandings`) before checking persistent `LocalStorageService` storage.
* **Startup Pre-Warming**: Executes `prewarmStandingsCache()` on app initialization to hydrate top championships before navigation.
* **Qualification Indicators**: Distinct colored boundary indicators:
  * 🟢 UEFA Champions League (`AppColors.uclGreen`)
  * 🔵 UEFA Europa League (`AppColors.uelBlue`)
  * 🟠 UEFA Conference League (`AppColors.ueclOrange`)
  * 🔴 Relegation Zone (`AppColors.relegationRed`)
* **Multi-Stage & Groups**: Stage selector for tournament knockouts and group stages, prioritizing the playing teams' group with a `مجموعة المباراة` badge.

### 7. 🔄 Transfer Market State Machine (`features/transfers/`)
* **Transfers BLoC**: Dedicated state management handling loading, loaded, and error states.
* **Infinite Scroll Pagination**: Powered by the backend `transfer_more` endpoint.
* **Live Market Cards**: Shows player photo, buyer crest, seller crest, transfer fee, and contract duration.

### 8. 🌐 Network Connectivity Monitoring & Offline Dialog (`features/internet_connection/`)
* **Global Network Listener**: `GlobalInternetConnectionListener` continuously monitors network status via `InternetConnectionCubit`.
* **Offline Dialog & Fallback**: Displays the themed `NoInternetDialog` on connection drop with retry actions and automatic fallback to locally cached data.
* **Automatic Reconnect**: Automatically re-subscribes to WebSocket rooms and refreshes active screens once connectivity returns.

### 9. 🎨 Theme-Aware Image & Logo Resolution
* **Automatic Logo Inversion**:
  * Light Mode: Uses dark/colored high-contrast variants (e.g. `17882925978755.png` for الدوري المصري الممتاز, `5171696546919.png` for UCL). Never renders white badges on light surfaces.
  * Dark Mode: Uses high-contrast white/light variants (e.g. `17882926672499.png`, `3141696514284.png`).
* **Brand Logo Protection**: The application brand logo is strictly protected and preserved.

### 10. 🔒 Developer Tools & Security Suite
* **Hidden Developer Mode**: Unlocked by tapping the app brand logo 10 times in Settings, followed by entering the master password (`MOhamed_2002`).
* **Diagnostics Sheet**: Inspects API latency, server metrics, cache hit rates, WebSocket room states, and Live Activity toggles.
* **Safe Controller Lifecycle**: The password dialog is encapsulated in a dedicated `StatefulWidget` to prevent `TextEditingController` memory leaks and crashes during pop animations.

### 11. 🚀 Shorebird CodePush Over-The-Air (OTA) Updates
* Seamlessly delivers instant hotfixes and UI patches directly to users without waiting for App Store or Google Play Store review cycles (`shorebird.yaml`).

---

## 🏗️ Architectural Blueprint

The application follows **Clean Architecture + Flutter MVVM (Model-View-ViewModel)** with strict unidirectional data flow:

```
┌────────────────────────────────────────────────────────┐
│                        VIEW                            │
│  (Pure UI Widgets, Stateless Screens, Theme Consumer)  │
└───────────────────────────▲────────────────────────────┘
                            │ Dispatches User Actions
             State Updates  │ & Listens to State
                            │
┌───────────────────────────▼────────────────────────────┐
│                     VIEWMODEL                          │
│  (Bloc / Cubit — Pure Business Logic & State Holding)  │
│  - Zero BuildContext or Flutter UI widget imports      │
│  - Emits immutable Equatable states                    │
└───────────────────────────▲────────────────────────────┘
                            │ Calls Methods
             Data / Domain  │ & Returns ApiResult<T>
                            │
┌───────────────────────────▼────────────────────────────┐
│                        MODEL                           │
│  ├── Repositories (Domain Contracts & Data Impl)       │
│  ├── Data Sources (Remote Dio API & Local Storage)     │
│  └── Entities & DTOs (Immutable Models & JSON Parsers) │
└────────────────────────────────────────────────────────┘
```

---

## 📁 Feature-First Directory Structure

```text
lib/
├── app/                    # App initialization, GoRouter routes, AppTheme
├── core/                   # Shared architectural foundations
│   ├── constants/          # AppColors, AppDimensions, AppStrings, ApiEndpoints
│   ├── di/                 # GetIt service locator setup
│   ├── errors/             # Custom Failures and ServerExceptions
│   ├── localization/       # Bilingual AR/EN strings and RTL/LTR helpers
│   ├── network/            # Dio ApiClient, HMAC interceptors, ApiResult<T>
│   ├── notifications/      # Push notifications (FCM) & local fallbacks
│   ├── security/           # HMAC SHA-256 signature generator
│   ├── storage/            # LocalStorageService (SharedPreferences)
│   ├── theme/              # Material 3 light/dark themes and ThemeCubit
│   ├── utils/              # UrlHelper, LeagueResolver, RealtimeMergeEngine
│   ├── websocket/          # Socket.IO client manager and event dispatchers
│   └── widgets/            # AppImage, LivePulseBadge, EmptyView, ErrorView
├── features/               # Self-contained business feature modules
│   ├── favorites/          # Pinned teams and leagues management
│   ├── home/               # Home dashboard, date strip, match cards
│   ├── internet_connection/# Network listeners, offline dialog, connection cubit
│   ├── leagues/            # League details, standings, scorers, assists
│   ├── live_activity/      # Lock screen widgets, ActivityKit, RemoteViews
│   ├── match_details/      # Match banner, timeline events, tactical lineups
│   ├── matches/            # Matches by date schedule and live filters
│   ├── news/               # Sports news carousel and articles
│   ├── onboarding/         # First-launch team & league selection
│   ├── players/            # Player profile, market value, injury sheet
│   ├── profiles/           # Stadium, referee, and commentator profiles
│   ├── search/             # Universal debounced search across all entities
│   ├── settings/           # Appearance, font size, notifications, dev tools
│   ├── standings/          # Standings tables, stages, favorites partition
│   ├── teams/              # Team profile, squad roster, fixtures, manager
│   ├── transfers/          # Transfer market live feed and pagination
│   └── videos/             # Video highlights feed and player
└── main.dart               # Bootstrap entry point, DI initialization, runApp
```

---

## 📦 Key Dependencies & Tech Stack

| Package | Version | Purpose |
|---|---|---|
| `flutter_bloc` | `^8.1.6` | Predictable state management via BLoC & Cubit |
| `dio` | `^5.7.0` | Powerful HTTP client with HMAC security interceptors |
| `socket_io_client` | `^2.0.3+1` | Real-time WebSocket connectivity |
| `go_router` | `^14.6.2` | Declarative URL-based deep linking & routing |
| `get_it` | `^8.0.2` | Dependency injection & service locator |
| `equatable` | `^2.0.7` | Value equality for immutable states & DTOs |
| `shared_preferences` | `^2.3.3` | Persistent local key-value storage |
| `cached_network_image` | `^3.4.1` | Multi-tier image caching with memCache boundaries |
| `google_fonts` | `^6.2.1` | Curated Arabic (Tajawal/Cairo) and Latin typography |
| `connectivity_plus` | `^6.1.0` | Global network connectivity monitoring |
| `skeletonizer` | `^3.0.0` | Skeleton loading placeholder shaders |
| `intl` | `^0.20.2` | Internationalization, calendar, and number formatting |

---

## ⚡ API & Real-Time Engine

| Parameter | Value |
|---|---|
| **REST Base URL** | `https://moohamed154-154score-api.hf.space` |
| **WebSocket URL** | `https://moohamed154-154score-api.hf.space` (Socket.IO) |
| **Arabic Room** | `live_matches_ar` |
| **English Room** | `live_matches_en` |
| **Transfers Room**| `transfers_ar` |
| **Match Room** | `match:{matchId}` (per-match live events and clock ticks) |

---

## 🚀 Quick Start Guide

### Prerequisites
- Flutter SDK `≥ 3.47.0`
- Dart SDK `≥ 3.13.0`
- Android Studio / Xcode for mobile targets
- Shorebird CLI (optional for OTA patches)

### Installation & Run

```bash
# 1. Clone repository
git clone <repo-url>
cd ysscores

# 2. Install dependencies
flutter pub get

# 3. Launch on connected device or emulator
flutter run
```

### Static Analysis & Testing

```bash
# Run complete test suite (unit, widget, bloc tests)
flutter test

# Run static analysis
flutter analyze

# Automatically apply mechanical lint fixes
dart fix --apply
```

### Shorebird OTA Release & Patching

```bash
# Release base binary to Shorebird
shorebird release android

# Push instant patch without App Store review
shorebird patch android
```

---

## 🔑 Core Engineering Rules

1. **Strict Unidirectional MVVM Layering**:
   - **Zero UI Imports in ViewModels**: ViewModels (`Bloc` / `Cubit`) never import `material.dart` or consume `BuildContext`. Dialogs, snackbars, and navigation belong exclusively in Views via `BlocListener`.
   - **No Direct Data/Network Calls in Views or ViewModels**: Views never call `sl<...Repository>()` or `ApiClient` in `initState()` with `setState()`, and ViewModels never depend directly on `Dio` or `RemoteDataSource`. Every data flow strictly follows `View ➔ Bloc/Cubit ➔ Domain Repository Contract ➔ Repository Impl ➔ DataSource`.
   - **No Native Binaries in `lib/`**: Never place compiled native artifacts (`.so`, `.dll`, `.dylib`) inside `lib/`.
2. **60/120 FPS Rendering & Rebuild Isolation**:
   - **Scoped Selection**: Never use `context.watch<Bloc>()` at the root of complex screens (`MatchDetailsView`, `TeamView`); always use `context.select(...)` or `BlocBuilder(buildWhen: ...)` to isolate 1Hz WebSocket updates.
   - **Leaf-Only Live Clocks**: Live `MM:SS` timers (`CircularLiveClock`) use `ValueNotifier<String>` + `ValueListenableBuilder` rather than `setState()` so 1Hz ticks only update the `Text` leaf.
   - **No Nested `shrinkWrap` Lists**: Bounded tables (`StandingsTable`, `TopScorersTable`) inside scrollable views use `RepaintBoundary` + `Column` instead of `ListView.separated(shrinkWrap: true)`.
   - **Gesture & Swipe Isolation**: Never dispatch asynchronous state changes inside active swipe callbacks (like `onPageChanged`). Defer to `ScrollEndNotification`.
3. **Idiomatic `Skeletonizer` Loading Standard**:
   - All loading states inherit the centralized theme-aware `SkeletonizerConfig` in `lib/app/app.dart` without redundant per-screen `ShimmerEffect` overrides.
   - **Real Widgets + Dummy Entities**: List and table skeletons wrap actual presentation widgets (`LeagueSectionWidget`, `MatchCard`, `StandingsTable`, `TopScorersTable`, `TransferCard`, `VideoCard`, `TimelineEventItem`) with dummy entities inside `Skeletonizer`.
   - **`Bone.*` Primitives for Custom Layouts**: Detail views and sheets use `Bone.text`, `Bone.multiText`, `Bone.circle`, `Bone.square`, `Bone.icon`, and `Skeleton.leaf` inside themed cards — never raw `Container(color: Colors.grey)` boxes, static un-animated containers, or bare full-screen `CircularProgressIndicator`s.
4. **404 Empty State Disambiguation**: Temporal schedules returning 404 or `"لا توجد مباريات"` represent scheduled empty days (`ApiSuccess([])`), never server errors.
