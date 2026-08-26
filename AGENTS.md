# Flutter MVVM Architecture & Engineering Standards

This repository adheres strictly to the **Flutter MVVM (Model-View-ViewModel) Architecture & Clean Code Standard**.

For full detailed blueprints, diagrams, and code patterns, see:
👉 [`.agents/rules/flutter-mvvm-architecture.md`](.agents/rules/flutter-mvvm-architecture.md)

---

## 1. Strict Layer Separation of Concerns

* **Model Layer (Data & Domain)**:
  * **Repositories**: Abstract contracts (`AuthRepository`) in domain and concrete implementations (`AuthRepositoryImpl`) in data. Single source of truth.
  * **Data Sources**: Remote APIs (`Dio` client with centralized interceptors) and local persistence (`Hive`, `Isar`, `FlutterSecureStorage`).
  * **Models & DTOs**: Immutable entities using `Equatable` or `@freezed` with clean `fromJson` / `toJson` mappers.

* **ViewModel Layer (State & Business Logic)**:
  * Pure state management using **`Cubit` / `Bloc`** (or `ChangeNotifier`).
  * Holds immutable UI state classes (`AuthState` with `status`, `data`, `errorMessage`, `copyWith`).
  * **STRICT RULE**: **Zero `BuildContext` or Flutter UI widget imports in ViewModels**. All navigation and UI dialogs/snackbars are handled in the View layer.

* **View Layer (Pure UI)**:
  * Pure `StatelessWidget` UI components (use `StatefulWidget` only when local animation/scroll controller lifecycles require it).
  * Listens to ViewModel state via targeted `BlocBuilder` / `Selector` / `Consumer`.
  * Handles one-off side effects (navigation, dialogs, snackbars) inside `BlocListener`.

---

## 2. Dependency Injection & Service Locator (`get_it`)

* Centralized registration in `core/di/injection_container.dart`:
  * **Singletons**: Core utilities (`Dio`, `LocalCache`, `Repositories`).
  * **Factories**: ViewModels / Cubits (`registerFactory` creates a fresh instance per screen lifecycle).
* Initialized in `main.dart` before `runApp()`.

---

## 3. Performance & 60/120 FPS Rendering Standards

* **Mandatory `const` Constructors**: Mark every immutable widget with `const` to eliminate redundant rebuilds.
* **Scoped Rebuilds**: Wrap only the specific child subtree that depends on state changes (`buildWhen` / `Selector`), never the whole screen.
* **Optimized Scrolling**: Use `ListView.builder` / `CustomScrollView` with `itemExtent` or `prototypeItem`.
* **Memory & Image Caching**: Always use `cached_network_image` with explicit `memCacheWidth` and `memCacheHeight` to prevent bitmap memory bloat.
* **Repaint Boundaries**: Wrap animations, loaders, and custom painters with `RepaintBoundary`.
* **Resource Disposal**: Always call `.dispose()` on `TextEditingController`, `AnimationController`, `ScrollController`, `PageController`, and cancel all `StreamSubscription` instances.

---

## 4. Error Handling & Result Pattern

* Use a sealed `ApiResult<T>` wrapper (or `Either<Failure, T>`) so unhandled exceptions never crash ViewModels:
  ```dart
  sealed class ApiResult<T> { const ApiResult(); }
  class Success<T> extends ApiResult<T> { final T data; const Success(this.data); }
  class Failure<T> extends ApiResult<T> { final String message; final int? statusCode; const Failure(this.message, {this.statusCode}); }
  ```
* Centralized `Dio` interceptors for authentication tokens, error mapping, and logging.

---

## 5. Feature-First Folder Structure Template

```text
lib/
├── core/                   # Shared tokens, DI, network, routes, theme, utils
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
