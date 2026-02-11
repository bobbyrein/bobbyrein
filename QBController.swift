import SpriteKit

/// Deterministic QB movement controller with soft pocket penalties.
final class QBController {
    private weak var qbNode: SKSpriteNode?

    /// Desired movement vector (expected normalized by input system).
    var desiredMovement = CGVector.zero
    var maxSpeed: CGFloat = 220

    /// Pocket center and radii define a soft oval pressure region.
    var pocketCenter = CGPoint.zero
    var pocketRadiusX: CGFloat = 120
    var pocketRadiusY: CGFloat = 80

    private(set) var qbAccuracyMultiplier: CGFloat = 1.0
    private(set) var qbSackRiskMultiplier: CGFloat = 1.0

    init(qbNode: SKSpriteNode) {
        self.qbNode = qbNode
    }

    func resetMultipliers() {
        qbAccuracyMultiplier = 1
        qbSackRiskMultiplier = 1
    }

    func update(deltaTime: TimeInterval) {
        guard let qbNode else { return }

        let dt = CGFloat(max(0, deltaTime))
        qbNode.position.x += desiredMovement.dx * maxSpeed * dt
        qbNode.position.y += desiredMovement.dy * maxSpeed * dt

        updatePocketPenalty(for: qbNode.position)
    }

    private func updatePocketPenalty(for position: CGPoint) {
        let nx = (position.x - pocketCenter.x) / max(1, pocketRadiusX)
        let ny = (position.y - pocketCenter.y) / max(1, pocketRadiusY)
        let distance = sqrt(nx * nx + ny * ny)

        if distance <= 1 {
            qbAccuracyMultiplier = 1
            qbSackRiskMultiplier = 1
            return
        }

        let overflow = min(1.5, distance - 1)
        qbAccuracyMultiplier = max(0.55, 1 - overflow * 0.35)
        qbSackRiskMultiplier = min(2.2, 1 + overflow * 0.9)
    }
}
