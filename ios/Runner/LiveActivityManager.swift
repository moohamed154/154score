#if canImport(ActivityKit)
@preconcurrency import ActivityKit
import Flutter
import Foundation
import UIKit

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
            result(FlutterError(code: "ACTIVITIES_DISABLED", message: "الأنشطة الحالية معطلة. يرجى تفعيل (الأنشطة الحالية - Live Activities) لتطبيق 154 SCORE من إعدادات الهاتف", details: nil))
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

        Task { @MainActor in
            var mutableData = data
            let homeLogoUrl = data["homeLogo"] as? String ?? ""
            let awayLogoUrl = data["awayLogo"] as? String ?? ""

            // Parallel async prefetch with generous timeout
            async let homeFetch = self.fetchThumbnailBase64(from: homeLogoUrl)
            async let awayFetch = self.fetchThumbnailBase64(from: awayLogoUrl)

            var hBase64 = mutableData["homeLogoBase64"] as? String ?? ""
            var aBase64 = mutableData["awayLogoBase64"] as? String ?? ""

            if hBase64.isEmpty && !homeLogoUrl.isEmpty {
                hBase64 = await homeFetch
            }
            if aBase64.isEmpty && !awayLogoUrl.isEmpty {
                aBase64 = await awayFetch
            }

            // Enforce ActivityKit 4KB budget: allow up to 2800 characters total for images
            if (hBase64.count + aBase64.count) > 2800 {
                if aBase64.count > 1400 { aBase64 = "" }
                if hBase64.count > 1400 { hBase64 = "" }
            }

            mutableData["homeLogoBase64"] = hBase64
            mutableData["awayLogoBase64"] = aBase64

            let initialContentState = self.buildContentState(from: mutableData)

            do {
                let activity: Activity<LiveMatchActivityAttributes>
                if #available(iOS 16.2, *) {
                    let content = ActivityContent(state: initialContentState, staleDate: nil)
                    do {
                        activity = try Activity.request(
                            attributes: attributes,
                            content: content,
                            pushType: .token
                        )
                    } catch {
                        print("[LiveActivityManager] Push token request failed (\(error.localizedDescription)), trying pushType: nil with content")
                        do {
                            activity = try Activity.request(
                                attributes: attributes,
                                content: content,
                                pushType: nil
                            )
                        } catch {
                            // Secondary fallback: strip base64 to guarantee 0% failure from payload size
                            print("[LiveActivityManager] Payload size error, stripping base64 images and retrying...")
                            var strippedData = mutableData
                            strippedData["homeLogoBase64"] = ""
                            strippedData["awayLogoBase64"] = ""
                            let strippedState = self.buildContentState(from: strippedData)
                            let strippedContent = ActivityContent(state: strippedState, staleDate: nil)
                            activity = try Activity.request(
                                attributes: attributes,
                                content: strippedContent,
                                pushType: nil
                            )
                        }
                    }
                } else {
                    do {
                        activity = try Activity.request(
                            attributes: attributes,
                            contentState: initialContentState,
                            pushType: .token
                        )
                    } catch {
                        print("[LiveActivityManager] Push token request failed (\(error.localizedDescription)), falling back to pushType: nil")
                        activity = try Activity.request(
                            attributes: attributes,
                            contentState: initialContentState,
                            pushType: nil
                        )
                    }
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

        Task { @MainActor in
            var mutableData = data
            let homeLogoUrl = data["homeLogo"] as? String ?? ""
            let awayLogoUrl = data["awayLogo"] as? String ?? ""

            async let homeFetch = self.fetchThumbnailBase64(from: homeLogoUrl)
            async let awayFetch = self.fetchThumbnailBase64(from: awayLogoUrl)

            var hBase64 = mutableData["homeLogoBase64"] as? String ?? ""
            var aBase64 = mutableData["awayLogoBase64"] as? String ?? ""

            if hBase64.isEmpty && !homeLogoUrl.isEmpty {
                hBase64 = await homeFetch
            }
            if aBase64.isEmpty && !awayLogoUrl.isEmpty {
                aBase64 = await awayFetch
            }

            if (hBase64.count + aBase64.count) > 2800 {
                if aBase64.count > 1400 { aBase64 = "" }
                if hBase64.count > 1400 { hBase64 = "" }
            }

            mutableData["homeLogoBase64"] = hBase64
            mutableData["awayLogoBase64"] = aBase64

            let updatedState = self.buildContentState(from: mutableData)
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

        let targetActivities: [Activity<LiveMatchActivityAttributes>]
        if let matchId = matchId, !matchId.isEmpty {
            targetActivities = Activity<LiveMatchActivityAttributes>.activities.filter { $0.attributes.matchId == matchId }
        } else if let activityId = activityId, !activityId.isEmpty {
            targetActivities = Activity<LiveMatchActivityAttributes>.activities.filter { $0.id == activityId }
        } else {
            targetActivities = Activity<LiveMatchActivityAttributes>.activities
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

    private func fetchThumbnailBase64(from urlString: String) async -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), !trimmed.isEmpty else { return "" }
        do {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 8.0
            config.timeoutIntervalForResource = 12.0
            let session = URLSession(configuration: config)
            let (data, _) = try await session.data(from: url)
            guard let image = UIImage(data: data) else { return "" }
            
            // Render compact 24x24 thumbnail with widget background fill to preserve circular contrast
            let targetSize = CGSize(width: 24, height: 24)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let resized = renderer.image { _ in
                UIColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1.0).setFill()
                UIRectFill(CGRect(origin: .zero, size: targetSize))
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
            
            // Compress with JPEG (0.40 quality produces ~550-650 bytes, ~750-850 base64 chars)
            guard let jpgData = resized.jpegData(compressionQuality: 0.40) else { return "" }
            let base64 = jpgData.base64EncodedString()
            if base64.count > 1100 {
                guard let lowerJpg = resized.jpegData(compressionQuality: 0.20) else { return "" }
                return lowerJpg.base64EncodedString()
            }
            return base64
        } catch {
            print("[LiveActivityManager] Failed to fetch thumbnail for \(urlString): \(error.localizedDescription)")
            return ""
        }
    }

    private func buildContentState(from data: [String: Any]) -> LiveMatchActivityAttributes.ContentState {
        let isArabic = data["isArabic"] as? Bool ?? true
        return LiveMatchActivityAttributes.ContentState(
            matchId: data["matchId"] as? String ?? "",
            homeTeam: data["homeTeam"] as? String ?? (isArabic ? "المستضيف" : "Home"),
            awayTeam: data["awayTeam"] as? String ?? (isArabic ? "الضيف" : "Away"),
            homeLogo: data["homeLogo"] as? String ?? "",
            awayLogo: data["awayLogo"] as? String ?? "",
            homeLogoBase64: data["homeLogoBase64"] as? String ?? "",
            awayLogoBase64: data["awayLogoBase64"] as? String ?? "",
            homeScore: "\(data["homeScore"] ?? "0")",
            awayScore: "\(data["awayScore"] ?? "0")",
            status: data["status"] as? String ?? (isArabic ? "مباشر" : "LIVE"),
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
            isExtraTime: data["isExtraTime"] as? Bool ?? false,
            isArabic: isArabic
        )
    }
}
#endif
