import SpriteKit

class CompleteScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = C.bg
        setupScene()
    }
    
    private func setupScene() {
        let cx = size.width / 2
        let data = GameData.shared
        
        // Trophy
        let trophy = makeEmoji("🏆", size: 100)
        trophy.position = CGPoint(x: cx, y: size.height - 100)
        trophy.setScale(0.2)
        trophy.run(.sequence([.scale(to: 1.2, duration: 0.3), .scale(to: 1.0, duration: 0.15)]))
        addChild(trophy)
        
        // Title
        let title = makeLabel("Git Flow 마스터!", size: 38, color: C.text, bold: true)
        title.position = CGPoint(x: cx, y: size.height - 180)
        addChild(title)
        
        let sub = makeLabel("모든 미션을 완료했습니다", size: 16, color: C.textDim)
        sub.position = CGPoint(x: cx, y: size.height - 210)
        addChild(sub)
        
        // Stats
        let starsLabel = makeLabel("⭐ \(data.totalStars)", size: 32, color: C.yellow, bold: true)
        starsLabel.position = CGPoint(x: cx - 80, y: size.height - 270)
        addChild(starsLabel)
        
        let robotCount = makeLabel("🤖 \(data.collectedRobots.count)", size: 32, color: C.text, bold: true)
        robotCount.position = CGPoint(x: cx + 80, y: size.height - 270)
        addChild(robotCount)
        
        // Collected robots
        let robotRow = SKNode()
        for (i, robot) in data.collectedRobots.enumerated() {
            let e = makeEmoji(robot.emoji, size: 36)
            e.position = CGPoint(x: CGFloat(i - data.collectedRobots.count/2) * 50, y: 0)
            e.setScale(0)
            e.run(.sequence([
                .wait(forDuration: 0.5 + Double(i) * 0.1),
                .scale(to: 1.2, duration: 0.15),
                .scale(to: 1.0, duration: 0.1)
            ]))
            robotRow.addChild(e)
        }
        robotRow.position = CGPoint(x: cx, y: size.height - 330)
        addChild(robotRow)
        
        // Git Flow summary panel
        let panelW: CGFloat = 560
        let panelH: CGFloat = 220
        let panelY: CGFloat = size.height - 480
        
        let panel = PanelNode(size: CGSize(width: panelW, height: panelH))
        panel.position = CGPoint(x: cx, y: panelY)
        addChild(panel)
        
        let panelTitle = makeLabel("📘 Git Flow 전체 구조", size: 15, color: C.text, bold: true)
        panelTitle.position = CGPoint(x: cx, y: panelY + 85)
        addChild(panelTitle)
        
        let branches: [(String, NSColor, String)] = [
            ("main", C.green, "출하 창고 — 프로덕션 코드"),
            ("develop", C.blue, "조립 라인 — 개발 통합"),
            ("feature/*", C.purple, "워크스테이션 — 기능 개발"),
            ("release/*", C.yellow, "QA 라인 — 출시 전 안정화"),
            ("hotfix/*", C.red, "긴급 수리 — 프로덕션 패치"),
        ]
        
        for (i, b) in branches.enumerated() {
            let y = panelY + 55 - CGFloat(i) * 24
            
            let badge = makeBadge(b.0, color: b.1, fontSize: 9)
            badge.position = CGPoint(x: cx - 160, y: y)
            addChild(badge)
            
            let desc = makeLeftLabel(b.2, size: 11, color: C.textDim)
            desc.position = CGPoint(x: cx - 80, y: y)
            addChild(desc)
        }
        
        // Diagram
        let diagram = makeLabel("main → develop → feature → develop → release → main", size: 10, color: C.textFaint, mono: true)
        diagram.position = CGPoint(x: cx, y: panelY - 80)
        addChild(diagram)
        
        // Commands panel
        let cmdPanelY = panelY - 140
        let cmds: [(String, String)] = [
            ("git commit", "작업 기록"),
            ("git checkout -b", "브랜치 생성"),
            ("git merge", "브랜치 통합"),
            ("git tag", "버전 태깅"),
            ("git branch -d", "브랜치 삭제"),
        ]
        
        let cmdTitle = makeLabel("✅ 학습 완료 Git 명령어", size: 13, color: C.green, bold: true)
        cmdTitle.position = CGPoint(x: cx, y: cmdPanelY + 50)
        addChild(cmdTitle)
        
        for (i, cmd) in cmds.enumerated() {
            let y = cmdPanelY + 25 - CGFloat(i) * 20
            let check = makeLabel("✓", size: 11, color: C.green, bold: true)
            check.position = CGPoint(x: cx - 200, y: y)
            addChild(check)
            
            let cmdLabel = makeLeftLabel(cmd.0, size: 11, color: C.text, bold: true, mono: true)
            cmdLabel.position = CGPoint(x: cx - 180, y: y)
            addChild(cmdLabel)
            
            let descLabel = makeLeftLabel("— \(cmd.1)", size: 11, color: C.textDim)
            descLabel.position = CGPoint(x: cx - 30, y: y)
            addChild(descLabel)
        }
        
        // Replay button
        let btn = ButtonNode(text: "🔄 다시 플레이", width: 180, height: 44, color: C.green, fontSize: 15)
        btn.position = CGPoint(x: cx, y: 50)
        btn.action = { [weak self] in self?.goToChapters() }
        addChild(btn)
    }
    
    override func mouseUp(with event: NSEvent) {
        let loc = event.location(in: self)
        for node in nodes(at: loc) {
            if let btn = node as? ButtonNode ?? node.parent as? ButtonNode {
                btn.action?()
                return
            }
        }
    }
    
    private func goToChapters() {
        let scene = ChapterScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: .push(with: .right, duration: 0.4))
    }
}
