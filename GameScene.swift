import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

final class GameScene: SKScene, SKPhysicsContactDelegate {
    enum PlayState {
        case pregame
        case snap
        case playActive
        case playOver
    }

    private enum TouchRole {
        case leftJoystick
        case rightSwipe
    }

    // MARK: Layers
    private let worldNode = SKNode()
    private let fieldLayer = SKNode()
    private let actorLayer = SKNode()
    private let uiLayer = SKNode()

    // MARK: Actors/Systems
    private let qbNode = SKSpriteNode(color: .systemBlue, size: CGSize(width: 30, height: 30))
    private var receivers: [Receiver] = []
    private var football: Football?

    private var qbController: QBController?
    private let defenseSystem = DefenseSystem(seed: 2025)
    private let driveManager = DriveManager()
    private let careerManager = CareerManager()
    private let progressionStore = ProgressionStore()

    // MARK: Input
    private var touchRoles: [ObjectIdentifier: TouchRole] = [:]
    private weak var leftTouch: UITouch?
    private weak var rightTouch: UITouch?

    private var leftJoystickOrigin = CGPoint.zero
    private var leftJoystickCurrent = CGPoint.zero
    private var rightSwipeStart = CGPoint.zero
    private var rightSwipeLast = CGPoint.zero
    private var rightSwipeStartTime: TimeInterval = 0

    private let joystickDeadzone: CGFloat = 16
    private let joystickMaxRadius: CGFloat = 72
    private let qbMaxSpeed: CGFloat = 220

    private(set) var throwPower: CGFloat = 0
    private(set) var releaseQuality: CGFloat = 0

    // MARK: UI
    private let stateLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let hudLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
    private let throwMeterLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")

    // MARK: State
    private(set) var playState: PlayState = .pregame {
        didSet {
            stateLabel.text = "State: \(playState)"
        }
    }

    private var lastUpdateTime: TimeInterval = 0

    override func didMove(to view: SKView) {
        configureScene()
        configurePhysics()
        buildHierarchy()
        buildField()
        buildHUD()
        spawnActors()
        configureSystems()
        transition(to: .pregame)
    }

    private func configureScene() {
        backgroundColor = SKColor(red: 0.06, green: 0.39, blue: 0.17, alpha: 1)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    private func configurePhysics() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        physicsWorld.speed = 1

        let border = SKPhysicsBody(edgeLoopFrom: CGRect(x: -size.width * 0.5,
                                                        y: -size.height * 0.5,
                                                        width: size.width,
                                                        height: size.height))
        border.categoryBitMask = PhysicsCategory.boundary
        border.contactTestBitMask = PhysicsCategory.football
        border.collisionBitMask = PhysicsCategory.football | PhysicsCategory.qb
        border.isDynamic = false
        physicsBody = border
    }

    private func buildHierarchy() {
        addChild(worldNode)
        worldNode.addChild(fieldLayer)
        worldNode.addChild(actorLayer)
        addChild(uiLayer)
    }

    private func buildField() {
        let fieldRect = SKShapeNode(rectOf: size)
        fieldRect.strokeColor = .white.withAlphaComponent(0.25)
        fieldRect.lineWidth = 4
        fieldLayer.addChild(fieldRect)

        let los = SKShapeNode(rectOf: CGSize(width: size.width * 0.9, height: 2))
        los.strokeColor = .yellow.withAlphaComponent(0.6)
        los.position = CGPoint(x: 0, y: -size.height * 0.02)
        los.name = "lineOfScrimmage"
        fieldLayer.addChild(los)
    }

    private func buildHUD() {
        stateLabel.fontSize = 18
        stateLabel.horizontalAlignmentMode = .left
        stateLabel.position = CGPoint(x: -size.width * 0.5 + 12, y: size.height * 0.5 - 28)
        stateLabel.zPosition = 200
        uiLayer.addChild(stateLabel)

        hudLabel.fontSize = 16
        hudLabel.horizontalAlignmentMode = .center
        hudLabel.position = CGPoint(x: 0, y: size.height * 0.5 - 28)
        hudLabel.zPosition = 200
        uiLayer.addChild(hudLabel)

        throwMeterLabel.fontSize = 16
        throwMeterLabel.horizontalAlignmentMode = .right
        throwMeterLabel.position = CGPoint(x: size.width * 0.5 - 12, y: size.height * 0.5 - 28)
        throwMeterLabel.zPosition = 200
        throwMeterLabel.text = "PWR 0.00 | QLT 0.00"
        uiLayer.addChild(throwMeterLabel)
    }

    private func spawnActors() {
        qbNode.name = "qb"
        qbNode.position = CGPoint(x: 0, y: -size.height * 0.20)
        qbNode.physicsBody = SKPhysicsBody(circleOfRadius: 15)
        qbNode.physicsBody?.isDynamic = true
        qbNode.physicsBody?.affectedByGravity = false
        qbNode.physicsBody?.categoryBitMask = PhysicsCategory.qb
        qbNode.physicsBody?.collisionBitMask = PhysicsCategory.boundary
        qbNode.physicsBody?.contactTestBitMask = PhysicsCategory.defender
        actorLayer.addChild(qbNode)

        receivers.removeAll()
        let routeOrder: [Receiver.RouteType] = [.slant, .out, .go]
        for i in 0..<3 {
            let receiver = Receiver()
            receiver.name = "receiver_\(i)"
            let x = -size.width * 0.25 + CGFloat(i) * (size.width * 0.25)
            let start = CGPoint(x: x, y: -size.height * 0.05)
            receiver.setupRoute(type: routeOrder[i], from: start)
            receiver.onCatch = { [weak self] _ in
                self?.handleCompletion(yards: 12)
            }
            actorLayer.addChild(receiver)
            receivers.append(receiver)
        }

        let rushers: [DefenseSystem.Rusher] = (0..<2).map { idx in
            let node = SKSpriteNode(color: .systemRed, size: CGSize(width: 24, height: 24))
            node.position = CGPoint(x: idx == 0 ? -70 : 70, y: 0)
            node.physicsBody = SKPhysicsBody(circleOfRadius: 12)
            node.physicsBody?.isDynamic = false
            node.physicsBody?.affectedByGravity = false
            node.physicsBody?.categoryBitMask = PhysicsCategory.defender
            node.physicsBody?.contactTestBitMask = PhysicsCategory.qb | PhysicsCategory.football
            actorLayer.addChild(node)
            let lane = CGVector(dx: idx == 0 ? 0.2 : -0.2, dy: -1)
            return DefenseSystem.Rusher(node: node, laneDirection: lane, speed: 85)
        }
        defenseSystem.configureRushers(rushers)

        let zones: [DefenseSystem.ZoneDefender] = [
            DefenseSystem.ZoneDefender(
                apex: CGPoint(x: -20, y: 40),
                left: CGPoint(x: -120, y: 150),
                right: CGPoint(x: 10, y: 145),
                interceptChance: 0.26,
                active: true
            ),
            DefenseSystem.ZoneDefender(
                apex: CGPoint(x: 20, y: 40),
                left: CGPoint(x: -10, y: 145),
                right: CGPoint(x: 120, y: 150),
                interceptChance: 0.26,
                active: true
            )
        ]
        defenseSystem.configureZones(zones)
    }

    private func configureSystems() {
        let controller = QBController(qbNode: qbNode)
        controller.maxSpeed = qbMaxSpeed
        controller.pocketCenter = CGPoint(x: 0, y: -size.height * 0.18)
        controller.pocketRadiusX = 120
        controller.pocketRadiusY = 70
        qbController = controller

        driveManager.startDrive()
        updateHUD()
        _ = careerManager.season.currentGameIndex
        _ = progressionStore.model.coins
    }

    private func transition(to newState: PlayState) {
        playState = newState
        switch newState {
        case .pregame:
            qbController?.resetMultipliers()
        case .snap:
            transition(to: .playActive)
        case .playActive:
            break
        case .playOver:
            cleanupBall()
        }
    }

    // MARK: Input
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let id = ObjectIdentifier(touch)
            let point = touch.location(in: self)

            if point.x <= 0, leftTouch == nil {
                leftTouch = touch
                touchRoles[id] = .leftJoystick
                leftJoystickOrigin = point
                leftJoystickCurrent = point
                continue
            }

            if point.x > 0, rightTouch == nil {
                rightTouch = touch
                touchRoles[id] = .rightSwipe
                rightSwipeStart = point
                rightSwipeLast = point
                rightSwipeStartTime = touch.timestamp
            }
        }

        if playState == .pregame {
            transition(to: .snap)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let id = ObjectIdentifier(touch)
            guard let role = touchRoles[id] else { continue }
            let point = touch.location(in: self)

            switch role {
            case .leftJoystick:
                leftJoystickCurrent = point
                qbController?.desiredMovement = normalizedJoystickVector(from: leftJoystickOrigin, to: point)
            case .rightSwipe:
                rightSwipeLast = point
                updateSwipePreview(start: rightSwipeStart, current: point, duration: touch.timestamp - rightSwipeStartTime)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleEndedTouches(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleEndedTouches(touches)
    }

    private func handleEndedTouches(_ touches: Set<UITouch>) {
        for touch in touches {
            let id = ObjectIdentifier(touch)
            guard let role = touchRoles[id] else { continue }

            switch role {
            case .leftJoystick:
                qbController?.desiredMovement = .zero
                leftTouch = nil
            case .rightSwipe:
                if playState == .playActive {
                    performThrow(from: rightSwipeStart, to: rightSwipeLast, endTime: touch.timestamp)
                }
                rightTouch = nil
                throwPower = 0
                releaseQuality = 0
            }

            touchRoles[id] = nil
        }
    }

    private func normalizedJoystickVector(from origin: CGPoint, to current: CGPoint) -> CGVector {
        var dx = current.x - origin.x
        var dy = current.y - origin.y

        let length = sqrt(dx * dx + dy * dy)
        if length < joystickDeadzone {
            return .zero
        }

        let clamped = min(length, joystickMaxRadius)
        dx = dx / max(0.001, length) * clamped
        dy = dy / max(0.001, length) * clamped
        return CGVector(dx: dx / joystickMaxRadius, dy: dy / joystickMaxRadius)
    }

    private func updateSwipePreview(start: CGPoint, current: CGPoint, duration: TimeInterval) {
        let vx = current.x - start.x
        let vy = current.y - start.y
        let swipeLength = sqrt(vx * vx + vy * vy)

        let speed = swipeLength / max(0.016, CGFloat(duration))
        throwPower = min(1, swipeLength / 220)
        releaseQuality = min(1, speed / 900)
        throwMeterLabel.text = String(format: "PWR %.2f | QLT %.2f", throwPower, releaseQuality)
    }

    private func performThrow(from start: CGPoint, to end: CGPoint, endTime: TimeInterval) {
        let vector = CGVector(dx: end.x - start.x, dy: end.y - start.y)
        let length = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
        guard length > 6 else { return }

        let normalized = CGVector(dx: vector.dx / length, dy: vector.dy / length)
        var velocityScale = 520 + throwPower * 520
        velocityScale *= qbController?.qbAccuracyMultiplier ?? 1

        let throwVelocity = CGVector(dx: normalized.dx * velocityScale,
                                     dy: normalized.dy * velocityScale)

        let qualityWindow = max(0.001, endTime - rightSwipeStartTime)
        releaseQuality = min(1, (length / CGFloat(qualityWindow)) / 900)

        let ball = football ?? Football()
        if ball.parent == nil { actorLayer.addChild(ball) }
        ball.throw(from: qbNode.position, velocity: throwVelocity, arc: 0.7)
        football = ball

        if let defenseEvent = defenseSystem.evaluatePass(from: qbNode.position, to: CGPoint(x: qbNode.position.x + throwVelocity.dx * 0.30,
                                                                                            y: qbNode.position.y + throwVelocity.dy * 0.30)) {
            handleDefenseEvent(defenseEvent)
        }

        if releaseQuality >= 0.9 {
            triggerPerfectReleaseFeedback()
        }
    }

    // MARK: Update Loop
    override func update(_ currentTime: TimeInterval) {
        let dt: TimeInterval
        if lastUpdateTime == 0 {
            dt = 0
        } else {
            dt = min(1.0 / 20.0, currentTime - lastUpdateTime)
        }
        lastUpdateTime = currentTime
        guard dt > 0 else { return }

        switch playState {
        case .pregame:
            break
        case .snap:
            break
        case .playActive:
            updatePlayActive(deltaTime: dt)
        case .playOver:
            break
        }

        updateHUD()
    }

    private func updatePlayActive(deltaTime: TimeInterval) {
        qbController?.update(deltaTime: deltaTime)

        for receiver in receivers {
            receiver.update(deltaTime: deltaTime)
        }

        if let ball = football {
            ball.update(deltaTime: deltaTime)
            for receiver in receivers where !receiver.hasCaughtBall {
                if receiver.attemptCatch(ball: ball) {
                    transition(to: .playOver)
                    return
                }
            }
        }

        let sackRisk = qbController?.qbSackRiskMultiplier ?? 1
        let events = defenseSystem.updateRush(qbPosition: qbNode.position,
                                              deltaTime: deltaTime,
                                              sackRiskMultiplier: sackRisk)
        for event in events {
            handleDefenseEvent(event)
        }
    }

    private func updateHUD() {
        let model = driveManager.hudModel()
        hudLabel.text = "\(model.downDistance) | \(model.field) | \(model.score) | \(model.clock)"
    }

    // MARK: Events
    private func handleDefenseEvent(_ event: DefenseSystem.Event) {
        switch event {
        case .sack:
            driveManager.endPlay(.sack(loss: 8))
            triggerSackFeedback()
            transition(to: .playOver)
        case .hurry:
            releaseQuality = max(0, releaseQuality - 0.15)
        case .interception:
            driveManager.endPlay(.interception)
            transition(to: .playOver)
        case .passDefended:
            driveManager.endPlay(.incomplete)
            transition(to: .playOver)
        }
    }

    private func handleCompletion(yards: Int) {
        driveManager.endPlay(.gain(yards: yards))
        transition(to: .playOver)
    }

    private func cleanupBall() {
        football?.removeFromParent()
        football = nil
    }

    // MARK: Feedback hooks
    private func triggerSackFeedback() {
        let shake = SKAction.sequence([
            .moveBy(x: -8, y: 0, duration: 0.03),
            .moveBy(x: 16, y: 0, duration: 0.06),
            .moveBy(x: -8, y: 0, duration: 0.03)
        ])
        run(shake)

        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        #endif
    }

    private func triggerPerfectReleaseFeedback() {
        let slow = SKAction.run { [weak self] in self?.speed = 0.7 }
        let wait = SKAction.wait(forDuration: 0.08)
        let restore = SKAction.run { [weak self] in self?.speed = 1.0 }
        run(.sequence([slow, wait, restore]))

        // Sound hook placeholder.
        // run(SKAction.playSoundFileNamed("perfect_release.wav", waitForCompletion: false))

        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }

    // MARK: Physics callback
    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if mask == (PhysicsCategory.football | PhysicsCategory.ground) {
            driveManager.endPlay(.incomplete)
            transition(to: .playOver)
        }
    }
}
