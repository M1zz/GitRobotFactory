import SpriteKit

class TitleScene: SKScene {
    private var devTapCount = 0
    private var robotIcon: SKNode?
    private var devModeIndicator: SKLabelNode?

    override func didMove(to view: SKView) {
        backgroundColor = C.bg
        setupScene()
    }
    
    private func setupScene() {
        let mid = CGPoint(x: size.width/2, y: size.height/2)

        // Subtle grid background
        for x in stride(from: 0, to: size.width, by: 48) {
            let line = SKShapeNode(rectOf: CGSize(width: 0.5, height: size.height))
            line.fillColor = C.gridLine
            line.strokeColor = .clear
            line.position = CGPoint(x: x, y: size.height/2)
            addChild(line)
        }
        for y in stride(from: 0, to: size.height, by: 48) {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 0.5))
            line.fillColor = C.gridLine
            line.strokeColor = .clear
            line.position = CGPoint(x: size.width/2, y: y)
            addChild(line)
        }

        // Background card
        let card = SKShapeNode(rectOf: CGSize(width: 540, height: 380), cornerRadius: 20)
        card.fillColor = C.panelBg
        card.strokeColor = C.border
        card.lineWidth = 1.5
        card.position = CGPoint(x: mid.x, y: mid.y - 10)
        addChild(card)

        // Robot icon (clickable for dev mode)
        let robot = SKLabelNode(text: "🤖")
        robot.fontSize = 72
        robot.position = CGPoint(x: mid.x, y: mid.y + 130)
        robot.name = "devRobot"
        robot.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: -10, duration: 2.2),
            .moveBy(x: 0, y: 10, duration: 2.2)
        ])))
        addChild(robot)
        robotIcon = robot

        // Title
        let title = SKLabelNode(text: "Git Robot Factory")
        title.fontName = "Helvetica-Bold"
        title.fontSize = 40
        title.fontColor = C.green
        title.position = CGPoint(x: mid.x, y: mid.y + 55)
        addChild(title)

        // Subtitle
        let subtitle = SKLabelNode(text: "로봇을 조립하며 배우는 Git Flow")
        subtitle.fontName = "Helvetica"
        subtitle.fontSize = 15
        subtitle.fontColor = C.textDim
        subtitle.position = CGPoint(x: mid.x, y: mid.y + 20)
        addChild(subtitle)

        // Divider
        let divider = SKShapeNode(rectOf: CGSize(width: 400, height: 1))
        divider.fillColor = C.border
        divider.strokeColor = .clear
        divider.position = CGPoint(x: mid.x, y: mid.y - 10)
        addChild(divider)

        // Start button
        let btn = ButtonNode(text: "🏭  공장 가동 시작", width: 220, height: 46, color: C.green, fontSize: 16)
        btn.position = CGPoint(x: mid.x, y: mid.y - 50)
        btn.action = { [weak self] in self?.goToChapters() }
        addChild(btn)

        // Stats (if any)
        let data = GameData.shared
        if !data.collectedRobots.isEmpty {
            let stats = makeLabel("⭐ \(data.totalStars)  |  🤖 \(data.collectedRobots.count)대 수집", size: 12, color: C.textDim)
            stats.position = CGPoint(x: mid.x, y: mid.y - 108)
            addChild(stats)
        }

        // Git concepts strip at bottom
        let concepts = ["commit", "branch", "merge", "release", "hotfix"]
        for (i, c) in concepts.enumerated() {
            let label = makeLabel(c, size: 10, color: C.textFaint, mono: true)
            label.position = CGPoint(x: CGFloat(i - 2) * 110 + mid.x, y: 28)
            addChild(label)
        }

        if GameData.shared.devMode {
            showDevModeIndicator()
        }
    }

    private func showDevModeIndicator() {
        devModeIndicator?.removeFromParent()

        let indicator = SKLabelNode(text: "👨‍💻 DEVELOPER MODE")
        indicator.fontName = "Menlo-Bold"
        indicator.fontSize = 12
        indicator.fontColor = C.yellow
        indicator.position = CGPoint(x: size.width / 2, y: size.height - 80)
        indicator.zPosition = 20

        // Pulse animation
        indicator.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.5, duration: 0.6),
            .fadeAlpha(to: 1.0, duration: 0.6)
        ])))

        addChild(indicator)
        devModeIndicator = indicator
    }
    
    private func goToChapters() {
        let scene = ChapterScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: .push(with: .left, duration: 0.4))
    }
    
    override func mouseUp(with event: NSEvent) {
        let loc = event.location(in: self)
        let nodes = self.nodes(at: loc)

        // Check for dev robot tap
        for node in nodes {
            if node.name == "devRobot" || node == robotIcon {
                devTapCount += 1

                // Flash the robot
                robotIcon?.run(.sequence([
                    .scale(to: 1.1, duration: 0.1),
                    .scale(to: 1.0, duration: 0.1)
                ]))

                if devTapCount >= 5 {
                    toggleDevMode()
                    devTapCount = 0
                }
                return
            }

            if let btn = node as? ButtonNode ?? node.parent as? ButtonNode {
                btn.action?()
                return
            }
        }
    }

    private func toggleDevMode() {
        GameData.shared.devMode.toggle()

        if GameData.shared.devMode {
            showDevModeIndicator()

            // Success feedback
            let toast = SKLabelNode(text: "🔓 개발자 모드 활성화!")
            toast.fontName = "Helvetica-Bold"
            toast.fontSize = 16
            toast.fontColor = C.green
            toast.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
            toast.zPosition = 100
            addChild(toast)

            toast.run(.sequence([
                .group([
                    .moveBy(x: 0, y: 30, duration: 0.3),
                    .fadeIn(withDuration: 0.3)
                ]),
                .wait(forDuration: 1.5),
                .group([
                    .moveBy(x: 0, y: 20, duration: 0.3),
                    .fadeOut(withDuration: 0.3)
                ]),
                .removeFromParent()
            ]))
        } else {
            devModeIndicator?.removeFromParent()
            devModeIndicator = nil

            // Deactivate feedback
            let toast = SKLabelNode(text: "🔒 개발자 모드 비활성화")
            toast.fontName = "Helvetica-Bold"
            toast.fontSize = 16
            toast.fontColor = C.textDim
            toast.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
            toast.zPosition = 100
            addChild(toast)

            toast.run(.sequence([
                .group([
                    .moveBy(x: 0, y: 30, duration: 0.3),
                    .fadeIn(withDuration: 0.3)
                ]),
                .wait(forDuration: 1.5),
                .group([
                    .moveBy(x: 0, y: 20, duration: 0.3),
                    .fadeOut(withDuration: 0.3)
                ]),
                .removeFromParent()
            ]))
        }
    }
}
