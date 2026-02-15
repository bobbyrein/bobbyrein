import SpriteKit

final class Football: SKSpriteNode {
    private(set) var isThrown = false
    private(set) var isIntercepted = false

    var velocityVector = CGVector.zero
    var arcFactor: CGFloat = 0

    /// Tunables for readability.
    var gravity: CGFloat = -520
    var drag: CGFloat = 0.985
    var arcDecay: CGFloat = 1.6

    convenience init() {
        self.init(texture: nil, color: .brown, size: CGSize(width: 18, height: 12))
    }

    override init(texture: SKTexture?, color: SKColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        name = "football"
        zPosition = 20

        physicsBody = SKPhysicsBody(circleOfRadius: max(size.width, size.height) * 0.5)
        physicsBody?.affectedByGravity = false
        physicsBody?.isDynamic = true
        physicsBody?.allowsRotation = false
        physicsBody?.categoryBitMask = PhysicsCategory.football
        physicsBody?.collisionBitMask = PhysicsCategory.boundary | PhysicsCategory.ground
        physicsBody?.contactTestBitMask = PhysicsCategory.receiver | PhysicsCategory.defender | PhysicsCategory.ground | PhysicsCategory.endzone
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func throw(from origin: CGPoint, velocity: CGVector, arc: CGFloat) {
        position = origin
        velocityVector = velocity
        arcFactor = max(0, arc)
        isThrown = true
        isIntercepted = false
    }

    func intercept(at position: CGPoint) {
        self.position = position
        velocityVector = .zero
        arcFactor = 0
        isIntercepted = true
        isThrown = false
    }

    func update(deltaTime: TimeInterval) {
        guard isThrown, !isIntercepted else { return }
        let dt = CGFloat(max(0, deltaTime))

        velocityVector.dy += gravity * dt
        velocityVector.dx *= pow(drag, dt * 60)
        velocityVector.dy *= pow(drag, dt * 60)

        position.x += velocityVector.dx * dt
        position.y += velocityVector.dy * dt

        arcFactor = max(0, arcFactor - arcDecay * dt)
    }
}
