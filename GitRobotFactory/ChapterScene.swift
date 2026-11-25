import SpriteKit

class ChapterScene: SKScene {
    private var missionButtons: [(node: SKNode, missionId: Int)] = []
    private var scrollOffset: CGFloat = 0
    private var contentNode = SKNode()
    
    override func didMove(to view: SKView) {
        backgroundColor = C.bg
        addChild(contentNode)
        setupTopBar()
        setupMissions()
    }
    
    // MARK: - Top Bar
    private func setupTopBar() {
        let bar = SKShapeNode(rectOf: CGSize(width: size.width, height: 44))
        bar.fillColor = C.topBarBg
        bar.strokeColor = .clear
        bar.position = CGPoint(x: size.width/2, y: size.height - 22)
        bar.zPosition = 10
        addChild(bar)
        
        let back = ButtonNode(text: "◀ 뒤로", width: 80, height: 28, color: C.buttonSecondary, fontSize: 11)
        back.position = CGPoint(x: 55, y: size.height - 22)
        back.zPosition = 11
        back.action = { [weak self] in self?.goToTitle() }
        addChild(back)
        
        let title = makeLabel("🏭 미션 선택", size: 16, color: C.text, bold: true)
        title.position = CGPoint(x: 170, y: size.height - 22)
        title.zPosition = 11
        addChild(title)
        
        let stars = makeLabel("⭐ \(GameData.shared.totalStars)", size: 12, color: C.yellow, bold: true)
        stars.position = CGPoint(x: size.width - 50, y: size.height - 22)
        stars.zPosition = 11
        addChild(stars)

        // Dev mode indicator
        if GameData.shared.devMode {
            let devLabel = makeLabel("DEV", size: 9, color: C.yellow, bold: true, mono: true)
            devLabel.position = CGPoint(x: size.width - 110, y: size.height - 22)
            devLabel.zPosition = 11
            devLabel.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.5, duration: 0.5),
                .fadeAlpha(to: 1.0, duration: 0.5)
            ])))
            addChild(devLabel)
        }

        let divider = SKShapeNode(rectOf: CGSize(width: size.width, height: 1))
        divider.fillColor = C.border
        divider.strokeColor = .clear
        divider.position = CGPoint(x: size.width/2, y: size.height - 44)
        divider.zPosition = 10
        addChild(divider)
    }
    
    // MARK: - Mission List
    private func setupMissions() {
        let data = GameData.shared
        let missions = GameData.missions

        var currentChapter = 0
        var y: CGFloat = size.height - 72

        for mission in missions {
            // Chapter header
            if mission.chapter != currentChapter {
                currentChapter = mission.chapter
                y -= 4

                let chHeader = SKShapeNode(rectOf: CGSize(width: size.width - 40, height: 22), cornerRadius: 4)
                chHeader.fillColor = C.textFaint.withAlphaComponent(0.12)
                chHeader.strokeColor = .clear
                chHeader.position = CGPoint(x: size.width/2, y: y - 11)
                contentNode.addChild(chHeader)

                let chTitle = makeLeftLabel(mission.chapterTitle.uppercased(), size: 9, color: C.textDim, bold: true, mono: true)
                chTitle.position = CGPoint(x: 30, y: y - 11)
                contentNode.addChild(chTitle)
                y -= 28
            }

            let done = data.completedMissions.contains(mission.id)
            let locked = data.isMissionLocked(mission.id)

            // Mission row card
            let rowW = size.width - 40
            let row = SKNode()
            row.position = CGPoint(x: size.width / 2, y: y)

            let rowBg = SKShapeNode(rectOf: CGSize(width: rowW, height: 50), cornerRadius: 10)
            rowBg.fillColor = done ? C.successBg : C.panelBg
            rowBg.strokeColor = done ? C.green.withAlphaComponent(0.45) : C.border
            rowBg.lineWidth = 1
            row.addChild(rowBg)

            // Left accent bar for done missions
            if done {
                let accent = SKShapeNode(rectOf: CGSize(width: 3, height: 36), cornerRadius: 2)
                accent.fillColor = C.green
                accent.strokeColor = .clear
                accent.position = CGPoint(x: -rowW/2 + 7, y: 0)
                row.addChild(accent)
            }

            // Status icon
            let icon = SKLabelNode(text: locked ? "🔒" : done ? "✅" : mission.rewardEmoji)
            icon.fontSize = 20
            icon.verticalAlignmentMode = .center
            icon.position = CGPoint(x: -(rowW/2 - 34), y: 0)
            row.addChild(icon)

            // Title + subtitle
            let titleText = "M\(mission.id): \(mission.title)"
            let mTitle = makeLeftLabel(titleText, size: 12, color: locked ? C.textFaint : C.text, bold: true)
            mTitle.position = CGPoint(x: -(rowW/2 - 64), y: 8)
            row.addChild(mTitle)

            let sub = makeLeftLabel(mission.subtitle, size: 10, color: C.textDim)
            sub.position = CGPoint(x: -(rowW/2 - 64), y: -9)
            row.addChild(sub)

            // Stars (right side)
            let starX: CGFloat = rowW/2 - 72
            for s in 0..<mission.stars {
                let star = SKLabelNode(text: "★")
                star.fontSize = 11
                star.fontColor = done ? C.yellow : C.starDim
                star.verticalAlignmentMode = .center
                star.position = CGPoint(x: starX + CGFloat(s) * 13, y: 0)
                row.addChild(star)
            }

            row.alpha = locked ? 0.38 : 1.0
            contentNode.addChild(row)

            if !locked {
                missionButtons.append((row, mission.id))
            }

            y -= 58
        }

        // Robot collection section
        if !data.collectedRobots.isEmpty {
            y -= 16
            let colTitle = makeLeftLabel("🤖  도감  (\(data.collectedRobots.count)/\(GameData.missions.count))", size: 11, color: C.textDim, bold: true)
            colTitle.position = CGPoint(x: 30, y: y)
            contentNode.addChild(colTitle)
            y -= 32

            let cols = 8
            for (i, robot) in data.collectedRobots.enumerated() {
                let col = i % cols
                let rowIdx = i / cols
                let rx = 65 + CGFloat(col) * 110
                let ry = y - CGFloat(rowIdx) * 52

                let emoji = SKLabelNode(text: robot.emoji)
                emoji.fontSize = 24
                emoji.position = CGPoint(x: rx, y: ry)
                contentNode.addChild(emoji)

                let name = makeLabel(robot.name, size: 7, color: C.textDim)
                name.position = CGPoint(x: rx, y: ry - 18)
                contentNode.addChild(name)
            }
        }
    }
    
    // MARK: - Scroll
    override func scrollWheel(with event: NSEvent) {
        let newOffset = scrollOffset + event.deltaY * 2
        let maxScroll = max(0, CGFloat(GameData.missions.count) * 58 - size.height + 150)
        scrollOffset = min(max(newOffset, 0), maxScroll)
        contentNode.position.y = -scrollOffset
    }
    
    // MARK: - Click
    override func mouseUp(with event: NSEvent) {
        let loc = event.location(in: self)
        
        let sceneNodes = nodes(at: loc)
        for node in sceneNodes {
            if let btn = node as? ButtonNode ?? node.parent as? ButtonNode {
                btn.action?()
                return
            }
        }
        
        let contentLoc = event.location(in: contentNode)
        for (node, missionId) in missionButtons {
            let nodeFrame = node.calculateAccumulatedFrame()
            if nodeFrame.contains(contentLoc) {
                startMission(missionId)
                return
            }
        }
    }
    
    private func startMission(_ id: Int) {
        let scene = GameScene(size: size)
        scene.scaleMode = .aspectFill
        scene.missionId = id
        view?.presentScene(scene, transition: .push(with: .left, duration: 0.3))
    }
    
    private func goToTitle() {
        let scene = TitleScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: .push(with: .right, duration: 0.3))
    }
}
