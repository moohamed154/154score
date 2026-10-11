#if canImport(ActivityKit)
@preconcurrency import ActivityKit
import Flutter
import Foundation

@available(iOS 16.1, *)
@MainActor
public class LiveActivityManager {
    public static let shared = LiveActivityManager()

    private var methodChannel: FlutterMethodChannel?

    private init() {}

    public func setMethodChannel(_ channel: FlutterMethodChannel) {
        self.methodChannel = channel
    }

    public func areActivitiesEnabled() -> Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }

    public func startLiveActivity(data: [String: Any], result: @escaping FlutterResult) {
        guard areActivitiesEnabled() else {
            result(FlutterError(code: "ACTIVITIES_DISABLED", message: "Live Activities are disabled on this device", details: nil))
            return
        }

        guard let matchId = data["matchId"] as? String, !matchId.isEmpty else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "matchId is required", details: nil))
            return
        }

        let homeTeam = data["homeTeam"] as? String ?? "Home"
        let awayTeam = data["awayTeam"] as? String ?? "Away"

        // Prevent duplicate activities for the same match
        for existing in Activity<LiveMatchActivityAttributes>.activities {
            if existing.attributes.matchId == matchId {
                Task { @MainActor in
                    if #available(iOS 16.2, *) {
                        await existing.end(nil, dismissalPolicy: .immediate)
                    } else {
                        await existing.end(using: nil, dismissalPolicy: .immediate)
                    }
                }
            }
        }

        let attributes = LiveMatchActivityAttributes(
            matchId: matchId,
            homeTeam: homeTeam,
            awayTeam: awayTeam
        )

        let initialContentState = buildContentState(from: data)

        do {
            let activity: Activity<LiveMatchActivityAttributes>
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: initialContentState, staleDate: nil)
                activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: .token
                )
            } else {
                activity = try Activity.request(
                    attributes: attributes,
                    contentState: initialContentState,
                    pushType: .token
                )
            }

            let activityId = activity.id
            let pushTokenUpdates = activity.pushTokenUpdates

            // Listen for push token updates & rotation
            Task { @MainActor [weak self] in
                for await pushTokenData in pushTokenUpdates {
                    let tokenString = pushTokenData.map { String(format: "%02.2hhx", $0) }.joined()
                    print("[LiveActivityManager] Push token received for activity \(activityId): \(tokenString)")
                    self?.methodChannel?.invokeMethod("onPushTokenRotated", arguments: [
                        "activityId": activityId,
                        "matchId": matchId,
                        "pushToken": tokenString
                    ])
                }
            }

            var initialTokenString = ""
            if let tokenData = activity.pushToken {
                initialTokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
            }

            result([
                "activityId": activity.id,
                "matchId": matchId,
                "pushToken": initialTokenString
            ])
        } catch {
            print("[LiveActivityManager] Failed to start live activity: \(error.localizedDescription)")
            result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
        }
    }

    public func updateLiveActivity(data: [String: Any], result: @escaping FlutterResult) {
        guard let matchId = data["matchId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "matchId is required", details: nil))
            return
        }

        guard let activity = Activity<LiveMatchActivityAttributes>.activities.first(where: { $0.attributes.matchId == matchId }) else {
            result(false)
            return
        }

        let updatedState = buildContentState(from: data)

        Task { @MainActor in
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: updatedState, staleDate: nil)
                await activity.update(content)
            } else {
                await activity.update(using: updatedState)
            }
            result(true)
        }
    }

    public func stopLiveActivity(data: [String: Any], result: @escaping FlutterResult) {
        let matchId = data["matchId"] as? String
        let activityId = data["activityId"] as? String

        var targetActivities: [Activity<LiveMatchActivityAttributes>] = []

        if let matchId = matchId, !matchId.isEmpty {
            targetActivities = Activity<LiveMatchActivityAttributes>.activities.filter { $0.attributes.matchId == matchId }
        } else if let activityId = activityId, !activityId.isEmpty {
            targetActivities = Activity<LiveMatchActivityAttributes>.activities.filter { $0.id == activityId }
        }

        guard !targetActivities.isEmpty else {
            result(true)
            return
        }

        Task { @MainActor in
            for act in targetActivities {
                if #available(iOS 16.2, *) {
                    await act.end(nil, dismissalPolicy: .immediate)
                } else {
                    await act.end(using: nil, dismissalPolicy: .immediate)
                }
            }
            result(true)
        }
    }

    public func getActiveActivities(result: @escaping FlutterResult) {
        let activeMatchIds = Activity<LiveMatchActivityAttributes>.activities.map { $0.attributes.matchId }
        result(activeMatchIds)
    }

    private func buildContentState(from data: [String: Any]) -> LiveMatchActivityAttributes.ContentState {
        return LiveMatchActivityAttributes.ContentState(
            matchId: data["matchId"] as? String ?? "",
            homeTeam: data["homeTeam"] as? String ?? "Home",
            awayTeam: data["awayTeam"] as? String ?? "Away",
            homeLogo: data["homeLogo"] as? String ?? "",
            awayLogo: data["awayLogo"] as? String ?? "",
            homeScore: "\(data["homeScore"] ?? "0")",
            awayScore: "\(data["awayScore"] ?? "0")",
            status: data["status"] as? String ?? "مباشر",
            statusCode: data["statusCode"] as? String ?? "LIVE",
            period: data["period"] as? String ?? "live",
            minute: data["minute"] as? String ?? "",
            clock: data["clock"] as? String ?? "",
            leagueName: data["leagueName"] as? String ?? "",
            leagueLogo: data["leagueLogo"] as? String ?? "",
            penaltyHome: "\(data["penaltyHome"] ?? "")",
            penaltyAway: "\(data["penaltyAway"] ?? "")",
            hasPenalties: data["hasPenalties"] as? Bool ?? false,
            isLive: data["isLive"] as? Bool ?? true,
            isFinished: data["isFinished"] as? Bool ?? false,
            isHalftime: data["isHalftime"] as? Bool ?? false,
            isExtraTime: data["isExtraTime"] as? Bool ?? false
        )
    }
}
#endif
