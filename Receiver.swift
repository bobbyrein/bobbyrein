import SpriteKit

final class Receiver: SKSpriteNode {
    enum RouteType: CaseIterable {
        case slant
        case out
        case go
        case curl
        case drag
    }

    var routeType: RouteType = .slant
    var waypoints: [CGPoint] = []
    var currentWaypointIndex = 0
    var moveSpeed: CGFloat = 110
    var catchRadius: CGFloat = 36
    var isCatchable = true
    var hasCaughtBall = false

    var onCatch: ((Receiver) -> Void)?

    convenience init(color: SKColor = .systemYellow) {
        self.init(texture: nil, color: color, size: CGSize(width: 24, height: 24))
    }

    override init(texture: SKTexture?, color: SKColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        physicsBody = SKPhysicsBody(circleOfRadius: size.width * 0.5)
        physicsBody?.affectedByGravity = false
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = PhysicsCategory.receiver
        physicsBody?.contactTestBitMask = PhysicsCategory.football
        physicsBody?.collisionBitMask = PhysicsCategory.none
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setupRoute(type: RouteType, from origin: CGPoint) {
        routeType = type
        currentWaypointIndex = 0
        hasCaughtBall = false
        isCatchable = true
        waypoints = makeWaypoints(type: type, origin: origin)
        position = origin
    }

    func update(deltaTime: TimeInterval) {
        guard currentWaypointIndex < waypoints.count else { return }

        let target = waypoints[currentWaypointIndex]
        let toTarget = CGVector(dx: target.x - position.x, dy: target.y - position.y)
        let distance = sqrt(toTarget.dx * toTarget.dx + toTarget.dy * toTarget.dy)

        if distance < 6 {
            currentWaypointIndex += 1
            return
        }

        let dir = CGVector(dx: toTarget.dx / max(0.001, distance),
                           dy: toTarget.dy / max(0.001, distance))
        let step = CGFloat(deltaTime) * moveSpeed
        position.x += dir.dx * step
        position.y += dir.dy * step
    }

    @discardableResult
    func attemptCatch(ball: Football) -> Bool {
        guard isCatchable, !hasCaughtBall, ball.isThrown else { return false }
        let dx = ball.position.x - position.x
        let dy = ball.position.y - position.y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance <= catchRadius else { return false }

        hasCaughtBall = true
        isCatchable = false
        ball.intercept(at: position)
        onCatch?(self)
        return true
    }

    private func makeWaypoints(type: RouteType, origin: CGPoint) -> [CGPoint] {
        switch type {
        case .slant:
            return [
                CGPoint(x: origin.x + 45, y: origin.y + 90),
                CGPoint(x: origin.x + 90, y: origin.y + 150)
            ]
        case .out:
            return [
                CGPoint(x: origin.x, y: origin.y + 110),
                CGPoint(x: origin.x + 110, y: origin.y + 110)
            ]
        case .go:
            return [CGPoint(x: origin.x, y: origin.y + 240)]
        case .curl:
            return [
                CGPoint(x: origin.x, y: origin.y + 140),
                CGPoint(x: origin.x - 35, y: origin.y + 100)
            ]
        case .drag:
            return [CGPoint(x: origin.x + 160, y: origin.y + 20)]
        }
    }
}
