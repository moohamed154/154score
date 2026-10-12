#if canImport(ActivityKit) && canImport(WidgetKit) && canImport(SwiftUI)
import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
public struct LiveMatchActivityWidget: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveMatchActivityAttributes.self) { context in
            // ── Lock Screen / Banner UI ──────────────────────────────────
            LockScreenLiveActivityView(state: context.state)
                .activityBackgroundTint(Color(red: 0.07, green: 0.09, blue: 0.12))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            // ── Dynamic Island (iPhone 14 Pro / 15 / 16) ─────────────────
            DynamicIsland {
                // Expanded Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        TeamLogoView(base64: context.state.homeLogoBase64, fallbackText: context.state.homeTeam)
                            .frame(width: 28, height: 28)
                        Text(context.state.homeTeam)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.leading, 8)
                }

                // Expanded Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 6) {
                        Text(context.state.awayTeam)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        TeamLogoView(base64: context.state.awayLogoBase64, fallbackText: context.state.awayTeam)
                            .frame(width: 28, height: 28)
                    }
                    .padding(.trailing, 8)
                }

                // Expanded Center
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        if !context.state.isLive && !context.state.isFinished {
                            Text(context.state.clock.isEmpty ? "--:--" : context.state.clock)
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text(context.state.isArabic ? "موعد الانطلاق" : "Kickoff")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Color(white: 0.65))
                        } else {
                            HStack(spacing: 8) {
                                Text(context.state.homeScore)
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                Text("-")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(context.state.awayScore)
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }

                        // Status / Clock Pill
                        StatusBadgeView(state: context.state)
                    }
                }

                // Expanded Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if !context.state.leagueName.isEmpty {
                            Text(context.state.leagueName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        Spacer()
                        if context.state.hasPenalties {
                            Text(context.state.isArabic ? "ركلات الترجيح: \(context.state.penaltyHome) - \(context.state.penaltyAway)" : "Penalties: \(context.state.penaltyHome) - \(context.state.penaltyAway)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(red: 0.96, green: 0.65, blue: 0.14))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                }
            } compactLeading: {
                // Compact Leading: Home Logo & Score
                HStack(spacing: 4) {
                    TeamLogoView(base64: context.state.homeLogoBase64, fallbackText: context.state.homeTeam)
                        .frame(width: 18, height: 18)
                    if context.state.isLive || context.state.isFinished {
                        Text(context.state.homeScore)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            } compactTrailing: {
                // Compact Trailing: Away Score / Kickoff Time & Logo
                HStack(spacing: 4) {
                    if !context.state.isLive && !context.state.isFinished {
                        Text(context.state.clock.isEmpty ? (context.state.isArabic ? "لم تبدأ" : "Upcoming") : context.state.clock)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.45))
                    } else {
                        Text(context.state.awayScore)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    TeamLogoView(base64: context.state.awayLogoBase64, fallbackText: context.state.awayTeam)
                        .frame(width: 18, height: 18)
                }
            } minimal: {
                // Minimal: Live Score or Kickoff Time
                if !context.state.isLive && !context.state.isFinished {
                    Text(context.state.clock.isEmpty ? "VS" : context.state.clock)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.45))
                } else {
                    Text("\(context.state.homeScore)-\(context.state.awayScore)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.45))
                }
            }
            .widgetURL(URL(string: "score154://match/\(context.state.matchId)"))
        }
    }
}

// ── App Logo Helper ───────────────────────────────────────────────────────────
@available(iOS 16.1, *)
private struct AppLogoHelper {
    static let image: UIImage? = {
        if let img = UIImage(named: "AppLogo") {
            return img
        }
        if let path = Bundle.main.path(forResource: "AppLogo", ofType: "png"),
           let img = UIImage(contentsOfFile: path) {
            return img
        }
        return nil
    }()
}

// ── Lock Screen Live Activity Main Card View ──────────────────────────────────
@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let state: LiveMatchActivityAttributes.ContentState

    var body: some View {
        Link(destination: URL(string: "score154://match/\(state.matchId)") ?? URL(string: "https://ysscores.com")!) {
            VStack(spacing: 10) {
                // Header: League badge and minute/status pill
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.45))
                        Text(state.leagueName.isEmpty ? (state.isArabic ? "154 سبورت" : "154 SCORE") : state.leagueName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(white: 0.85))
                            .lineLimit(1)
                    }

                    Spacer()

                    StatusBadgeView(state: state)
                }

                // Middle: Home Team | Center (Kickoff Time or Scores) | Away Team
                HStack(alignment: .center) {
                    // Home Team
                    HStack(spacing: 8) {
                        TeamLogoView(base64: state.homeLogoBase64, fallbackText: state.homeTeam)
                            .frame(width: 36, height: 36)
                        Text(state.homeTeam)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Center: Kickoff Time OR Live/Finished Score
                    VStack(spacing: 3) {
                        if !state.isLive && !state.isFinished {
                            // Match hasn't started yet: Show kickoff time prominently
                            Text(state.clock.isEmpty ? "--:--" : state.clock)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text(state.isArabic ? "موعد الانطلاق" : "Kickoff Time")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Color(white: 0.65))
                        } else {
                            HStack(spacing: 8) {
                                Text(state.homeScore)
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                Text("-")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color(white: 0.5))
                                Text(state.awayScore)
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }

                            if state.hasPenalties {
                                Text("(\(state.penaltyHome) - \(state.penaltyAway))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(red: 0.96, green: 0.65, blue: 0.14))
                            }
                        }
                    }
                    .padding(.horizontal, 8)

                    // Away Team
                    HStack(spacing: 8) {
                        Text(state.awayTeam)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                        TeamLogoView(base64: state.awayLogoBase64, fallbackText: state.awayTeam)
                            .frame(width: 36, height: 36)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // Footer: App branding with App Logo on bottom left, and subtle tap hint on right
                HStack {
                    HStack(spacing: 6) {
                        if let appLogo = AppLogoHelper.image {
                            Image(uiImage: appLogo)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 14, height: 14)
                                .clipShape(RoundedRectangle(cornerRadius: 3.5))
                        } else {
                            Circle()
                                .fill(state.isLive ? Color(red: 0.0, green: 0.85, blue: 0.45) : Color.gray)
                                .frame(width: 6, height: 6)
                        }

                        Text(state.isArabic ? (state.isLive ? "154Score • تحديث فوري مباشر" : "154Score مباشر") : (state.isLive ? "154Score • Live Updates" : "154Score Live"))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color(white: 0.65))
                    }
                    Spacer()
                    Text(state.isArabic ? "اضغط للتفاصيل ↗" : "Details ↗")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.45))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.08, green: 0.10, blue: 0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(white: 0.18), lineWidth: 0.8)
                    )
            )
        }
        .widgetURL(URL(string: "score154://match/\(state.matchId)"))
    }
}

// ── Reusable Status Badge Component ───────────────────────────────────────────
@available(iOS 16.1, *)
struct StatusBadgeView: View {
    let state: LiveMatchActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 4) {
            if state.isLive && !state.isHalftime && !state.isFinished {
                Circle()
                    .fill(Color(red: 0.95, green: 0.22, blue: 0.22))
                    .frame(width: 6, height: 6)
            }

            Text(badgeText)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(badgeColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(badgeBackgroundColor)
        .clipShape(Capsule())
    }

    private var badgeText: String {
        if state.isFinished {
            return state.isArabic ? "انتهت" : "FT"
        } else if state.isHalftime {
            return state.isArabic ? "استراحة" : "HT"
        } else if !state.minute.isEmpty {
            return "\(state.minute)'"
        } else {
            if state.isArabic {
                return state.status
            } else {
                switch state.status {
                case "مباشر": return "LIVE"
                case "لم تبدأ": return "Upcoming"
                case "تأجلت": return "Postponed"
                case "ألغيت": return "Cancelled"
                case "استراحة": return "HT"
                case "انتهت": return "FT"
                default:
                    if !state.statusCode.isEmpty {
                        return state.statusCode
                    }
                    return state.isLive ? "LIVE" : state.status
                }
            }
        }
    }

    private var badgeColor: Color {
        if state.isFinished {
            return Color(white: 0.7)
        } else if state.isHalftime {
            return Color(red: 0.96, green: 0.65, blue: 0.14)
        } else {
            return Color(red: 0.0, green: 0.92, blue: 0.5)
        }
    }

    private var badgeBackgroundColor: Color {
        if state.isFinished {
            return Color(white: 0.2)
        } else if state.isHalftime {
            return Color(red: 0.96, green: 0.65, blue: 0.14).opacity(0.18)
        } else {
            return Color(red: 0.0, green: 0.92, blue: 0.5).opacity(0.18)
        }
    }
}

// ── Reusable Team Logo Component ──────────────────────────────────────────────
@available(iOS 16.1, *)
struct TeamLogoView: View {
    let base64: String
    let fallbackText: String

    var body: some View {
        if !base64.isEmpty,
           let data = Data(base64Encoded: base64),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(Circle())
        } else {
            fallbackView
        }
    }

    private var fallbackView: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.15, green: 0.18, blue: 0.23))
            Text(String(fallbackText.prefix(1)))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
#endif
