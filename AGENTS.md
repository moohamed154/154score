# Flutter MVVM Architecture & Comprehensive Engineering Standards

This repository adheres strictly to the **Flutter MVVM (Model-View-ViewModel) Architecture & Clean Code Standard**.
This document serves as the single source of truth for the entire **154Score** application codebase.

For low-level architectural blueprints and diagrams, see:
👉 [`.agents/rules/flutter-mvvm-architecture.md`](.agents/rules/flutter-mvvm-architecture.md)

---

## 1. Core Architectural Standards & Layer Separation

* **Model Layer (Data & Domain)**:
  * **Repositories**: Abstract contracts in `domain/repositories/` and concrete implementations in `data/repositories/`. The repository is the single source of truth for all data access.
  * **Data Sources**: Remote APIs (centralized `Dio` / `Http` client with authentication interceptors) and local persistence (`SharedPreferences`, `LocalStorageService`, `Hive`).
  * **Models & DTOs**: Immutable entities using `Equatable` with clean `fromJson` / `toJson` serialization.
  * **Raw Data Integrity**: Always prioritize raw API image fields (`team_1_logo`, `team_2_logo`, `logo`) over resolver fallbacks. Never overwrite valid backend strings.

* **ViewModel Layer (State & Business Logic)**:
  * Pure state management using **`Bloc` / `Cubit`**.
  * UI state classes are immutable, holding `status`, `data`, `errorMessage`, and implementing `copyWith`.
  * **STRICT RULE**: **Zero `BuildContext` or Flutter UI widget imports in ViewModels**. All navigation, dialogs, snackbars, and theme inspections belong exclusively in the View layer.

* **View Layer (Pure UI)**:
  * Pure `StatelessWidget` UI components (use `StatefulWidget` only when managing local animation controllers or scroll controllers).
  * Consumes state via targeted `BlocBuilder` / `BlocConsumer` with specific `buildWhen` conditions.
  * Handles one-off side effects (navigation, snackbars, toast messages) strictly inside `BlocListener`.
  * Dynamically queries theme brightness (`Theme.of(context).brightness == Brightness.dark`) to resolve theme-tailored assets.

---

## 2. Theme-Aware Images & Logo Guidelines (Dark & Light Mode)

* **Automatic Theme Adaptation (Mandatory)**:
  * **Championship & League Logos**:
    * Always render competition logos via `UrlHelper.resolveChampionshipLogo(leagueId, currentLogo: ..., isDark: isDark)`.
    * **Light Mode (`isDark == false`)**: Must ALWAYS use the dark/colored high-contrast variant (e.g. `17882925978755.png` for Egyptian League / دوري ORA, `5171696546919.png` for UCL, `3421703719071.png` for Saudi Pro League). **Never render white/light logos on light backgrounds.**
    * **Dark Mode (`isDark == true`)**: Must ALWAYS use the light/white contrast variant (e.g. `17882926672499.png` for دوري ORA, `3141696514284.png` for UCL).
    * `UrlHelper.resolveChampionshipLogo` automatically detects theme-paired logo filenames and swaps them reciprocal to the active theme.
  * **Container Backgrounds for Badges & Logos**:
    * Logo container boxes must adapt dynamically: `color: isDark ? AppColors.darkCardElevated : const Color(0xFFF8FAFC)`.
    * Use subtle borders (`color: isDark ? const Color(0xFF2A3447) : const Color(0xFFE2E8F0)`) so transparent logos remain distinctly visible.
  * **Navigation with Themed Logos**:
    * When pushing routes (e.g., `/league/$id`), always pass `isDark: isDark` to `UrlHelper.resolveChampionshipLogo` in the route's `extra` map.
    * In destination header widgets (such as `LeagueHeaderCard`), always re-resolve `resolvedLogo` using `isDark` from the active `BuildContext`.
* **App Brand Logo Protection**:
  * **STRICT RULE**: **NEVER modify, replace, or alter the app's own brand logo** (`assets/images/logo_dark.png`, `assets/images/logo_light.png` or the `154Score` app bar badge).

---

## 3. CDN & Image URL Conventions (YSScores CDN Rules)

* **Club / Team Logos**:
  * **NEVER construct URLs using numeric team IDs** (`https://imgs.ysscores.com/teams/64/{id}.png` is WRONG and returns a 1911-byte grey circular placeholder).
  * YSScores CDN stores club crests under unique timestamp filenames (e.g. `9981690292497.png`).
  * Always use the exact logo string returned by the API (`team_1_logo`, `team_2_logo`) normalized via `UrlHelper.normalizeImageUrl(...)`.
* **Championship / Tournament Logos**:
  * Base CDN path: `https://imgs.ysscores.com/championship/128/{filename}.png`.
  * Centralized mapping in `UrlHelper._getThemedChampionshipLogo` with light/dark variants.
* **Player Photos & Stadiums**:
  * Player photos: `UrlHelper.normalizePlayerPhotoUrl(...)`.
  * Stadiums: `UrlHelper.normalizeStadiumImageUrl(...)`.

---

## 4. Network, Security & Real-Time Engine

* **Security Interceptors & API Authentication**:
  * All REST requests require HMAC security validation headers (`X-Timestamp`, `X-Nonce`, `X-Signature`) handled centrally in `core/network/` and `core/security/`.
* **WebSocket Channels**:
  * Main channels: `live_matches_ar`, `live_matches_en`, `transfers_ar`.
  * Match-specific rooms: `match:{matchId}` for instant events, goal alerts, and minute ticks.
* **Realtime Merge Engine (`RealtimeMergeEngine`)**:
  * Merges incoming WebSocket live deltas with cached/REST snapshots smoothly without causing UI rebuild flicker or losing scroll position.
  * Prioritizes live WebSocket states over stale REST responses.

---

## 5. Arabic Localization & Sports Terminology

* **Arabic-First Standard**:
  * Arabic is the primary language. Ensure RTL layout integrity across all screens.
  * Never display raw English backend status strings directly on UI badges or chips.
* **Standard Terminology Mappings**:
  * `"Current"` / `"Current Season"` ➔ `"الموسم الحالي"`
  * `"Live"` ➔ `"مباشر"`
  * `"Finished"` / `"Ended"` ➔ `"انتهت"`
  * `"Upcoming"` ➔ `"لم تبدأ"`
  * `"Postponed"` ➔ `"تأجلت"`
  * `"Cancelled"` ➔ `"ألغيت"`
  * Competition name: `"دوري ORA"` / `"الدوري المصري الممتاز"`.

---

## 6. Comprehensive Feature Catalog & Implementation Rules

### 1. Matches (`features/matches`)
* **Horizontal Date Selector**: Allows navigating days forward and backward; highlights the current day; RTL scroll-friendly.
* **Calendar Date Picker**: Bottom sheet / dialog to jump directly to any date.
* **League Grouping**: Matches are partitioned by championship with expand/collapse toggle.
* **Live Score Card**: Live pulse badge for active matches (`AppColors.liveRed`), score display, penalty shootouts, red cards, and match minute.
* **Starred Toggle**: Quick star icon on championship headers and match cards.

### 2. Match Details (`features/match_details`)
* **Match Header Banner**: Dynamic team crests, live minute timer, score, aggregate score, venue, and referee.
* **Match Status Integrity (Cancelled & Postponed Standard)**:
  * **Strict Tab Filtering**: If a match is cancelled (`ألغيت` / `cancelled`) or postponed (`تأجلت` / `postponed`), **NEVER show Events (`الأحداث`) or Statistics (`الإحصائيات`) tabs**. The active tabs must strictly be `[التفاصيل, التشكيلة, الترتيب, الهدافون, الصناع, الأخبار]`.
  * **Center Header Pill**: For cancelled/postponed matches, display the kickoff time and status badge (`ألغيت` in high-contrast red or `تأجلت`), and **NEVER display dummy `0 - 0` scores or overwrite status to `انتهت`**.
  * **Protection from Overwrites**: `MatchDetailsBloc` and `MatchDetailsView` must strictly safeguard `ألغيت` and `تأجلت` from being overwritten by timeline placeholder events (`بداية الشوط الأول`) or elapsed calendar dates.
* **Details Tab (`التفاصيل`) Theme & Brand Integration**:
  * Special notices and cancellation alerts must strictly adhere to the app's primary theme: `AppColors.primary` (`#00C853`) for the `Icons.info_outline_rounded` icon and border accents, with standard themed card background (`AppColors.darkCard` / light green tint `0xFFF0FDF4`). Arbitrary colors (like blue `#3B82F6`) are strictly forbidden.
* **Standings Group Prioritization**:
  * In competitions with multi-group structures (e.g. World Cup, Club World Cup), the specific group containing the two playing teams is prioritized to appear first at the top of the Standings tab with a `مجموعة المباراة` badge.
* **Tabs**:
  1. **Events / Timeline**: Chronological match events (goals, VAR, substitutions, yellow/red cards) — hidden when match is cancelled or postponed.
  2. **Lineups**: Interactive tactical pitch preview (formations like 4-3-3, 4-2-3-1), starter ratings, substitutes list, and coach info.
  3. **Statistics**: Comparative progress bars (Possession %, Shots on target, Fouls, Corners, Offsides, Passes) — hidden when match is cancelled or postponed.
  4. **Head-to-Head (H2H)**: Historical encounters between the two clubs.
  5. **Standings**: Group/league standings table with current match's group prioritized.
* **WebSocket Room**: Auto-subscribes to `match:{id}` on init and un-subscribes on dispose.

### 3. Leagues & Competitions (`features/leagues`)
* **League Header Card**: Dynamic theme-aware logo, country badge, `"الموسم الحالي"` badge, and favorite toggle star.
* **Tabs**:
  1. **Matches**: Full schedule partitioned by date / game week.
  2. **Standings**: Full league table or tournament stage selector.
  3. **Top Scorers**: Player list with goals, penalties, team badge, and rank.
  4. **Assists**: Top playmakers list with assists count and team badge.

### 4. Standings (`features/standings`)
* **Tables**: Position, Club badge & name, Played, Won, Drawn, Lost, Goals difference, Points.
* **Qualification Indicators**:
  * Green bar: UEFA Champions League (`AppColors.uclGreen`).
  * Blue bar: UEFA Europa League (`AppColors.uelBlue`).
  * Orange bar: UEFA Conference League (`AppColors.ueclOrange`).
  * Red bar: Relegation zone (`AppColors.relegationRed`).
* **Multi-Stage & Groups**: Dropdown selector for tournament stages (Group Stage, Round of 16, Quarter-finals, Semi-finals, Final).
* **Favorites Partitioning**: Pin user's starred competitions to the top with drag-to-reorder support.

### 5. Teams (`features/teams`)
* **Header**: Club crest, country, manager, foundation year, and stadium.
* **Tabs**: Squad roster grouped by position (Goalkeepers, Defenders, Midfielders, Attackers), upcoming fixtures, recent results, and transfers.
* **Notifications**: Bell icon to subscribe/unsubscribe from team-specific push alerts.

### 6. Players & Profiles (`features/players`, `features/profiles`)
* **Header**: Player photo, nationality flag, club badge, jersey number, and position.
* **Metrics**: Age, height, preferred foot, market value, contract expiry.
* **Career History & Transfers**: Chronological club transfer fees and dates.
* **Trophies & Honors**: Career achievements.

### 7. Transfers (`features/transfers`)
* **Feed**: Real-time market transfer cards showing player photo, source club crest, destination club crest, transfer fee, and contract duration.
* **Filters**: Filter by league, transfer type (Permanent, Loan, Free), or date.

### 8. News & Videos (`features/news`, `features/videos`)
* **News Feed**: Breaking news banner carousel, categorized sports articles, publish time, and thumbnail.
* **Videos Feed**: Goal clips and match highlights with embedded responsive video player.

### 9. Universal Search (`features/search`)
* **Debounced Search**: Queries matches, leagues, teams, and players simultaneously with debouncing (300ms).
* **Search Results**: Categorized results with theme-aware badges and direct routing.

### 10. Favorites & Bookmarks (`features/favorites`)
* **Favorites Cubit**: Central management for starred leagues, teams, and matches.
* **Unified Star Toggle Standard**: Favoriting and unfavoriting are performed exclusively through the universal star/heart action buttons distributed across match cards, tournament headers, and club profile headers.
* **Favorites View (`FavoritesView`)**: Pure list and management surface for user-pinned clubs and competitions. **Never add manual "إضافة" (Add) dialog buttons to the Favorites screen** as favorites originate directly from the app's browsing surfaces.
* **Persistence**: Synchronized immediately with `LocalStorageService`.
* **Priority Reordering**: Custom ordering reflected across Home and Standings screens.

### 11. Notifications (`features/notifications`)
* **Push Notifications (FCM)**: Match start, goal alerts, red cards, full-time result, and breaking news.
* **Local Notifications**: Offline fallback reminders.

### 12. Settings & System (`features/settings`)
* **Theme Mode**: Dark, Light, System default.
* **Language**: Arabic (primary), English.
* **Notification Preferences**: Toggles per alert type (goals, kick-off, news).

### 13. Onboarding & First-Launch Setup (`features/onboarding`)
* **Branded Chips**: All team and league selection chips in the onboarding flow must display crisp logos alongside their titles (`UrlHelper.resolveTeamLogo` for clubs and `UrlHelper.resolveChampionshipLogo` with `isDark` adaptation for leagues/tournaments).
* **RTL Arrow Direction**: The navigation back button must strictly respect RTL layout semantics, pointing to the right (`→`) in Arabic to reflect navigating backward to the previous screen. In Flutter, `Icons.arrow_back_rounded` has `matchTextDirection: true` and automatically mirrors to point right (`→`) in RTL environments; never manually swap it with `Icons.arrow_forward_rounded` as that causes an unintentional double-flip.

---

## 7. Dependency Injection & Service Locator (`get_it`)

* Centralized registration in `core/di/injection_container.dart`:
  * **Singletons**: Core utilities (`Dio`, `LocalStorageService`, `Repositories`, `NotificationService`).
  * **Factories**: ViewModels / Cubits (`registerFactory` creates a fresh instance per screen lifecycle).
* Initialized in `main.dart` before `runApp()`.

---

## 8. Performance & 60/120 FPS Rendering Standards

* **Mandatory `const` Constructors**: Mark every immutable widget with `const` to eliminate redundant rebuilds.
* **Scoped Rebuilds**: Wrap only the specific child subtree that depends on state changes (`buildWhen` / `Selector`), never the whole screen.
* **Optimized Scrolling**: Use `ListView.builder` / `CustomScrollView` with `itemExtent` or `prototypeItem`.
* **Memory & Image Caching**: Always use `cached_network_image` via `AppImage` with explicit `memCacheWidth` and `memCacheHeight` to prevent bitmap memory bloat.
* **Repaint Boundaries**: Wrap animations, loaders, and custom painters with `RepaintBoundary`.
* **Resource Disposal**: Always call `.dispose()` on `TextEditingController`, `AnimationController`, `ScrollController`, `PageController`, and cancel all `StreamSubscription` instances.
* **Floating SnackBar Standard**: All notifications and feedback SnackBars must use floating behavior (`SnackBarBehavior.floating`), high-contrast dark card background (`Color(0xFF1E293B)`), pure white text (`Colors.white`, font weight 600), rounded border radius (`12px`), and an accent border to ensure perfect readability in both Dark and Light modes.

---

## 9. Error Handling & Result Pattern

* Use a sealed `ApiResult<T>` wrapper (or `Either<Failure, T>`) so unhandled exceptions never crash ViewModels:
  ```dart
  sealed class ApiResult<T> { const ApiResult(); }
  class Success<T> extends ApiResult<T> { final T data; const Success(this.data); }
  class Failure<T> extends ApiResult<T> { final String message; final int? statusCode; const Failure(this.message, {this.statusCode}); }
  ```
* Centralized interceptors for HMAC security authentication tokens (`X-Timestamp`, `X-Nonce`, `X-Signature`), error mapping, and logging.

---

## 10. Feature-First Folder Structure Template

```text
lib/
├── core/                   # Shared tokens, DI, network, routes, theme, utils, localization
│   ├── constants/          # Colors, typography, dimensions, api_endpoints
│   ├── network/            # Dio client, HMAC interceptors, WebSocket manager
│   ├── security/           # Signature generation, nonce, timestamp
│   ├── storage/            # LocalStorageService, cache keys
│   ├── theme/              # AppTheme, theme cubit, mode persistence
│   ├── utils/              # url_helper, league_resolver, team_resolver, realtime_merge_engine
│   └── widgets/            # AppImage, error_view, empty_view, starred_button
├── features/               # Feature-first modules
│   └── [feature_name]/
│       ├── data/           # Repositories (impl), DataSources, DTOs
│       ├── domain/         # Repositories (contracts), Entities
│       └── presentation/
│           ├── viewmodels/ # Cubits, Blocs, States
│           ├── views/      # Screens, Pages
│           └── widgets/    # Reusable feature-specific UI
└── main.dart               # Entry point, DI setup & runApp
```
