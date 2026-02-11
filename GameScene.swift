import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Play State

    enum PlayState {
        case pregame
        case snap
        case playActive
        case playOver
    }

    // MARK: - Node Hierarchy

    private let worldNode = SKNode()
    private let fieldLayer = SKNode()
    private let actorLayer = SKNode()
    private let uiLayer = SKNode()

    private let qbNode = SKSpriteNode(color: .systemBlue, size: CGSize(width: 32, height: 32))
    private var receiverNodes: [SKSpriteNode] = []
    private var defenderNodes: [SKSpriteNode] = []

    private let stateLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    // MARK: - Gameplay

    private(set) var playState: PlayState = .pregame {
        didSet {
            stateLabel.text = "State: \(String(describing: playState))"
        }
    }

    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        configureScene()
        configurePhysics()
        buildNodeHierarchy()
        buildField()
        buildUI()
        spawnInitialActors()
        transition(to: .pregame)
    }

    // MARK: - Configuration

    private func configureScene() {
        backgroundColor = SKColor(red: 0.07, green: 0.40, blue: 0.16, alpha: 1.0)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    private func configurePhysics() {
        physicsWorld.gravity = .zero
        physicsWorld.speed = 1.0
        physicsWorld.contactDelegate = self

        let fieldBody = SKPhysicsBody(edgeLoopFrom: CGRect(
            x: -size.width * 0.5,
            y: -size.height * 0.5,
            width: size.width,
            height: size.height
        ))
        fieldBody.isDynamic = false
        fieldBody.friction = 0
        physicsBody = fieldBody
    }

    private func buildNodeHierarchy() {
        addChild(worldNode)
        worldNode.addChild(fieldLayer)
        worldNode.addChild(actorLayer)
        addChild(uiLayer)
    }

    private func buildField() {
        let fieldRect = SKShapeNode(rectOf: size)
        fieldRect.strokeColor = .white.withAlphaComponent(0.25)
        fieldRect.lineWidth = 4
        fieldRect.zPosition = 0
        fieldLayer.addChild(fieldRect)

        let lineSpacing: CGFloat = 80
        var x: CGFloat = -size.width * 0.5
        while x <= size.width * 0.5 {
            let hash = SKShapeNode(rectOf: CGSize(width: 2, height: size.height))
            hash.position = CGPoint(x: x, y: 0)
            hash.strokeColor = .white.withAlphaComponent(0.1)
            hash.lineWidth = 2
            fieldLayer.addChild(hash)
            x += lineSpacing
        }
    }

    private func buildUI() {
        stateLabel.fontSize = 20
        stateLabel.horizontalAlignmentMode = .left
        stateLabel.verticalAlignmentMode = .center
        stateLabel.position = CGPoint(x: -size.width * 0.5 + 16, y: size.height * 0.5 - 32)
        stateLabel.zPosition = 100
        uiLayer.addChild(stateLabel)
    }

    private func spawnInitialActors() {
        spawnQB()
        spawnReceivers(count: 3)
        spawnDefenders(count: 3)
    }

    // MARK: - Spawning (placeholders ready for extension)

    private func spawnQB() {
        qbNode.name = "qb"
        qbNode.position = CGPoint(x: 0, y: -size.height * 0.2)
        qbNode.zPosition = 10
        actorLayer.addChild(qbNode)
    }

    private func spawnReceivers(count: Int) {
        receiverNodes.forEach { $0.removeFromParent() }
        receiverNodes.removeAll()

        for index in 0..<count {
            let receiver = SKSpriteNode(color: .systemYellow, size: CGSize(width: 24, height: 24))
            receiver.name = "receiver_\(index)"
            let spacing = size.width / CGFloat(max(count, 1) + 1)
            receiver.position = CGPoint(
                x: -size.width * 0.5 + spacing * CGFloat(index + 1),
                y: size.height * 0.08
            )
            receiver.zPosition = 10
            actorLayer.addChild(receiver)
            receiverNodes.append(receiver)
        }
    }

    private func spawnDefenders(count: Int) {
        defenderNodes.forEach { $0.removeFromParent() }
        defenderNodes.removeAll()

        for index in 0..<count {
            let defender = SKSpriteNode(color: .systemRed, size: CGSize(width: 24, height: 24))
            defender.name = "defender_\(index)"
            let spacing = size.width / CGFloat(max(count, 1) + 1)
            defender.position = CGPoint(
                x: -size.width * 0.5 + spacing * CGFloat(index + 1),
                y: -size.height * 0.02
            )
            defender.zPosition = 10
            actorLayer.addChild(defender)
            defenderNodes.append(defender)
        }
    }

    // MARK: - State Machine

    private func transition(to newState: PlayState) {
        playState = newState

        switch playState {
        case .pregame:
            preparePregame()
        case .snap:
            beginSnap()
        case .playActive:
            beginActivePlay()
        case .playOver:
            finishPlay()
        }
    }

    private func preparePregame() {
        // Placeholder: reset drive data, set formations, show prompt
    }

    private func beginSnap() {
        // Placeholder: snap animation/timing
        transition(to: .playActive)
    }

    private func beginActivePlay() {
        // Placeholder: enable control systems and defender AI
    }

    private func finishPlay() {
        // Placeholder: evaluate result, show summary, trigger next play
    }

    // MARK: - Input Placeholders

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard playState == .pregame else { return }
        transition(to: .snap)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Placeholder: left-zone joystick + right-zone swipe handling
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Placeholder: finalize swipe throw / reset joystick
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        let deltaTime: TimeInterval
        if lastUpdateTime == 0 {
            deltaTime = 0
        } else {
            deltaTime = currentTime - lastUpdateTime
        }
        lastUpdateTime = currentTime

        guard deltaTime > 0 else { return }

        switch playState {
        case .pregame:
            updatePregame(deltaTime: deltaTime)
        case .snap:
            updateSnap(deltaTime: deltaTime)
        case .playActive:
            updatePlayActive(deltaTime: deltaTime)
        case .playOver:
            updatePlayOver(deltaTime: deltaTime)
        }
    }

    private func updatePregame(deltaTime: TimeInterval) {
        _ = deltaTime
        // Placeholder: camera settle, UI pulse, etc.
    }

    private func updateSnap(deltaTime: TimeInterval) {
        _ = deltaTime
        // Placeholder: short snap timing window
    }

    private func updatePlayActive(deltaTime: TimeInterval) {
        updateReceivers(deltaTime: deltaTime)
        updateDefenders(deltaTime: deltaTime)

        // Placeholder play-over condition for scaffold purposes
        if qbNode.position.y > size.height * 0.45 {
            transition(to: .playOver)
        }
    }

    private func updatePlayOver(deltaTime: TimeInterval) {
        _ = deltaTime
        // Placeholder: post-play animations/results countdown
    }

    private func updateReceivers(deltaTime: TimeInterval) {
        let speed = CGFloat(45.0) * CGFloat(deltaTime)
        for receiver in receiverNodes {
            receiver.position.y += speed
        }
    }

    private func updateDefenders(deltaTime: TimeInterval) {
        let chaseSpeed = CGFloat(30.0) * CGFloat(deltaTime)
        for defender in defenderNodes {
            let toQB = CGVector(dx: qbNode.position.x - defender.position.x,
                                dy: qbNode.position.y - defender.position.y)
            let length = max(0.001, sqrt(toQB.dx * toQB.dx + toQB.dy * toQB.dy))
            let step = CGVector(dx: toQB.dx / length * chaseSpeed,
                                dy: toQB.dy / length * chaseSpeed)
            defender.position.x += step.dx
            defender.position.y += step.dy
        }
    }

    // MARK: - Physics Contacts

    func didBegin(_ contact: SKPhysicsContact) {
        // Placeholder: catch, sack, LOS crossing, interception, bounds checks
        _ = contact
    }
}
