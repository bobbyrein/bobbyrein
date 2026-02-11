import SpriteKit

final class DefenseSystem {
    enum Event {
        case sack
        case hurry
        case interception
        case passDefended
    }

    struct Rusher {
        var node: SKSpriteNode
        var laneDirection: CGVector
        var speed: CGFloat
    }

    struct ZoneDefender {
        var apex: CGPoint
        var left: CGPoint
        var right: CGPoint
        var interceptChance: CGFloat
        var active: Bool
    }

    private(set) var rushers: [Rusher] = []
    private(set) var zones: [ZoneDefender] = []
    private var rng: SeededRNG

    var sackDistance: CGFloat = 26
    var hurryDistance: CGFloat = 60

    init(seed: UInt64 = 42) {
        self.rng = SeededRNG(seed: seed)
    }

    func configureRushers(_ rushers: [Rusher]) {
        self.rushers = rushers
    }

    func configureZones(_ zones: [ZoneDefender]) {
        self.zones = zones
    }

    func updateRush(qbPosition: CGPoint, deltaTime: TimeInterval, sackRiskMultiplier: CGFloat) -> [Event] {
        var events: [Event] = []
        let dt = CGFloat(max(0, deltaTime))

        for index in rushers.indices {
            var rusher = rushers[index]
            let toQB = CGVector(dx: qbPosition.x - rusher.node.position.x,
                                dy: qbPosition.y - rusher.node.position.y)
            let len = max(0.001, sqrt(toQB.dx * toQB.dx + toQB.dy * toQB.dy))
            let chaseDir = CGVector(dx: toQB.dx / len, dy: toQB.dy / len)

            // Blend lane vector with QB chase for readable pressure lanes.
            let blended = CGVector(dx: chaseDir.dx * 0.7 + rusher.laneDirection.dx * 0.3,
                                   dy: chaseDir.dy * 0.7 + rusher.laneDirection.dy * 0.3)
            let blendedLen = max(0.001, sqrt(blended.dx * blended.dx + blended.dy * blended.dy))
            let finalDir = CGVector(dx: blended.dx / blendedLen, dy: blended.dy / blendedLen)

            rusher.node.position.x += finalDir.dx * rusher.speed * dt
            rusher.node.position.y += finalDir.dy * rusher.speed * dt
            rushers[index] = rusher

            if len <= sackDistance * sackRiskMultiplier {
                events.append(.sack)
            } else if len <= hurryDistance {
                events.append(.hurry)
            }
        }

        return events
    }

    func evaluatePass(from start: CGPoint, to end: CGPoint) -> Event? {
        for zone in zones where zone.active {
            if segmentIntersectsTriangle(start: start, end: end, a: zone.apex, b: zone.left, c: zone.right) {
                if rng.nextUnit() <= zone.interceptChance {
                    return .interception
                }
                return .passDefended
            }
        }
        return nil
    }

    private func segmentIntersectsTriangle(start: CGPoint, end: CGPoint, a: CGPoint, b: CGPoint, c: CGPoint) -> Bool {
        // Simple deterministic sampling for arcade readability.
        let samples = 10
        for i in 0...samples {
            let t = CGFloat(i) / CGFloat(samples)
            let p = CGPoint(x: start.x + (end.x - start.x) * t,
                            y: start.y + (end.y - start.y) * t)
            if isPointInTriangle(p, a: a, b: b, c: c) {
                return true
            }
        }
        return false
    }

    private func isPointInTriangle(_ p: CGPoint, a: CGPoint, b: CGPoint, c: CGPoint) -> Bool {
        let area = triangleArea(a, b, c)
        let area1 = triangleArea(p, b, c)
        let area2 = triangleArea(a, p, c)
        let area3 = triangleArea(a, b, p)
        return abs(area - (area1 + area2 + area3)) < 0.5
    }

    private func triangleArea(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
        abs((p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y)) * 0.5)
    }
}
