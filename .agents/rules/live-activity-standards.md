# ⏱️ Live Activity & Lock Screen Widgets Architecture Standards

This document establishes the architectural, platform, and synchronization standards for the Live Activity and Lock Screen widgets in the **154Score** application.

---

## 1. Cross-Platform Architecture

The Live Activity feature provides real-time live score and clock updates directly on the user's lock screen and dynamic surfaces:
- **Android**: Custom persistent Live Notification built with Android `RemoteViews` and foreground service notifications.
- **iOS**: Dynamic Island and Lock Screen Live Activities implemented via Apple's `ActivityKit` and WidgetKit.

---

## 2. Platform Implementation Guidelines

### 2.1 Android RemoteViews Layout Stability
1. **Container View Type**:
   - Always wrap custom notification layouts in `FrameLayout` or standard supported view types.
   - Never use arbitrary ViewGroup subclasses that fail XML inflation inside Android `NotificationManager` / `RemoteViews`.
2. **Channel & Importance**:
   - Channel: `live_matches` with `NotificationManager.IMPORTANCE_LOW` (so ongoing minute updates update silently without vibration or alert sound).
   - Set `ongoing: true` and `autoCancel: false` during active matches.

### 2.2 iOS ActivityKit & Dynamic Island
1. **Direct Embedded Branding**:
   - The lock-screen brand logo MUST be embedded as a direct base64 asset inside the Activity payload or bundle asset to avoid image load failures on the lock screen.
2. **Club Crests Pre-Fetching**:
   - Team crests must be downloaded and pre-cached locally on the device file system before initiating or updating an activity. Never pass un-cached remote HTTP URLs directly to `ActivityAttributes.ContentState`.

---

## 3. Clock & Chronometer Synchronization Standards

1. **Exact Formatting (`MM:SS`)**:
   - The live clock displayed on the lock screen MUST match the in-app `MatchCard` clock formatting (`MM:SS`, e.g. `65:30`).
2. **Base Timestamp Stabilization**:
   - Calculate the chronometer base timestamp using the server match start / half start timestamp.
   - Do NOT re-calculate or shift the chronometer base on minor network blips.
3. **180-Minute Interval Horizon**:
   - To prevent chronometers from freezing or resetting at 55 minutes, set the SwiftUI / RemoteViews chronometer bounds to 180 minutes.
4. **Special Match Intermissions**:
   - Half Time: Display `"استراحة"` (HT) with a paused timer indicator.
   - Penalty Shootout: Display `"ترجيح"` (Penalties) instead of running clock.

---

## 4. State Management & Feature Toggles

1. **Default State**:
   - Live Activity is **disabled by default** to conserve background device battery.
2. **User & Developer Controls**:
   - Controlled via `LiveActivityCubit` (`features/live_activity/`).
   - Accessible from Settings and developer tools sheet.
3. **Automatic Lifecycle Cleanup**:
   - Live Activities must automatically end when a match status changes to `"انتهت"` (Finished), `"ألغيت"` (Cancelled), or `"تأجلت"` (Postponed).
