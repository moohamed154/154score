# 154Score - Development & Build Guide

## Prerequisites
- Flutter SDK `^3.47.0` (Dart `^3.13.0`)
- Android Studio / Xcode (for mobile targets)
- Google Chrome / Edge (for web target)

---

## Getting Started

1. **Clone the repository & install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run on Chrome (Web)**:
   ```bash
   flutter run -d chrome
   ```

3. **Run on Android / iOS**:
   ```bash
   flutter run -d android
   flutter run -d ios
   ```

---

## Testing & Quality Assurance

1. **Run Unit and Widget Tests**:
   ```bash
   flutter test
   ```

2. **Run Linter Analysis**:
   ```bash
   flutter analyze
   ```

---

## Production Builds

- **Web**:
  ```bash
  flutter build web --release
  ```
- **Android APK**:
  ```bash
  flutter build apk --release
  ```
- **Android AppBundle**:
  ```bash
  flutter build appbundle --release
  ```
- **iOS**:
  ```bash
  flutter build ios --release
  ```
