import Foundation

@Observable
public final class GameStats: @unchecked Sendable {
    public static let shared = GameStats()

    private let defaults = UserDefaults.standard

    public var gamesPlayed: Int {
        didSet { defaults.set(gamesPlayed, forKey: "stats_gamesPlayed") }
    }

    public var gamesWon: Int {
        didSet { defaults.set(gamesWon, forKey: "stats_gamesWon") }
    }

    public var bestTimeSeconds: Int? {
        didSet { defaults.set(bestTimeSeconds, forKey: "stats_bestTimeSeconds") }
    }

    public var bestScoreStandard: Int {
        didSet { defaults.set(bestScoreStandard, forKey: "stats_bestScoreStandard") }
    }

    public var bestScoreVegas: Int {
        didSet { defaults.set(bestScoreVegas, forKey: "stats_bestScoreVegas") }
    }

    public var currentStreak: Int {
        didSet { defaults.set(currentStreak, forKey: "stats_currentStreak") }
    }

    public var bestStreak: Int {
        didSet { defaults.set(bestStreak, forKey: "stats_bestStreak") }
    }

    public var winPercentage: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return (Double(gamesWon) / Double(gamesPlayed)) * 100.0
    }

    public init() {
        self.gamesPlayed = defaults.integer(forKey: "stats_gamesPlayed")
        self.gamesWon = defaults.integer(forKey: "stats_gamesWon")
        let bestTime = defaults.object(forKey: "stats_bestTimeSeconds") as? Int
        self.bestTimeSeconds = bestTime
        self.bestScoreStandard = defaults.integer(forKey: "stats_bestScoreStandard")
        self.bestScoreVegas = defaults.integer(forKey: "stats_bestScoreVegas")
        self.currentStreak = defaults.integer(forKey: "stats_currentStreak")
        self.bestStreak = defaults.integer(forKey: "stats_bestStreak")
    }

    public func recordGameFinished(won: Bool, score: Int, timeElapsed: Int, scoringMode: ScoringMode) {
        gamesPlayed += 1
        if won {
            gamesWon += 1
            currentStreak += 1
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
            if let best = bestTimeSeconds {
                if timeElapsed < best {
                    bestTimeSeconds = timeElapsed
                }
            } else {
                bestTimeSeconds = timeElapsed
            }
        } else {
            currentStreak = 0
        }

        switch scoringMode {
        case .standard:
            if score > bestScoreStandard {
                bestScoreStandard = score
            }
        case .vegas:
            if score > bestScoreVegas {
                bestScoreVegas = score
            }
        }
    }

    public func reset() {
        gamesPlayed = 0
        gamesWon = 0
        bestTimeSeconds = nil
        bestScoreStandard = 0
        bestScoreVegas = 0
        currentStreak = 0
        bestStreak = 0
    }
}
