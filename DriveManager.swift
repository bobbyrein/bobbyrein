import Foundation

final class DriveManager {
    enum PlayResult {
        case gain(yards: Int)
        case incomplete
        case touchdown
        case interception
        case sack(loss: Int)
        case punt
        case fieldGoal(good: Bool)
        case turnoverOnDowns
    }

    struct HUDModel {
        let downDistance: String
        let score: String
        let clock: String
        let field: String
    }

    private(set) var down: Int = 1
    private(set) var yardsToGo: Int = 10
    private(set) var fieldPosition: Int = 25 // own 25
    private(set) var quarterSecondsRemaining: Int = 300
    private(set) var homeScore: Int = 0
    private(set) var awayScore: Int = 0

    func startDrive() {
        down = 1
        yardsToGo = 10
        fieldPosition = 25
    }

    func startPlay() {
        // Simplified arcade rule: no pre-play penalties/time runoff.
    }

    func endPlay(_ result: PlayResult) {
        switch result {
        case let .gain(yards):
            applyYardage(yards)
        case .incomplete:
            advanceDownOrTurnover()
        case .touchdown:
            homeScore += 7
            startDrive()
        case .interception:
            swapPossessionArcadeReset()
        case let .sack(loss):
            applyYardage(-abs(loss))
        case .punt:
            swapPossessionArcadeReset()
        case let .fieldGoal(good):
            if good {
                homeScore += 3
                startDrive()
            } else {
                swapPossessionArcadeReset()
            }
        case .turnoverOnDowns:
            swapPossessionArcadeReset()
        }
    }

    func advanceClock(seconds: Int) {
        quarterSecondsRemaining = max(0, quarterSecondsRemaining - max(0, seconds))
    }

    func hudModel() -> HUDModel {
        HUDModel(
            downDistance: "\(down)&\(yardsToGo)",
            score: "H \(homeScore) - A \(awayScore)",
            clock: formatClock(seconds: quarterSecondsRemaining),
            field: "\(fieldPosition) yd"
        )
    }

    private func applyYardage(_ yards: Int) {
        let previousLine = fieldPosition
        fieldPosition = max(1, min(99, fieldPosition + yards))

        if fieldPosition >= 100 {
            homeScore += 7
            startDrive()
            return
        }

        let gained = fieldPosition - previousLine
        yardsToGo -= gained

        if yardsToGo <= 0 {
            down = 1
            yardsToGo = 10
        } else {
            advanceDownOrTurnover()
        }
    }

    private func advanceDownOrTurnover() {
        if down >= 4 {
            endPlay(.turnoverOnDowns)
        } else {
            down += 1
        }
    }

    private func swapPossessionArcadeReset() {
        // Simplification: possession swap just resets your next drive.
        startDrive()
    }

    private func formatClock(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
