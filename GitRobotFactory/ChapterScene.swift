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
        bar.fillColor = NSColor(white: 0.05, alpha: 1)
        bar.strokeColor = .clear
        bar.position = CGPoint(x: size.width/2, y: size.height - 22)
        bar.zPosition = 10
        addChild(bar)
        
        let back = ButtonNode(text: "◀ 뒤로", width: 80, height: 28, color: NSColor(white: 0.12, alpha: 1), fontSize: 11)
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
        var y: CGFloat = size.height - 70
        
        for mission in missions {
            // Chapter header
            if mission.chapter != currentChapter {
                currentChapter = mission.chapter
                let chTitle = makeLeftLabel(mission.chapterTitle.uppercased(), size: 10, color: C.textDim, bold: true, mono: true)
                chTitle.position = CGPoint(x: 30, y: y)
                contentNode.addChild(chTitle)
                y -= 28
            }
            
            let done = data.completedMissions.contains(mission.id)
            let locked = data.isMissionLocked(mission.id)
            
            // Mission row (compact)
            let row = SKNode()
            row.position = CGPoint(x: size.width / 2, y: y)
            
            let rowBg = SKShapeNode(rectOf: CGSize(width: size.width - 40, height: 48), cornerRadius: 10)
            rowBg.fillColor = done ? NSColor(red: 0.04, green: 0.12, blue: 0.06, alpha: 1) : NSColor(white: 0.07, alpha: 1)
            rowBg.strokeColor = done ? C.green.withAlphaComponent(0.35) : C.border
            rowBg.lineWidth = 1
            row.addChild(rowBg)
            
            // Icon
            let icon = SKLabelNode(text: locked ? "🔒" : done ? "✅" : mission.rewardEmoji)
            icon.fontSize = 22
            icon.verticalAlignmentMode = .center
            icon.position = CGPoint(x: -(size.width/2 - 55), y: 0)
            row.addChild(icon)
            
            // Title
            let titleText = "M\(mission.id): \(mission.title)"
            let mTitle = makeLeftLabel(titleText, size: 12, color: locked ? C.textFaint : C.text, bold: true)
            mTitle.position = CGPoint(x: -(size.width/2 - 85), y: 6)
            row.addChild(mTitle)
            
            let sub = makeLeftLabel(mission.subtitle, size: 10, color: C.textDim)
            sub.position = CGPoint(x: -(size.width/2 - 85), y: -10)
            row.addChild(sub)
            
            // Stars
            let starX: CGFloat = (size.width/2 - 70)
            for s in 0..<mission.stars {
                let star = SKLabelNode(text: "★")
                star.fontSize = 12
                star.fontColor = done ? C.yellow : NSColor(white: 0.18, alpha: 1)
                star.verticalAlignmentMode = .center
                star.position = CGPoint(x: starX + CGFloat(s) * 14, y: 0)
                row.addChild(star)
            }
            
            row.alpha = locked ? 0.35 : 1.0
            contentNode.addChild(row)
            
            if !locked {
                missionButtons.append((row, mission.id))
            }
            
            y -= 58
        }
        
        // Robot collection
        if !data.collectedRobots.isEmpty {
            y -= 12
            let colTitle = makeLeftLabel("🤖 도감 (\(data.collectedRobots.count)/\(missions.count))", size: 11, color: C.textDim, bold: true)
            colTitle.position = CGPoint(x: 30, y: y)
            contentNode.addChild(colTitle)
            y -= 30
            
            let cols = 8
            for (i, robot) in data.collectedRobots.enumerated() {
                let col = i % cols
                let rowIdx = i / cols
                let rx = 65 + CGFloat(col) * 110
                let ry = y - CGFloat(rowIdx) * 50
                
                let emoji = SKLabelNode(text: robot.emoji)
                emoji.fontSize = 26
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
