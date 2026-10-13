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
        let b64 = "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"
        if let data = Data(base64Encoded: b64), let img = UIImage(data: data) {
            return img
        }
        return UIImage(named: "AppLogo")
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

                if state.startTimestamp > 0 {
                    let startDate = Date(timeIntervalSince1970: state.startTimestamp)
                    Text(timerInterval: startDate...startDate.addingTimeInterval(55 * 60), countsDown: false)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(badgeColor)
                        .multilineTextAlignment(.center)
                } else {
                    Text(badgeText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(badgeColor)
                }
            } else {
                Text(badgeText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(badgeColor)
            }
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
