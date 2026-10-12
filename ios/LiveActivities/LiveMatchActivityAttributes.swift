#if canImport(ActivityKit)
@preconcurrency import ActivityKit
import Foundation

@available(iOS 16.1, *)
public struct LiveMatchActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var matchId: String
        public var homeTeam: String
        public var awayTeam: String
        public var homeLogo: String
        public var awayLogo: String
        public var homeLogoBase64: String
        public var awayLogoBase64: String
        public var homeScore: String
        public var awayScore: String
        public var status: String
        public var statusCode: String
        public var period: String
        public var minute: String
        public var clock: String
        public var leagueName: String
        public var leagueLogo: String
        public var penaltyHome: String
        public var penaltyAway: String
        public var hasPenalties: Bool
        public var isLive: Bool
        public var isFinished: Bool
        public var isHalftime: Bool
        public var isExtraTime: Bool
        public var isArabic: Bool

        public init(
            matchId: String,
            homeTeam: String,
            awayTeam: String,
            homeLogo: String,
            awayLogo: String,
            homeLogoBase64: String = "",
            awayLogoBase64: String = "",
            homeScore: String,
            awayScore: String,
            status: String,
            statusCode: String,
            period: String,
            minute: String,
            clock: String,
            leagueName: String,
            leagueLogo: String,
            penaltyHome: String = "",
            penaltyAway: String = "",
            hasPenalties: Bool = false,
            isLive: Bool = true,
            isFinished: Bool = false,
            isHalftime: Bool = false,
            isExtraTime: Bool = false,
            isArabic: Bool = true
        ) {
            self.matchId = matchId
            self.homeTeam = homeTeam
            self.awayTeam = awayTeam
            self.homeLogo = homeLogo
            self.awayLogo = awayLogo
            self.homeLogoBase64 = homeLogoBase64
            self.awayLogoBase64 = awayLogoBase64
            self.homeScore = homeScore
            self.awayScore = awayScore
            self.status = status
            self.statusCode = statusCode
            self.period = period
            self.minute = minute
            self.clock = clock
            self.leagueName = leagueName
            self.leagueLogo = leagueLogo
            self.penaltyHome = penaltyHome
            self.penaltyAway = penaltyAway
            self.hasPenalties = hasPenalties
            self.isLive = isLive
            self.isFinished = isFinished
            self.isHalftime = isHalftime
            self.isExtraTime = isExtraTime
            self.isArabic = isArabic
        }
    }

    public var matchId: String
    public var homeTeam: String
    public var awayTeam: String

    public init(matchId: String, homeTeam: String, awayTeam: String) {
        self.matchId = matchId
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
    }
}
#endif
