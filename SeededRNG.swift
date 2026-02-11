import Foundation

/// Lightweight deterministic RNG for consistent replays/sim outcomes.
struct SeededRNG {
    private(set) var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0xA5A5_A5A5_A5A5_A5A5 : seed
    }

    mutating func nextUInt64() -> UInt64 {
        // LCG constants from Numerical Recipes style family.
        state = 6364136223846793005 &* state &+ 1442695040888963407
        return state
    }

    mutating func nextUnit() -> CGFloat {
        let value = nextUInt64() >> 11
        let maxValue = UInt64.max >> 11
        return CGFloat(Double(value) / Double(maxValue))
    }
}
