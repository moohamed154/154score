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
                        TeamLogoView(url: context.state.homeLogo, fallbackText: context.state.homeTeam)
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
                        TeamLogoView(url: context.state.awayLogo, fallbackText: context.state.awayTeam)
                            .frame(width: 28, height: 28)
                    }
                    .padding(.trailing, 8)
                }

                // Expanded Center
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
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
                            Text("ركلات الترجيح: \(context.state.penaltyHome) - \(context.state.penaltyAway)")
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
                    TeamLogoView(url: context.state.homeLogo, fallbackText: context.state.homeTeam)
                        .frame(width: 18, height: 18)
                    Text(context.state.homeScore)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            } compactTrailing: {
                // Compact Trailing: Away Score & Logo
                HStack(spacing: 4) {
                    Text(context.state.awayScore)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    TeamLogoView(url: context.state.awayLogo, fallbackText: context.state.awayTeam)
                        .frame(width: 18, height: 18)
                }
            } minimal: {
                // Minimal: Live Score or Crest
                Text("\(context.state.homeScore)-\(context.state.awayScore)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.45))
            }
        }
    }
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
                        Text(state.leagueName.isEmpty ? "154 SCORE" : state.leagueName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(white: 0.85))
                            .lineLimit(1)
                    }

                    Spacer()

                    StatusBadgeView(state: state)
                }

                // Middle: Home Team | Scores | Away Team
                HStack(alignment: .center) {
                    // Home Team
                    HStack(spacing: 8) {
                        TeamLogoView(url: state.homeLogo, fallbackText: state.homeTeam)
                            .frame(width: 36, height: 36)
                        Text(state.homeTeam)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Scores
                    VStack(spacing: 2) {
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
                    .padding(.horizontal, 12)

                    // Away Team
                    HStack(spacing: 8) {
                        Text(state.awayTeam)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                        TeamLogoView(url: state.awayLogo, fallbackText: state.awayTeam)
                            .frame(width: 36, height: 36)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // Footer: App branding and subtle tap hint
                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(state.isLive ? Color(red: 0.0, green: 0.85, blue: 0.45) : Color.gray)
                            .frame(width: 5, height: 5)
                        Text(state.isLive ? "تحديث فوري مباشر" : "154Score Live")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color(white: 0.6))
                    }
                    Spacer()
                    Text("اضغط للتفاصيل ↗")
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
            return "انتهت"
        } else if state.isHalftime {
            return "استراحة"
        } else if !state.minute.isEmpty {
            return "\(state.minute)'"
        } else {
            return state.status
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
    let url: String
    let fallbackText: String

    var body: some View {
        if let validUrl = URL(string: url), !url.isEmpty {
            AsyncImage(url: validUrl) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                case .failure(_), .empty:
                    fallbackView
                @unknown default:
                    fallbackView
                }
            }
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
