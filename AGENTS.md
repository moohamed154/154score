# Flutter MVVM Architecture & Comprehensive Engineering Standards

This repository adheres strictly to the **Flutter MVVM (Model-View-ViewModel) Architecture & Clean Code Standard**.
This document serves as the single source of truth for the entire **154Score** application codebase.

For low-level architectural blueprints and diagrams, see:
👉 [`.agents/rules/flutter-mvvm-architecture.md`](.agents/rules/flutter-mvvm-architecture.md)

---

## 1. Core Architectural Standards & Layer Separation

* **Model Layer (Data & Domain)**:
  * **Repositories**: Abstract contracts in `domain/repositories/` and concrete implementations in `data/repositories/`. The repository is the single source of truth for all data access.
  * **Data Sources**: Remote APIs (centralized `Dio` / `ApiClient` with authentication interceptors in `data/datasources/`) and local persistence (`SharedPreferences`, `LocalStorageService`, `Hive`).
  * **Models & DTOs**: Immutable entities using `Equatable` with clean `fromJson` / `toJson` serialization.
  * **Raw Data Integrity**: Always prioritize raw API image fields (`team_1_logo`, `team_2_logo`, `logo`) over resolver fallbacks. Never overwrite valid backend strings.
  * **No Native Binaries in `lib/`**: Never commit or place compiled native binaries (`.so`, `.dll`, `.dylib`) inside `lib/`.

* **ViewModel Layer (State & Business Logic)**:
  * Pure state management using **`Bloc` / `Cubit`**.
  * UI state classes are immutable, holding `status`, `data`, `errorMessage`, and implementing `copyWith`.
  * **STRICT RULE — Zero UI Imports**: **Zero `BuildContext` or Flutter UI widget imports in ViewModels**. All navigation, dialogs, snackbars, and theme inspections belong exclusively in the View layer.
  * **STRICT RULE — No Direct `Dio` / `ApiClient` in ViewModels**: ViewModels must depend exclusively on abstract `domain/repositories/` contracts injected via constructor, never directly on `Dio`, `ApiClient`, or `RemoteDataSource`.

* **View Layer (Pure UI)**:
  * Pure `StatelessWidget` UI components (use `StatefulWidget` only when managing local animation controllers, text controllers, or scroll controllers).
  * **STRICT RULE — No Direct Repository or Network Calls in Views**: Views must **never** call `sl<...Repository>()` or `ApiClient` inside `initState()` to manage local `isLoading` / `error` / `data` fields via `setState()`. Every screen or detail view (`NewsDetailView`, `VideoDetailsView`, `GenericProfileView`, etc.) must use a dedicated `Bloc` or `Cubit` (`NewsDetailCubit`, `VideoDetailCubit`, `ProfileCubit`) registered in `core/di/injection_container.dart`.
  * Consumes state via targeted `BlocBuilder` / `BlocConsumer` with specific `buildWhen` conditions or `context.select(...)`.
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
  * `"Half Time"` / `"HT"` ➔ `"استراحة"`
  * `"Penalties"` / `"Penalty Shootout"` ➔ `"ترجيح"`
  * `"Penalty Scored"` ➔ `"ركلة جزاء مسجلة"`
  * `"Penalty Missed"` ➔ `"ركلة جزاء ضائعة"`
  * `"Yellow Card"` ➔ `"بطاقة صفراء"`
  * `"Red Card"` ➔ `"بطاقة حمراء"`
  * Competition name: `"دوري ORA"` / `"الدوري المصري الممتاز"`.

---

## 6. Comprehensive Feature Catalog & Implementation Rules

### 1. Matches & Home View (`features/matches`, `features/home`)
* **Horizontal Date Selector**: Allows navigating days forward and backward; highlights the current day; RTL scroll-friendly.
* **Calendar Date Picker**: Bottom sheet / dialog to jump directly to any date.
* **League Grouping**: Matches are partitioned by championship with expand/collapse toggle.
* **Live Score Card & Live Clock Standard**:
  * Live pulse badge for active matches (`AppColors.liveRed`), score display, penalty shootouts, red cards, and match minute.
  * Live clock format is strictly `MM:SS` (e.g. `65:30`) during active play, displaying `"استراحة"` during half-time intermission and `"ترجيح"` during penalty shootouts.
* **Starred Toggle**: Quick star icon on championship headers and match cards.
* **Horizontal Swiping & Date Navigation Isolation (60/120 FPS Standard)**:
  * **Zero Mid-Swipe Bloc Emissions**: Never dispatch `LoadMatchesEvent` or trigger BLoC state updates inside `PageView.onPageChanged`. `onPageChanged` fires at 50% scroll offset mid-gesture, causing heavy rebuild passes, frame drops, and scroll lock collisions.
  * **Defer to `ScrollEndNotification`**: Listen via `NotificationListener<ScrollNotification>` and only dispatch `LoadMatchesEvent(date: newDate)` once the swipe animation completely stops (`notification is ScrollEndNotification`).
  * **Layer Composition via `RepaintBoundary`**: Wrap each day page (`_HomeDayPage`) in `RepaintBoundary` and use `AutomaticKeepAliveClientMixin` (`wantKeepAlive: true`) so the GPU compositor shifts cached layer surfaces with zero per-frame widget rasterization during horizontal swipes.
  * **Instant In-Memory Cache (0ms)**: Memoize filtered leagues per date (`_cachedFilteredDateLeagues` / `_cachedDateLeagues`) and background-prewarm adjacent days ($D-1$, $D+1$) with debouncing (150ms). On swiping or date selection, render cached leagues immediately without flashing skeleton loaders.
* **Empty Date Handling (404 & "لا توجد مباريات" Standard)**:
  * **Not a Server Failure**: Backend responses returning HTTP 404, `success: false`, or `"لا توجد مباريات"` / `"no matches"` represent a scheduled day with 0 matches (**Empty State**), NOT a server error.
  * **Repository & DataSource Mapping**: Data sources and repositories must catch 404 and "لا توجد مباريات" and return `ApiSuccess(<LeagueGroupEntity>[])` / `<LeagueGroupDto>[]`.
  * **Pure Empty View**: The UI must render the clean `EmptyView` with the soccer ball icon and `"no_matches_date"` (`لا توجد مباريات في هذا اليوم`), and **NEVER display error screens ("حدث خطأ ما"), disconnected Wi-Fi icons, or retry buttons** for empty days.

### 2. Match Details (`features/match_details`)
* **Match Header Banner**: Dynamic team crests, live minute timer, score, aggregate score, venue, and referee.
* **Match Status Integrity & Tab Filtering Standards**:
  * **Upcoming Matches Tab Filtering**: For matches that have not started (`لم تبدأ` / `upcoming`), **NEVER show Events (`الأحداث`) or Statistics (`الإحصائيات`) tabs**. The active tabs must strictly be `[التفاصيل, التشكيلة, الترتيب, الهدافون, الصناع, الأخبار]`.
  * **Cancelled & Postponed Matches Tab Filtering**: If a match is cancelled (`ألغيت` / `cancelled`) or postponed (`تأجلت` / `postponed`), **NEVER show Events (`الأحداث`) or Statistics (`الإحصائيات`) tabs**.
  * **Center Header Pill**: For cancelled/postponed matches, display the kickoff time and status badge (`ألغيت` in high-contrast red or `تأجلت`), and **NEVER display dummy `0 - 0` scores or overwrite status to `انتهت`**.
  * **Protection from Overwrites**: `MatchDetailsBloc` and `MatchDetailsView` must strictly safeguard `ألغيت` and `تأجلت` from being overwritten by timeline placeholder events (`بداية الشوط الأول`) or elapsed calendar dates.
* **Timeline Events & Vector Icons Catalog**:
  * High-fidelity vector icons matching Yalla Shoot visual language (`match_event_visual_icon.dart`):
    * **Penalty Scored**: Treated and rendered visually as a **Goal** with a green circle background (`AppColors.primary`), white soccer ball icon, minute badge, and Arabic label `"ركلة جزاء مسجلة"`.
    * **Penalty Missed**: Red badge with cross/miss indicator (`AppColors.relegationRed`) and label `"ركلة جزاء ضائعة"`.
    * **Missed Chance & Woodwork**: Distinct vector icons for missed opportunities and crossbar/post hits.
    * **Cards**: Rectangular yellow (`AppColors.yellowCard`) and red (`AppColors.redCard`) badges.
    * **Substitutions**: Cyan twin directional arrows (`AppColors.substitution`).
    * **VAR**: High-contrast orange screen icon (`AppColors.varEvent`).
    * **Stoppage Time**: Dedicated badge displaying exact stoppage time addition (e.g. `+4`).
  * **Symmetrical Event Alignment**: Timeline event slots are symmetrically balanced across home (team 1) and away (team 2) sides across both RTL and LTR viewports.
* **Details Tab (`التفاصيل`) Theme & Brand Integration**:
  * Special notices and cancellation alerts must strictly adhere to the app's primary theme: `AppColors.primary` (`#00C853`) for the `Icons.info_outline_rounded` icon and border accents, with standard themed card background (`AppColors.darkCard` / light green tint `0xFFF0FDF4`). Arbitrary colors (like blue `#3B82F6`) are strictly forbidden.
* **Standings Group Prioritization**:
  * In competitions with multi-group structures (e.g. World Cup, Club World Cup), the specific group containing the two playing teams is prioritized to appear first at the top of the Standings tab with a `مجموعة المباراة` badge.
* **Match Share Link**:
  * When sharing a match from `MatchDetailsView`, the download/share link in both Arabic and English text templates is strictly `https://154score-api.medohs770.workers.dev/`.
* **WebSocket Room**: Auto-subscribes to `match:{id}` on init and un-subscribes on dispose.

### 3. Leagues & Competitions (`features/leagues`)
* **League Header Card**: Dynamic theme-aware logo, country badge, `"الموسم الحالي"` badge, and favorite toggle star.
* **Aliases & Resolution (`league_resolver.dart` / `url_helper.dart`)**:
  * Seamless normalization and resolution across English and Arabic aliases for major competitions: UCL (`دوري أبطال أوروبا`), UEL (`الدوري الأوروبي`), UECL (`دوري المؤتمر الأوروبي` / `UEFA Conference League`), Premier League, La Liga, Serie A, Egyptian Premier League (`دوري ORA`), Saudi Pro League, etc.
* **Tabs**:
  1. **Matches**: Full schedule partitioned by date / game week.
  2. **Standings**: Full league table or tournament stage selector.
  3. **Top Scorers**: Player list with goals, penalties, team badge, and rank.
  4. **Assists**: Top playmakers list with assists count and team badge.

### 4. Standings (`features/standings`)
* **Two-Tier Cache Standard (0ms First Paint)**:
  * In-memory cache (`_cachedStandings`) for immediate instant re-renders.
  * Persistent storage via `LocalStorageService` to retain standings offline across app restarts.
  * **Startup Pre-Warming**: Call `prewarmStandingsCache()` on app initialization to hydrate top championships before the user navigates to the Standings tab.
* **Tables**: Position, Club badge & name, Played, Won, Drawn, Lost, Goals difference, Points.
* **Qualification Indicators**:
  * Green bar: UEFA Champions League (`AppColors.uclGreen`).
  * Blue bar: UEFA Europa League (`AppColors.uelBlue`).
  * Orange bar: UEFA Conference League (`AppColors.ueclOrange`).
  * Red bar: Relegation zone (`AppColors.relegationRed`).
* **Multi-Stage & Groups**: Dropdown selector for tournament stages (Group Stage, Round of 16, Quarter-finals, Semi-finals, Final).
* **Tournament Stages Time Format (12h/24h)**: Match cards in tournament knockout stages (`TournamentStagesWidget`) and match info tables must strictly respect the user's active time format setting (`'12h'` or `'24h'`) via `DateFormatter.formatDisplayTime`, eliminating raw unformatted strings (`22:00:00` ➔ `10:00 PM` in 12h or `22:00` in 24h).
* **Favorites Partitioning**: Pin user's starred competitions to the top with drag-to-reorder support.

### 5. Teams (`features/teams`)
* **Header**: Club crest, country, manager, foundation year, and stadium.
* **Tabs**: Squad roster grouped by position (Goalkeepers, Defenders, Midfielders, Attackers), upcoming fixtures, recent results, and transfers.
* **Notifications**: Bell icon to subscribe/unsubscribe from team-specific push alerts.

### 6. Players & Profiles (`features/players`, `features/profiles`)
* **Header**: Player photo, nationality flag, club badge, jersey number, and position.
* **Metrics**: Age, height, preferred foot, market value pill, contract expiry.
* **Injury Status & Details**:
  * Active injury badge (`inj_active`) displayed prominently on player cards and squad lists.
  * Tapping the injury badge opens the **Injury Details Bottom Sheet** detailing injury type, expected return date, and missing matches.
* **Career History & Transfers**: Chronological club transfer fees and dates.
* **Trophies & Honors**: Career achievements.

### 7. Transfers (`features/transfers`)
* **Architecture**: State managed by `TransfersBloc` with clean pagination support via `transfer_more` endpoint and real-time updates.
* **Feed**: Real-time market transfer cards showing player photo, source club crest, destination club crest, transfer fee, and contract duration.
* **Filters**: Filter by league, transfer type (Permanent, Loan, Free), or date.

### 8. News & Videos (`features/news`, `features/videos`)
* **News Feed & Article Share Standards**:
  * Breaking news banner carousel, categorized sports articles, publish time, and thumbnail.
  * **Static News Share URL**: The share message text must strictly append the static URL `https://154score-api.medohs770.workers.dev/` (never raw or unbranded external endpoints).
  * **Branded News Share Photo**: The generated share card (`_buildShareCard`) must prominently display the official app brand logo (`assets/images/app_logo.png` / fallback `assets/icons/app_icon.png`) alongside the `154 SCORE` branding text in the footer capsule badge.
* **Videos Feed & Placeholder Standard**:
  * Goal clips and match highlights with embedded responsive video player.
  * **Branded Video Placeholders**: Always use branded pitch thumbnail placeholders (`assets/images/video_placeholder.png` or themed gradient container); never display external/unbranded default placeholders.
  * **Graceful 404 Handling**: Video detail lookups returning 404 must display an inline notice without crashing the video feed.

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
* **Font Size Adjustments**: Dedicated font size settings view with dynamic UI scaling.
* **Notification Preferences**: Toggles per alert type (goals, kick-off, news).
* **Unified Settings Icon Containers**: All settings option tiles share a unified container token (`AppColors.darkCardElevated` / light background) with standard border radius and padding.
* **Unified AppBar Back Button Icon (`Icons.arrow_back_ios_new_rounded`)**: All screens and sub-pages (including `PrivacyPolicyView`, `FontSizeSettingsView`, `ThemeSettingsView`, etc.) must strictly use the rounded chevron back icon `Icons.arrow_back_ios_new_rounded` (configured globally in `AppTheme.actionIconTheme.backButtonIconBuilder`, or explicitly with `Icons.arrow_back_ios_new_rounded, size: 20`). **Never override AppBar `leading` with `Icons.arrow_back_rounded` (`←`)**. `Icons.arrow_back_ios_new_rounded` automatically mirrors across LTR (`<`) and RTL (`>`) layouts via `matchTextDirection: true`.
* **Privacy Policy Web URL**: The official external privacy policy URL in `PrivacyPolicyView` is strictly `https://154score-api.medohs770.workers.dev/privacy`.
* **Developer Tools & Diagnostics Security**: Developer mode is protected and hidden by default. Unlocking it requires tapping the app brand logo 10 times in Settings, followed by entering the master developer password (`MOhamed_2002`). Unlocking displays the developer and diagnostics suite; locking hides it until re-authenticated. The password prompt must be encapsulated in a dedicated `StatefulWidget` so `TextEditingController` is disposed cleanly within `State.dispose()` after pop animations conclude, avoiding `used after being disposed` crashes.

### 13. Onboarding & First-Launch Setup (`features/onboarding`)
* **Branded Chips**: All team and league selection chips in the onboarding flow must display crisp logos alongside their titles (`UrlHelper.resolveTeamLogo` for clubs and `UrlHelper.resolveChampionshipLogo` with `isDark` adaptation for leagues/tournaments).
* **RTL Arrow Direction**: The navigation back button must strictly respect RTL layout semantics, pointing to the right (`→`) in Arabic to reflect navigating backward to the previous screen. In Flutter, `Icons.arrow_back_rounded` has `matchTextDirection: true` and automatically mirrors to point right (`→`) in RTL environments; never manually swap it with `Icons.arrow_forward_rounded` as that causes an unintentional double-flip.

### 14. Tactical Pitch Lineups & Match Player Statistics (`features/match_details/presentation/widgets/lineup/`)
* **Tactical Pitch View (`match_pitch_widget.dart`)**:
  * Realistic pitch painter with penalty areas, center circle, and goal boxes.
  * Formations rendered dynamically (4-3-3, 4-2-3-1, 3-5-2, etc.) with responsive coordinate mapping.
  * Player nodes (`pitch_player_node.dart`) show player photo, jersey number, rating pill, captain badge, yellow/red card badges, and goal indicators.
  * Full RTL/LTR layout mirroring for pitch board orientation and team bench order.
* **Player Match Statistics Sheet (`player_match_stats_sheet.dart`)**:
  * Tapping any starting or substitute player opens the high-detail match statistics modal bottom sheet.
  * Displays: Overall match rating, minutes played, goals, assists, total passes, pass accuracy, shots on target, tackles, duels won, fouls committed, and substitution timestamps.

### 15. Live Activity & Lock Screen Widgets (`features/live_activity/`)
* **Cross-Platform Live Score Tracking**:
  * Android: Live Notification with RemoteViews layout using `FrameLayout` for layout stability (eliminating RemoteViews inflation errors).
  * iOS: Dynamic Island & Lock Screen Live Activity via ActivityKit.
* **Live Clock Synchronization**:
  * Matches the in-app `MatchCard` clock formatting (`MM:SS`, e.g. `65:30`).
  * Chronometer base timestamp is fixed and stabilized to prevent live clock freezing or resetting at 55 minutes, with interval widened to 180m.
* **Embedded App Assets**:
  * iOS lock screen uses base64 embedded app brand logo to guarantee zero image load failures.
  * Club crests are pre-cached and normalized before dispatching Live Activity updates.
* **Feature Toggle**:
  * Disabled by default to conserve background battery; toggleable via Settings and Developer Tools.

### 16. Connectivity Monitoring & Offline Dialog (`features/internet_connection/`)
* **Global Network Listener (`global_internet_connection_listener.dart`)**:
  * Continuously monitors network connection states via `InternetConnectionCubit`.
  * Detects network drops and automatically restores socket rooms and REST polling upon reconnection.
* **Offline Dialog (`no_internet_dialog.dart`)**:
  * Clean themed modal displaying connection loss notice with retry button and fallback to cached local data.

---

## 7. Dependency Injection & Service Locator (`get_it`)

* Centralized registration in `core/di/injection_container.dart`:
  * **Singletons**: Core utilities (`Dio`, `LocalStorageService`, `Repositories`, `NotificationService`).
  * **Factories**: ViewModels / Cubits (`registerFactory` creates a fresh instance per screen lifecycle).
* **Constructor Parameter Standard**: Avoid language-gated `private-named-parameters` (`required this._privateField`). Always declare clean public named constructor parameters and bind them via initializer lists:
  ```dart
  HomeCubit({
    required VideosRepository videosRepository,
    required TransfersRepository transfersRepository,
    required LocalStorageService localStorageService,
  })  : _videosRepository = videosRepository,
        _transfersRepository = transfersRepository,
        _localStorageService = localStorageService,
        super(const HomeState());
  ```
* Initialized in `main.dart` before `runApp()`.

---

## 8. Performance & 60/120 FPS Rendering Standards

* **Mandatory `const` Constructors**: Mark every immutable widget with `const` to eliminate redundant rebuilds.
* **Scoped Rebuilds (`context.select` & `buildWhen`)**:
  * **NEVER use `context.watch<Bloc>()` at the top of a screen's `build()` method** (e.g., `MatchDetailsView`, `TeamView`) when only a sub-property is needed. Always use `context.select((Bloc b) => ...)` or a targeted `BlocBuilder(buildWhen: ...)` so 1Hz live WebSocket ticks do not rebuild the entire screen and its tab subtrees.
* **1Hz Live Timer Isolation (`ValueNotifier`)**:
  * In 1Hz ticking clock widgets (such as `CircularLiveClock`), **never call `setState()` every second**. Use `ValueNotifier<String>` + `ValueListenableBuilder<String>` so only the leaf `Text` widget updates without dirtying parent layout elements.
* **Optimized Scrolling & No Nested `shrinkWrap` Lists**:
  * Use `ListView.builder` / `CustomScrollView` with `itemExtent` or `prototypeItem` for primary scrollables.
  * **NEVER nest `ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` inside another scrollable** for bounded tables (`StandingsTable`, `TopScorersTable`, profile info lists), as `shrinkWrap: true` forces $O(N)$ intrinsic layout passes on every scroll frame. Instead, use a `Column` wrapped in `RepaintBoundary` or `SliverList`.
* **Memory & Image Caching**: Always use `cached_network_image` via `AppImage` with explicit `memCacheWidth` and `memCacheHeight` to prevent bitmap memory bloat.
* **Repaint Boundaries & Layer Isolation**: Wrap animations, loaders, custom painters, bounded tables, and multi-page items (`_HomeDayPage` inside `PageView`) with `RepaintBoundary` so GPU compositing translates rasterized layers without per-frame subtree repainting.
* **Gesture & Transition Isolation**: Never dispatch asynchronous state changes or trigger BLoC state emissions within active user touch gestures (e.g. `onPageChanged`, `onPanUpdate`). Always defer state emissions until gestures settle (`ScrollEndNotification` or physics idle) to preserve native 60/120 FPS transitions without frame drops.
* **Resource Disposal**: Always call `.dispose()` on `TextEditingController`, `AnimationController`, `ScrollController`, `PageController`, `ValueNotifier`, and cancel all `StreamSubscription` instances.
* **Floating SnackBar Standard**: All notifications and feedback SnackBars must use floating behavior (`SnackBarBehavior.floating`), high-contrast dark card background (`Color(0xFF1E293B)`), pure white text (`Colors.white`, font weight 600), rounded border radius (`12px`), and an accent border to ensure perfect readability in both Dark and Light modes.

---

## 8.1 Idiomatic `Skeletonizer` Loading Standard (Mandatory)

All screen, tab, and modal loading states across the application must use the `skeletonizer` package in its idiomatic form:

* **Inherit Global `SkeletonizerConfig`**:
  * `SkeletonizerConfig` is configured globally at the root in `lib/app/app.dart` with theme-aware `ShimmerEffect` colors.
  * **NEVER hardcode redundant `effect: ShimmerEffect(...)` overrides** on individual `Skeletonizer` widgets unless a surface has a unique non-standard background.
* **Pattern 1 — Real Widget + Dummy Entities (Preferred)**:
  * Wrap the real presentation widget (`LeagueSectionWidget`, `MatchCard`, `StandingsTable`, `TopScorersTable`, `TransferCard`, `VideoCard`, `NewsListItem`, `TimelineEventItem`) inside `Skeletonizer(enabled: true, child: ...)` populated with realistic dummy `Entity` items (`MatchEntity`, `StandingRowEntity`, `TopScorerEntity`, etc.).
  * `Skeletonizer` automatically converts child `Text`, `Icon`, and image leaf nodes into matching shimmer bones that stay 100% in sync with UI layout changes.
* **Pattern 2 — `Bone.*` Primitives (For Custom Detail Layouts)**:
  * When a dummy entity is not applicable (e.g. `NewsDetailView`, `VideoDetailsView`, `PlayerView`, `GenericProfileView`, `NotificationsView`, `PlayerMatchStatsSheet`), construct themed card containers (`isDark ? AppColors.darkCard : AppColors.lightCard`) and populate them with `Bone.text(words: ...)`, `Bone.multiText(lines: ...)`, `Bone.circle(size: ...)`, `Bone.square(size: ..., borderRadius: ...)`, `Bone.icon()`, and `Skeleton.leaf(child: ...)`.
* **Strictly Forbidden Loading Anti-Patterns**:
  * **NEVER** wrap raw `Container(color: Colors.grey)` blocks inside `Skeletonizer` or use `ignoreContainers: false` to fake bones.
  * **NEVER** build static, un-animated grey `Container` boxes without wrapping them in `Skeletonizer`.
  * **NEVER** use a bare `CircularProgressIndicator` for initial full-screen, tab, or bottom-sheet content loading (reserve `CircularProgressIndicator` strictly for inline button action spinners or pagination footers).

---

## 9. Error Handling & Result Pattern

* Use a sealed `ApiResult<T>` wrapper (or `Either<Failure, T>`) so unhandled exceptions never crash ViewModels:
  ```dart
  sealed class ApiResult<T> { const ApiResult(); }
  class Success<T> extends ApiResult<T> { final T data; const Success(this.data); }
  class Failure<T> extends ApiResult<T> { final String message; final int? statusCode; const Failure(this.message, {this.statusCode}); }
  ```
* **Temporal Resource 404 Disambiguation**: When an endpoint queries temporal collections (e.g. `/matches?date=...` or `/matches/live`), an HTTP 404 response or backend message containing `"لا توجد مباريات"` / `"no matches"` MUST be interpreted as an empty dataset success (`ApiSuccess([])`), never as a service failure (`ApiFailure`).
* Centralized interceptors for HMAC security authentication tokens (`X-Timestamp`, `X-Nonce`, `X-Signature`), error mapping, and logging.

---

## 10. Shorebird Code Push & Over-The-Air (OTA) Updates

* **Configuration**:
  * Configured in `shorebird.yaml` with `app_id: 0796e137-d14c-43d3-a3cb-5145f1de0aa4`.
  * Tracked in `pubspec.yaml` assets (`- shorebird.yaml`).
  * Auto-update enabled by default: patches are downloaded silently in the background on app launch and applied on the next start without store reviews or user friction.
* **Release & Patch Operations**:
  * **Android Release**: `shorebird release android`
  * **Android Instant Patch**: `shorebird patch android`
  * **iOS Release / Patch**: `shorebird release ios` / `shorebird patch ios` (executed on macOS / CI with Xcode).
* **SDK Compatibility**: Maintain `environment: sdk: '>=3.5.0 <4.0.0'` in `pubspec.yaml` to ensure seamless version solving across various Flutter and Shorebird engine versions.

---

## 11. Feature-First Folder Structure Template

```text
lib/
├── app/                    # App root, SkeletonizerConfig, GoRouter setup
├── core/                   # Shared tokens, DI, network, routes, theme, utils, localization
│   ├── constants/          # Colors, typography, dimensions, api_endpoints
│   ├── di/                 # Centralized GetIt service locator (injection_container.dart)
│   ├── network/            # Dio client, HMAC interceptors, ApiResult<T>
│   ├── security/           # Signature generation, nonce, timestamp
│   ├── storage/            # LocalStorageService, cache keys
│   ├── theme/              # AppTheme, theme cubit, mode persistence
│   ├── utils/              # url_helper, league_resolver, team_resolver, realtime_merge_engine
│   └── widgets/            # AppImage, error_view, empty_view, circular_live_clock
├── features/               # Feature-first modules
│   └── [feature_name]/
│       ├── data/
│       │   ├── datasources/# RemoteDataSource (ApiClient) & LocalDataSource
│       │   ├── models/     # DTOs with fromJson / toJson
│       │   └── repositories/# Concrete Repository implementations (*RepositoryImpl)
│       ├── domain/
│       │   ├── entities/   # Immutable Equatable domain entities
│       │   └── repositories/# Abstract Repository contracts (*Repository)
│       └── presentation/
│           ├── bloc/ | cubit/ | viewmodels/ # Pure state management (Zero UI/Dio imports)
│           ├── views/      # Pure UI screens & detail views (Zero direct Repository/ApiClient calls)
│           └── widgets/    # Reusable feature-specific UI components
└── main.dart               # Entry point, DI setup & runApp
```
