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
        let bar = SKShapeNode(rectOf: CGSize(width: size.width, height: 50))
        bar.fillColor = NSColor(white: 0.06, alpha: 1)
        bar.strokeColor = .clear
        bar.position = CGPoint(x: size.width/2, y: size.height - 25)
        bar.zPosition = 10
        addChild(bar)
        
        let back = ButtonNode(text: "◀ 돌아가기", width: 110, height: 32, color: NSColor(white: 0.15, alpha: 1), fontSize: 12)
        back.position = CGPoint(x: 80, y: size.height - 25)
        back.zPosition = 11
        back.action = { [weak self] in self?.goToTitle() }
        addChild(back)
        
        let title = makeLabel("🏭 미션 선택", size: 20, color: C.text, bold: true)
        title.position = CGPoint(x: 220, y: size.height - 25)
        title.zPosition = 11
        addChild(title)
        
        let stars = makeLabel("⭐ \(GameData.shared.totalStars)", size: 13, color: C.yellow, bold: true)
        stars.position = CGPoint(x: size.width - 60, y: size.height - 25)
        stars.zPosition = 11
        addChild(stars)
        
        let divider = SKShapeNode(rectOf: CGSize(width: size.width, height: 1))
        divider.fillColor = C.border
        divider.strokeColor = .clear
        divider.position = CGPoint(x: size.width/2, y: size.height - 50)
        divider.zPosition = 10
        addChild(divider)
    }
    
    // MARK: - Mission List
    private func setupMissions() {
        let data = GameData.shared
        let missions = GameData.missions
        
        var currentChapter = 0
        var y: CGFloat = size.height - 90
        
        for mission in missions {
            // Chapter header
            if mission.chapter != currentChapter {
                currentChapter = mission.chapter
                let chTitle = makeLeftLabel(mission.chapterTitle.uppercased(), size: 11, color: C.textDim, bold: true, mono: true)
                chTitle.position = CGPoint(x: 40, y: y)
                contentNode.addChild(chTitle)
                y -= 35
            }
            
            let done = data.completedMissions.contains(mission.id)
            let locked = data.isMissionLocked(mission.id)
            
            // Mission row
            let row = SKNode()
            row.position = CGPoint(x: size.width / 2, y: y)
            
            let rowBg = SKShapeNode(rectOf: CGSize(width: size.width - 60, height: 56), cornerRadius: 12)
            rowBg.fillColor = done ? NSColor(red: 0.05, green: 0.15, blue: 0.09, alpha: 1) : NSColor(white: 0.09, alpha: 1)
            rowBg.strokeColor = done ? C.green.withAlphaComponent(0.4) : C.border
            rowBg.lineWidth = 1
            row.addChild(rowBg)
            
            // Icon
            let icon = SKLabelNode(text: locked ? "🔒" : done ? "✅" : mission.rewardEmoji)
            icon.fontSize = 26
            icon.verticalAlignmentMode = .center
            icon.position = CGPoint(x: -(size.width/2 - 70), y: 0)
            row.addChild(icon)
            
            // Title
            let titleText = "Mission \(mission.id): \(mission.title)"
            let mTitle = makeLeftLabel(titleText, size: 14, color: locked ? C.textFaint : C.text, bold: true)
            mTitle.position = CGPoint(x: -(size.width/2 - 110), y: 6)
            row.addChild(mTitle)
            
            let sub = makeLeftLabel(mission.subtitle, size: 11, color: C.textDim)
            sub.position = CGPoint(x: -(size.width/2 - 110), y: -12)
            row.addChild(sub)
            
            // Stars
            var starX: CGFloat = (size.width/2 - 90)
            for s in 0..<mission.stars {
                let star = SKLabelNode(text: "★")
                star.fontSize = 14
                star.fontColor = done ? C.yellow : NSColor(white: 0.2, alpha: 1)
                star.verticalAlignmentMode = .center
                star.position = CGPoint(x: starX + CGFloat(s) * 16, y: 0)
                row.addChild(star)
            }
            
            row.alpha = locked ? 0.4 : 1.0
            contentNode.addChild(row)
            
            if !locked {
                missionButtons.append((row, mission.id))
            }
            
            y -= 68
        }
        
        // Robot collection
        if !data.collectedRobots.isEmpty {
            y -= 15
            let colTitle = makeLeftLabel("🤖 로봇 도감 (\(data.collectedRobots.count)/\(missions.count))", size: 13, color: C.textDim, bold: true)
            colTitle.position = CGPoint(x: 40, y: y)
            contentNode.addChild(colTitle)
            y -= 35
            
            let cols = 8
            for (i, robot) in data.collectedRobots.enumerated() {
                let col = i % cols
                let rowIdx = i / cols
                let rx = 80 + CGFloat(col) * 130
                let ry = y - CGFloat(rowIdx) * 60
                
                let emoji = SKLabelNode(text: robot.emoji)
                emoji.fontSize = 32
                emoji.position = CGPoint(x: rx, y: ry)
                contentNode.addChild(emoji)
                
                let name = makeLabel(robot.name, size: 8, color: C.textDim)
                name.position = CGPoint(x: rx, y: ry - 22)
                contentNode.addChild(name)
            }
        }
    }
    
    // MARK: - Scroll
    override func scrollWheel(with event: NSEvent) {
        let newOffset = scrollOffset + event.deltaY * 2
        let maxScroll = max(0, CGFloat(GameData.missions.count) * 68 - size.height + 200)
        scrollOffset = min(max(newOffset, 0), maxScroll)
        contentNode.position.y = -scrollOffset
    }
    
    // MARK: - Click
    override func mouseUp(with event: NSEvent) {
        let loc = event.location(in: self)
        
        // Check buttons in scene (not in contentNode)
        let sceneNodes = nodes(at: loc)
        for node in sceneNodes {
            if let btn = node as? ButtonNode ?? node.parent as? ButtonNode {
                btn.action?()
                return
            }
        }
        
        // Check mission rows in contentNode
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
        view?.presentScene(scene, transition: .push(with: .left, duration: 0.4))
    }
    
    private func goToTitle() {
        let scene = TitleScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: .push(with: .right, duration: 0.4))
    }
}
