# 154Score - API Integration Documentation

## Base URL
```text
https://moohamed154-154score-api.hf.space
```

---

## REST Endpoints Overview

| Endpoint | Method | Query Parameters | Description |
| :--- | :--- | :--- | :--- |
| `/api/matches` | `GET` | `lang` (ar/en), `date` (YYYY-MM-DD), `utc-offset` | Matches grouped by league |
| `/api/matches/:id/events` | `GET` | `lang` | Match timeline events (goals, cards, subs, VAR) |
| `/api/matches/:id/stats` | `GET` | `lang` | Possession, shots, shots on target, corners, etc. |
| `/api/matches/:id/details` | `GET` | `lang`, `utc-offset` | Venue, referee, commentator, channel |
| `/api/matches/:id/news` | `GET` | `lang` | Match-specific news feed |
| `/api/transfers` | `GET` | `lang` | Football transfer market movements |
| `/api/videos` | `GET` | `champ_id` (all/id), `lang` | Video highlights and championship filters |
| `/api/videos/:id` | `GET` | `lang` | Video details and related clips |
| `/api/leagues/:id/standings` | `GET` | `lang` | League standings table |
| `/api/stadium/:id/:slug` | `GET` | `lang` | Stadium profile metadata |
| `/api/referee/:id/:slug` | `GET` | `lang` | Referee profile metadata |
| `/api/commentator/:id/:slug` | `GET` | `lang` | Commentator profile metadata |
| `/api/config?type=health` | `GET` | - | Server health status |
| `/ping` | `GET` | - | Instant server awake check |
| `/api/metrics` | `GET` | - | Internal server performance metrics |

---

## Safe Error Handling Pattern

The application wraps all network operations in a sealed `ApiResult<T>`:

```dart
sealed class ApiResult<T> { ... }
class ApiSuccess<T> extends ApiResult<T> { final T data; }
class ApiFailure<T> extends ApiResult<T> { final Failure failure; }
```

- Network timeouts and connection drops map to `NetworkFailure`.
- HTTP 4xx / 5xx errors map to `ServerFailure(statusCode)`.
- Malformed payloads fallback to safe default DTOs with zero crashes.
