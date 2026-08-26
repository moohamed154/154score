# ⚽ 154Score - Production-Ready Football Application

<div align="center">

**A production-quality football application built with Flutter, MVVM + BLoC Clean Architecture, and real-time Socket.IO WebSockets.**

[![Flutter](https://img.shields.io/badge/Flutter-3.47.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.0-0175C2?logo=dart)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM%20%2B%20Clean%20%2B%20BLoC-success)](#architecture)
[![WebSocket](https://img.shields.io/badge/Real--Time-Socket.IO-brightgreen)](#real-time-websocket)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-blue)](#platforms)

</div>

---

## 🌟 Highlights & Features

- ⚡ **Real-Time Live Scores**: Live WebSocket updates via Socket.IO for scores, match minutes, goals, cards, and substitutions with animated score transitions.
- 📱 **Multi-Platform & Responsive**: Seamless experience on Mobile (Bottom Navigation), Tablet (Navigation Rail), and Desktop/Web (Sidebar + Multi-Column Dashboard).
- 🌐 **Arabic (RTL) & English (LTR)**: Complete dynamic localization with Arabic & English typography, date formatting, and room synchronization (`live_matches_ar` / `live_matches_en`).
- 🎨 **Material 3 Theme Engine**: Sleek sports styling supporting Dark Mode, Light Mode, and System Theme.
- 🏟️ **Comprehensive Match Center**: Live score header, Overview, Events Timeline, Statistics Comparison Bars, Match Metadata (Referees, Broadcasters, Stadium), and News.
- 📊 **League Standings**: Live league tables with UEFA Champions League, Europa League, and Relegation color indicators.
- 🔄 **Transfer Market**: Live transfer tracker with player details, fees, and club movements.
- 🎥 **Video Feed**: Highlights and goal clips filterable by championship.
- 👤 **Profiles**: Stadium, Referee, and Commentator profile centers.
- ⭐ **Local Favorites**: Fast access to favorited teams, competitions, and matches.
- 🛠️ **System Diagnostics**: Built-in API health check, ping latency test, and server metrics viewer.
- 🔒 **Zero Firebase / Zero Supabase**: Strictly powered by the custom 154score API and local `shared_preferences`.

---

## 🏗️ Architecture

The codebase adheres strictly to **Clean Architecture & Flutter MVVM Standard**:

```text
lib/
├── app/                   # Router (GoRouter), Theme, App Scaffold, Root App
├── core/                  # Constants, Network (Dio ApiClient, ApiResult), WebSocket, Storage, Utils, Widgets
└── features/              # Feature-first modules (data, domain, presentation)
    ├── home/
    ├── matches/
    ├── match_details/
    ├── standings/
    ├── transfers/
    ├── videos/
    ├── profiles/
    ├── favorites/
    ├── settings/
    └── search/
```

For detailed diagrams and patterns, see [docs/architecture.md](docs/architecture.md).

---

## 🔌 API & WebSocket Endpoints

- **REST Base URL**: `https://moohamed154-154score-api.hf.space`
- **WebSocket URL**: `https://moohamed154-154score-api.hf.space` (Socket.IO)

Full specifications are documented in [docs/api.md](docs/api.md) and [docs/websocket.md](docs/websocket.md).

---

## 🚀 Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the Application
```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

### 3. Run Automated Tests
```bash
flutter test
```

---

## 📖 Documentation Sitemap
- [Architecture Blueprint](docs/architecture.md)
- [REST API Specifications](docs/api.md)
- [WebSocket & Real-Time Guide](docs/websocket.md)
- [Development & Build Commands](docs/development.md)
