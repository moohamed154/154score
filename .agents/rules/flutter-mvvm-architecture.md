# 📱 Master Rules for Flutter MVVM Architecture & Clean Development

These rules establish the architectural, performance, and code quality standards for building modern, scalable, and testable Flutter applications using the **Model-View-ViewModel (MVVM)** pattern.

---

## 1. Core Architectural Layers & Separation of Concerns

```
┌────────────────────────────────────────────────────────┐
│                        VIEW                            │
│  (Widgets, Screens, Pages, Dialogs, UI Components)     │
└───────────────────────────▲────────────────────────────┘
                            │ Dispatches User Actions
             State Updates  │ & Listens to State
                            │
┌───────────────────────────▼────────────────────────────┐
│                     VIEWMODEL                          │
│  (Cubit / Bloc / ChangeNotifier / StateNotifier)       │
│  - Holds immutable UI State                            │
│  - Pure business logic & orchestration                 │
│  - Zero `BuildContext` or widget imports               │
└───────────────────────────▲────────────────────────────┘
                            │ Calls Methods
             Data / Domain  │ & Returns Entities/Results
                            │
┌───────────────────────────▼────────────────────────────┐
│                        MODEL                           │
│  ├── Repositories (Contracts & Implementations)        │
│  ├── Data Sources (Remote API Dio / Local Hive/Cache)  │
│  └── Entities & DTOs (Immutable Models, JSON Parsers)  │
└────────────────────────────────────────────────────────┘
```

---

## 2. Directory Structure (Feature-First MVVM Standard)

```text
lib/
├── core/
│   ├── constants/          # AppColors, AppStrings, AppAssets, ApiEndpoints
│   ├── di/                 # Dependency injection setup (get_it / injectable)
│   ├── errors/             # Custom Exceptions & Failures (ServerFailure, CacheFailure)
│   ├── network/            # Dio client, Interceptors, BaseHttpClient, ApiResult
│   ├── routes/             # AppRouter (go_router / modular navigation)
│   ├── theme/              # AppTheme, Typography, ColorSchemes, Dimension tokens
│   └── utils/              # Extensions, Formatters, Validators, Helpers
│
├── features/               # Self-contained feature modules
│   ├── auth/
│   │   ├── data/           # AuthRepositoryImpl, AuthRemoteDataSource, AuthDto
│   │   ├── domain/         # AuthRepository (Interface), UserEntity
│   │   └── presentation/
│   │       ├── viewmodels/ # auth_cubit.dart, auth_state.dart
│   │       ├── views/      # login_view.dart, register_view.dart
│   │       └── widgets/    # auth_form.dart, social_auth_button.dart
│   │
│   └── dashboard/
│       ├── data/
│       ├── domain/
│       └── presentation/
│           ├── viewmodels/
│           ├── views/
│           └── widgets/
│
└── main.dart               # App entry point, bootstrap & initialization
```

---

## 3. Layer Specifications & Responsibilities

### 3.1 Model Layer (Data & Domain)
1. **Repository Pattern**:
   - Define abstract repository contracts in the domain layer:
     ```dart
     abstract class AuthRepository {
       Future<ApiResult<UserEntity>> login({required String email, required String password});
       Future<void> logout();
     }
     ```
   - Concrete repository implementation coordinates remote and local caching:
     ```dart
     class AuthRepositoryImpl implements AuthRepository {
       final AuthRemoteDataSource _remoteDataSource;
       final AuthLocalDataSource _localDataSource;
       AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);
       ...
     }
     ```
2. **Immutability & Serialization**:
   - Models must be immutable using `Equatable` or `@freezed`.
   - Implement `fromJson` / `toJson` for DTOs; never manipulate raw Maps inside ViewModels.

### 3.2 ViewModel Layer (State & Logic)
1. **Strict Decoupling**:
   - **NEVER import `package:flutter/material.dart` or pass `BuildContext` into a ViewModel.**
   - All navigation, dialogs, and snackbars must be triggered in the View using state listeners or a navigation service.
2. **Immutable UI State**:
   - Define a single sealed state class or an immutable state object:
     ```dart
     enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

     class AuthState extends Equatable {
       final AuthStatus status;
       final UserEntity? user;
       final String? errorMessage;

       const AuthState({
         this.status = AuthStatus.initial,
         this.user,
         this.errorMessage,
       });

       AuthState copyWith({
         AuthStatus? status,
         UserEntity? user,
         String? errorMessage,
       }) {
         return AuthState(
           status: status ?? this.status,
           user: user ?? this.user,
           errorMessage: errorMessage ?? this.errorMessage,
         );
       }

       @override
       List<Object?> get props => [status, user, errorMessage];
     }
     ```
3. **Pure Business Logic**:
   - ViewModels only interact with Repositories and update state.

### 3.3 View Layer (Pure UI)
1. **Stateless Views**:
   - Views should be `StatelessWidget` whenever possible.
   - Use `StatefulWidget` ONLY for local animation controllers, text editing controllers, or scroll controller lifecycles.
2. **Scoped Rebuilds**:
   - Use targeted listeners (`BlocBuilder(buildWhen: ...)`, `Selector`, or `Consumer`) so only the required subtree rebuilds.
   - Separate UI presentation (`BlocBuilder`) from one-off side effects like navigation/snackbars (`BlocListener`).

---

## 4. Dependency Injection & Service Locator

1. Use **`get_it`** (or `injectable`) to register singletons and factories in `core/di/injection_container.dart`:
   ```dart
   final sl = GetIt.instance;

   Future<void> initDependencies() async {
     // Core / Network
     sl.registerLazySingleton<Dio>(() => createDioClient());

     // Data sources
     sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));

     // Repositories
     sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()));

     // ViewModels (Factory = new instance per screen or singleton for global state)
     sl.registerFactory<AuthCubit>(() => AuthCubit(sl()));
   }
   ```
2. Initialize DI in `main.dart` before `runApp()`:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await initDependencies();
     runApp(const MyApp());
   }
   ```

---

## 5. Performance & 60/120 FPS Rendering Standards

1. **`const` Constructors**:
   - Mark every immutable widget with `const`.
   - Use lint rule `prefer_const_constructors: true` in `analysis_options.yaml`.
2. **List & Scrolling Performance**:
   - Always use `ListView.builder` or `CustomScrollView` with `SliverList.builder`.
   - Provide `itemExtent` or `prototypeItem` when item dimensions are fixed.
   - Use `addAutomaticKeepAlives: false` and `addRepaintBoundaries: true` for long lists.
3. **Image Optimization**:
   - Use `cached_network_image` with explicit `memCacheWidth` and `memCacheHeight` to prevent high-res bitmap memory bloat.
   - Pre-cache critical assets in `didChangeDependencies`: `precacheImage(...)`.
4. **Repaint Boundaries & Layer Compositing**:
   - Wrap frequently animating widgets, charts, and multi-page items (`PageView` day/feed items) in `RepaintBoundary` so the GPU can translate layers without per-frame subtree repainting.
5. **Gesture & Page Transition Isolation (60/120 FPS Standard)**:
   - Never dispatch asynchronous BLoC events or state updates inside continuous touch gesture callbacks (`onPageChanged`, `onPanUpdate`).
   - Defer state mutations until gestures settle completely (e.g. `ScrollEndNotification`) to guarantee buttery smooth transitions without frame drops or scroll locking collisions.
6. **Controller & Subscription Disposal**:
   - Always call `.dispose()` on `TextEditingController`, `AnimationController`, `ScrollController`, `PageController`, and cancel `StreamSubscription` in `dispose()`.

---

## 6. Error Handling & Result Pattern

1. **Standard `ApiResult` / `Either` Wrapper**:
   - Never let unhandled network exceptions crash the ViewModel:
   ```dart
   sealed class ApiResult<T> {
     const ApiResult();
   }
   class Success<T> extends ApiResult<T> {
     final T data;
     const Success(this.data);
   }
   class Failure<T> extends ApiResult<T> {
     final String message;
     final int? statusCode;
     const Failure(this.message, {this.statusCode});
   }
   ```
2. **Temporal Resource 404 Disambiguation**:
   - When querying temporal collections (e.g., date-based schedules like `/matches?date=...`), HTTP 404 or backend messages like `"لا توجد مباريات"` / `"no matches"` MUST be interpreted as an empty dataset success (`Success([])`), NOT as a service failure.
3. **Centralized Dio Interceptors**:
   - Add Logging, JWT Bearer Token Injection, and Auto-Refresh interceptors in `core/network/`.

---

## 7. Testing Standards

1. **ViewModel Unit Tests**:
   - Test state transitions and business logic using `bloc_test` or `mocktail`:
   ```dart
   blocTest<AuthCubit, AuthState>(
     'emits [loading, authenticated] when login succeeds',
     build: () {
       when(() => mockAuthRepo.login(email: 'a@b.com', password: '123'))
           .thenAnswer((_) async => const Success(mockUser));
       return AuthCubit(mockAuthRepo);
     },
     act: (cubit) => cubit.login('a@b.com', '123'),
     expect: () => [
       const AuthState(status: AuthStatus.loading),
       const AuthState(status: AuthStatus.authenticated, user: mockUser),
     ],
   );
   ```
2. **Repository & DataSource Tests**:
   - Mock HTTP requests using `mocktail` or `http_mock_adapter`.
3. **Widget Tests**:
   - Test pure UI rendering across states (`Initial`, `Loading`, `Error`, `Success`).

---

## 8. Flutter Code Quality & Analysis Rules

Ensure `analysis_options.yaml` includes strict linting rules:
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - prefer_const_declarations
    - avoid_unnecessary_containers
    - avoid_print
    - unawaited_futures
    - cancel_subscriptions
    - close_sinks
    - use_super_parameters
```
