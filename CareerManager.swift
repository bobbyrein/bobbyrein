import Foundation

final class CareerManager {
    struct Stats: Codable {
        var completions = 0
        var attempts = 0
        var tds = 0
        var ints = 0
        var rushYards = 0
        var sacks = 0
    }

    struct GameRecord: Codable {
        var drivesPlayed: Int
        var stats: Stats
        var coinsAwarded: Int
    }

    struct Season: Codable {
        var yearLabel: String
        var totalGames: Int
        var currentGameIndex: Int
        var drivesPerGame: Int
        var records: [GameRecord]
        var draftStock: Int
    }

    private let storageKey = "career.manager.senior.year"
    private let defaults: UserDefaults

    private(set) var season: Season

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(Season.self, from: data) {
            season = decoded
        } else {
            season = Season(yearLabel: "Senior Year", totalGames: 10, currentGameIndex: 0, drivesPerGame: 8, records: [], draftStock: 50)
        }
    }

    func startNewSeason() {
        season = Season(yearLabel: "Senior Year", totalGames: 10, currentGameIndex: 0, drivesPerGame: 8, records: [], draftStock: 50)
        save()
    }

    func completeGame(drivesPlayed: Int, stats: Stats) -> (coins: Int, upgradeChoices: Int) {
        guard season.currentGameIndex < season.totalGames else {
            return (0, 0)
        }

        let coins = max(25, stats.tds * 40 + stats.completions * 3 - stats.ints * 10)
        season.records.append(GameRecord(drivesPlayed: drivesPlayed, stats: stats, coinsAwarded: coins))
        season.currentGameIndex += 1
        season.draftStock = computeDraftStock()
        save()
        return (coins, 1)
    }

    func computeDraftStock() -> Int {
        let totals = season.records.reduce(into: Stats()) { partial, record in
            partial.completions += record.stats.completions
            partial.attempts += record.stats.attempts
            partial.tds += record.stats.tds
            partial.ints += record.stats.ints
            partial.rushYards += record.stats.rushYards
            partial.sacks += record.stats.sacks
        }

        guard totals.attempts > 0 else { return 50 }

        let completionPct = Double(totals.completions) / Double(totals.attempts)
        var stock = 40.0
        stock += completionPct * 30
        stock += Double(totals.tds) * 2
        stock -= Double(totals.ints) * 3
        stock += Double(totals.rushYards) * 0.04
        stock -= Double(totals.sacks) * 0.8
        return max(0, min(100, Int(stock.rounded())))
    }

    func save() {
        if let data = try? JSONEncoder().encode(season) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
