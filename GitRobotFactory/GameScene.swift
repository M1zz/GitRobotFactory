import SpriteKit

class GameScene: SKScene {
    var missionId: Int = 1
    
    private var mission: Mission!
    private var phaseIndex = 0
    private var actionDone = false
    
    // Layout constants
    private let leftWidth: CGFloat = 500
    private let rightWidth: CGFloat = 700
    private let topBarH: CGFloat = 50
    private let terminalH: CGFloat = 140
    
    // Sub-nodes
    private var robotNode = RobotNode()
    private var gitGraph = GitGraphNode()
    private var terminal: TerminalNode!
    private var assemblyZone = AssemblyZone()
    
    // UI elements
    private var instructionLabel: SKLabelNode!
    private var branchBadge: SKNode!
    private var phaseCounter: SKLabelNode!
    private var progressBar: SKShapeNode!
    private var progressFill: SKShapeNode!
    private var explanationGroup: SKNode?
    
    private var activeBranches: [String] = ["main"]
    private var currentBranch = "main"

    // MARK: - Drag & Drop State
    private var draggedCard: PartCardNode?
    private var ghostCard: PartCardNode?
    private var dragStartPosition: CGPoint?
    private var currentHighlight: SKNode?
    private let dragThreshold: CGFloat = 5.0

    override func didMove(to view: SKView) {
        backgroundColor = C.bg
        mission = GameData.missions.first(where: { $0.id == missionId }) ?? GameData.missions[0]
        
        setupTopBar()
        setupProgressBar()
        setupLeftPanel()
        setupRightPanel()
        setupTerminal()
        
        showCurrentPhase()
    }
    
    // MARK: - Layout Setup
    
    private func setupTopBar() {
        let bar = SKShapeNode(rectOf: CGSize(width: size.width, height: topBarH))
        bar.fillColor = NSColor(white: 0.06, alpha: 1)
        bar.strokeColor = .clear
        bar.position = CGPoint(x: size.width/2, y: size.height - topBarH/2)
        bar.zPosition = 10
        addChild(bar)
        
        // Back button
        let back = ButtonNode(text: "◀ 미션 목록", width: 110, height: 30, color: NSColor(white: 0.15, alpha: 1), fontSize: 11)
        back.position = CGPoint(x: 75, y: size.height - topBarH/2)
        back.zPosition = 11
        back.action = { [weak self] in self?.goToChapters() }
        addChild(back)
        
        // Mission title
        let title = makeLabel("Mission \(mission.id): \(mission.title)", size: 14, color: C.text, bold: true)
        title.position = CGPoint(x: 240, y: size.height - topBarH/2)
        title.zPosition = 11
        addChild(title)
        
        // Branch badge
        branchBadge = makeBadge(currentBranch, color: C.branchColor(currentBranch))
        branchBadge.position = CGPoint(x: size.width - 250, y: size.height - topBarH/2)
        branchBadge.zPosition = 11
        addChild(branchBadge)
        
        // Phase counter
        phaseCounter = makeLabel("Phase 1/\(mission.phases.count)", size: 11, color: C.textDim, mono: true)
        phaseCounter.position = CGPoint(x: size.width - 120, y: size.height - topBarH/2)
        phaseCounter.zPosition = 11
        addChild(phaseCounter)
        
        // Stars
        let stars = makeLabel("⭐\(GameData.shared.totalStars)", size: 12, color: C.yellow)
        stars.position = CGPoint(x: size.width - 40, y: size.height - topBarH/2)
        stars.zPosition = 11
        addChild(stars)
    }
    
    private func setupProgressBar() {
        let y = size.height - topBarH - 2
        progressBar = SKShapeNode(rectOf: CGSize(width: size.width, height: 3))
        progressBar.fillColor = NSColor(white: 0.12, alpha: 1)
        progressBar.strokeColor = .clear
        progressBar.position = CGPoint(x: size.width/2, y: y)
        progressBar.zPosition = 10
        addChild(progressBar)
        
        progressFill = SKShapeNode(rectOf: CGSize(width: 0, height: 3))
        progressFill.fillColor = C.green
        progressFill.strokeColor = .clear
        progressFill.position = CGPoint(x: 0, y: y)
        progressFill.zPosition = 11
        addChild(progressFill)
    }
    
    private func updateProgress() {
        let frac = CGFloat(phaseIndex) / CGFloat(max(mission.phases.count, 1))
        let w = size.width * frac
        progressFill.removeFromParent()
        progressFill = SKShapeNode(rectOf: CGSize(width: w, height: 3))
        progressFill.fillColor = C.green
        progressFill.strokeColor = .clear
        progressFill.position = CGPoint(x: w/2, y: size.height - topBarH - 2)
        progressFill.zPosition = 11
        addChild(progressFill)
    }
    
    private func setupLeftPanel() {
        let panelY = size.height - topBarH - 5
        
        // Divider
        let divider = SKShapeNode(rectOf: CGSize(width: 1, height: size.height - topBarH - terminalH))
        divider.fillColor = C.border
        divider.strokeColor = .clear
        divider.position = CGPoint(x: leftWidth, y: (size.height - topBarH - terminalH) / 2 + terminalH)
        addChild(divider)
        
        // Instruction area (top-left)
        instructionLabel = SKLabelNode()
        instructionLabel.fontName = "Helvetica-Bold"
        instructionLabel.fontSize = 14
        instructionLabel.fontColor = C.text
        instructionLabel.verticalAlignmentMode = .top
        instructionLabel.horizontalAlignmentMode = .left
        instructionLabel.preferredMaxLayoutWidth = leftWidth - 60
        instructionLabel.numberOfLines = 0
        instructionLabel.position = CGPoint(x: 30, y: panelY - 20)
        addChild(instructionLabel)
        
        // Assembly zone (center-left)
        assemblyZone.position = CGPoint(x: leftWidth / 2, y: (size.height - topBarH + terminalH) / 2 - 30)
        addChild(assemblyZone)
        
        // Wire up assembly callbacks
        assemblyZone.onPartSelected = { [weak self] part in self?.handlePartSelected(part) }
        assemblyZone.onWorkstationOpened = { [weak self] name in self?.handleWorkstationOpened(name) }
        assemblyZone.onMerge = { [weak self] from, to in self?.handleMerge(from, to) }
        assemblyZone.onConflictResolved = { [weak self] in self?.handleConflictResolved() }
        assemblyZone.onTagged = { [weak self] ver in self?.handleTagged(ver) }
        assemblyZone.onShipped = { [weak self] in self?.handleShipped() }
        assemblyZone.onCleanup = { [weak self] name in self?.handleCleanup(name) }
        assemblyZone.onEmergencyFix = { [weak self] part in self?.handleEmergencyFix(part) }
    }
    
    private func setupRightPanel() {
        let rightCenterX = leftWidth + rightWidth / 2
        let midY = (size.height - topBarH + terminalH) / 2
        
        // Robot
        let robotTitle = makeLabel("🤖 로봇 조립", size: 11, color: C.textDim, bold: true, mono: true)
        robotTitle.position = CGPoint(x: leftWidth + 120, y: size.height - topBarH - 20)
        addChild(robotTitle)
        
        robotNode.position = CGPoint(x: leftWidth + 120, y: midY + 30)
        addChild(robotNode)
        
        // Divider
        let div2 = SKShapeNode(rectOf: CGSize(width: 1, height: size.height - topBarH - terminalH))
        div2.fillColor = C.border
        div2.strokeColor = .clear
        div2.position = CGPoint(x: leftWidth + 240, y: midY)
        addChild(div2)
        
        // Git graph
        let graphTitle = makeLabel("GIT GRAPH", size: 11, color: C.textDim, bold: true, mono: true)
        graphTitle.position = CGPoint(x: leftWidth + 400, y: size.height - topBarH - 20)
        addChild(graphTitle)
        
        gitGraph.position = CGPoint(x: leftWidth + 300, y: terminalH + 30)
        addChild(gitGraph)
    }
    
    private func setupTerminal() {
        terminal = TerminalNode(width: size.width - 40)
        terminal.position = CGPoint(x: size.width / 2, y: terminalH / 2 + 10)
        addChild(terminal)
    }
    
    // MARK: - Phase Management
    
    private func showCurrentPhase() {
        guard phaseIndex < mission.phases.count else { return }
        let phase = mission.phases[phaseIndex]
        
        // Update UI
        phaseCounter.text = "Phase \(phaseIndex + 1)/\(mission.phases.count)"
        updateProgress()
        updateBranchBadge(phase.branchContext)
        
        // Instruction
        let instructionBg = SKShapeNode(rectOf: CGSize(width: leftWidth - 40, height: 60), cornerRadius: 10)
        instructionBg.fillColor = NSColor(red: 0.08, green: 0.12, blue: 0.2, alpha: 1)
        instructionBg.strokeColor = C.blue.withAlphaComponent(0.3)
        instructionBg.lineWidth = 1
        instructionBg.position = CGPoint(x: leftWidth/2, y: size.height - topBarH - 55)
        instructionBg.name = "instructionBg"
        instructionBg.zPosition = 5
        addChild(instructionBg)
        
        let prefix = makeLabel("📋", size: 16)
        prefix.position = CGPoint(x: 30, y: size.height - topBarH - 45)
        prefix.zPosition = 6
        prefix.name = "instructionPrefix"
        addChild(prefix)
        
        instructionLabel.text = phase.instruction
        instructionLabel.position = CGPoint(x: 55, y: size.height - topBarH - 30)
        
        // Show assembly action
        actionDone = false
        assemblyZone.showAction(phase.assemblyAction)
        
        // Remove old explanation
        explanationGroup?.removeFromParent()
        explanationGroup = nil
    }
    
    private func updateBranchBadge(_ context: String) {
        branchBadge.removeFromParent()
        let branchName = context.components(separatedBy: " ").last ?? currentBranch
        branchBadge = makeBadge(branchName, color: C.branchColor(branchName))
        branchBadge.position = CGPoint(x: size.width - 250, y: size.height - topBarH/2)
        branchBadge.zPosition = 11
        addChild(branchBadge)
    }
    
    private func completePhaseAction() {
        guard !actionDone, phaseIndex < mission.phases.count else { return }
        actionDone = true
        let phase = mission.phases[phaseIndex]
        
        // Add to terminal
        terminal.addCommand(phase.gitCommand)
        
        // Add git graph node
        let branchName = phase.branchContext.components(separatedBy: " ").last ?? currentBranch
        let nodeType: String
        switch phase.assemblyAction {
        case .mergeParts, .shipRobot: nodeType = "merge"
        case .openWorkstation: nodeType = "branch"
        case .tagVersion: nodeType = "tag"
        case .resolveConflict: nodeType = "conflict"
        default: nodeType = "commit"
        }
        gitGraph.addEntry(branch: branchName, label: String(phase.instruction.prefix(30)), type: nodeType)
        
        // Clear assembly zone
        assemblyZone.clearCurrent()
        
        // Show explanation popup
        showExplanation(phase)
    }
    
    private func showExplanation(_ phase: MissionPhase) {
        let group = SKNode()
        group.name = "explanation"
        group.zPosition = 20
        
        let bg = SKShapeNode(rectOf: CGSize(width: leftWidth - 40, height: 180), cornerRadius: 12)
        bg.fillColor = NSColor(red: 0.12, green: 0.1, blue: 0.04, alpha: 1)
        bg.strokeColor = C.yellow.withAlphaComponent(0.3)
        bg.lineWidth = 1
        bg.position = CGPoint(x: leftWidth/2, y: (size.height - topBarH + terminalH) / 2 - 30)
        group.addChild(bg)
        
        let bulb = makeLabel("💡 Git 개념", size: 13, color: C.yellow, bold: true)
        bulb.position = CGPoint(x: leftWidth/2, y: bg.position.y + 65)
        group.addChild(bulb)
        
        let exp = SKLabelNode(text: phase.explanation)
        exp.fontName = "Helvetica"
        exp.fontSize = 12.5
        exp.fontColor = NSColor(white: 0.8, alpha: 1)
        exp.verticalAlignmentMode = .center
        exp.horizontalAlignmentMode = .center
        exp.preferredMaxLayoutWidth = leftWidth - 80
        exp.numberOfLines = 0
        exp.position = CGPoint(x: leftWidth/2, y: bg.position.y + 25)
        group.addChild(exp)
        
        // Git command
        let cmdBg = SKShapeNode(rectOf: CGSize(width: leftWidth - 80, height: 28), cornerRadius: 6)
        cmdBg.fillColor = NSColor(white: 0.04, alpha: 1)
        cmdBg.strokeColor = .clear
        cmdBg.position = CGPoint(x: leftWidth/2, y: bg.position.y - 20)
        group.addChild(cmdBg)
        
        let cmdText = makeLabel(phase.gitCommand.components(separatedBy: "\n").first ?? phase.gitCommand,
                                size: 11, color: C.green, bold: true, mono: true)
        cmdText.position = cmdBg.position
        group.addChild(cmdText)
        
        // Continue button
        let nextBtn = ButtonNode(text: "이해했어요! →", width: 160, height: 36, color: C.green, fontSize: 13)
        nextBtn.position = CGPoint(x: leftWidth/2, y: bg.position.y - 65)
        nextBtn.zPosition = 21
        nextBtn.action = { [weak self] in self?.advancePhase() }
        group.addChild(nextBtn)
        
        // Animate in
        group.alpha = 0
        group.run(.fadeIn(withDuration: 0.25))
        
        addChild(group)
        explanationGroup = group
    }
    
    private func advancePhase() {
        // Clean up any ongoing drag
        cleanupDrag()

        // Remove explanation
        explanationGroup?.run(.sequence([.fadeOut(withDuration: 0.15), .removeFromParent()]))
        explanationGroup = nil

        // Remove instruction bg
        childNode(withName: "instructionBg")?.removeFromParent()
        childNode(withName: "instructionPrefix")?.removeFromParent()

        phaseIndex += 1
        
        if phaseIndex >= mission.phases.count {
            showReward()
        } else {
            showCurrentPhase()
        }
    }
    
    // MARK: - Reward
    
    private func showReward() {
        let data = GameData.shared
        data.completedMissions.insert(missionId)
        data.totalStars += mission.stars
        data.collectedRobots.append((emoji: mission.rewardEmoji, name: mission.rewardName))
        
        assemblyZone.clearCurrent()
        childNode(withName: "instructionBg")?.removeFromParent()
        childNode(withName: "instructionPrefix")?.removeFromParent()
        instructionLabel.text = ""
        
        let group = SKNode()
        group.zPosition = 30
        let cx = leftWidth / 2
        let cy = (size.height - topBarH + terminalH) / 2
        
        // Robot emoji
        let emoji = makeEmoji(mission.rewardEmoji, size: 72)
        emoji.position = CGPoint(x: cx, y: cy + 60)
        emoji.setScale(0.2)
        emoji.run(.sequence([
            .scale(to: 1.2, duration: 0.2),
            .scale(to: 1.0, duration: 0.1)
        ]))
        group.addChild(emoji)
        
        // Name
        let name = makeLabel(mission.rewardName, size: 14, color: C.textDim, bold: true)
        name.position = CGPoint(x: cx, y: cy + 10)
        group.addChild(name)
        
        // Stars
        for i in 0..<mission.stars {
            let star = SKLabelNode(text: "★")
            star.fontSize = 22
            star.fontColor = C.yellow
            star.verticalAlignmentMode = .center
            star.position = CGPoint(x: cx + CGFloat(i - mission.stars/2) * 26, y: cy - 20)
            star.setScale(0)
            star.run(.sequence([
                .wait(forDuration: 0.3 + Double(i) * 0.15),
                .scale(to: 1.2, duration: 0.15),
                .scale(to: 1.0, duration: 0.1)
            ]))
            group.addChild(star)
        }
        
        // Complete text
        let complete = makeLabel("미션 완료! 🎉", size: 18, color: C.green, bold: true)
        complete.position = CGPoint(x: cx, y: cy - 55)
        group.addChild(complete)
        
        // Lesson
        let lessonBg = SKShapeNode(rectOf: CGSize(width: leftWidth - 60, height: 50), cornerRadius: 8)
        lessonBg.fillColor = C.blue.withAlphaComponent(0.08)
        lessonBg.strokeColor = C.blue.withAlphaComponent(0.2)
        lessonBg.position = CGPoint(x: cx, y: cy - 100)
        group.addChild(lessonBg)
        
        let lesson = SKLabelNode(text: mission.gitLesson)
        lesson.fontName = "Helvetica"
        lesson.fontSize = 11
        lesson.fontColor = NSColor(white: 0.7, alpha: 1)
        lesson.preferredMaxLayoutWidth = leftWidth - 90
        lesson.numberOfLines = 0
        lesson.verticalAlignmentMode = .center
        lesson.position = lessonBg.position
        group.addChild(lesson)
        
        // Next button
        let isLast = missionId >= GameData.missions.count
        let nextBtn = ButtonNode(text: isLast ? "🏆 최종 결과" : "다음 미션 →", width: 180, height: 44, color: C.green, fontSize: 14)
        nextBtn.position = CGPoint(x: cx, y: cy - 155)
        nextBtn.zPosition = 31
        nextBtn.action = { [weak self] in
            if isLast {
                self?.goToComplete()
            } else {
                self?.goToNextMission()
            }
        }
        group.addChild(nextBtn)
        
        addChild(group)
    }
    
    // MARK: - Action Handlers
    
    private func handlePartSelected(_ part: RobotPart) {
        robotNode.installPart(part)
        completePhaseAction()
    }
    
    private func handleWorkstationOpened(_ name: String) {
        if !activeBranches.contains(name) {
            activeBranches.append(name)
        }
        currentBranch = name
        completePhaseAction()
    }
    
    private func handleMerge(_ from: String, _ to: String) {
        currentBranch = to
        completePhaseAction()
    }
    
    private func handleConflictResolved() {
        completePhaseAction()
    }
    
    private func handleTagged(_ version: String) {
        completePhaseAction()
    }
    
    private func handleShipped() {
        currentBranch = "main"
        completePhaseAction()
    }
    
    private func handleCleanup(_ name: String) {
        activeBranches.removeAll { $0 == name }
        completePhaseAction()
    }
    
    private func handleEmergencyFix(_ part: RobotPart) {
        robotNode.installPart(part)
        completePhaseAction()
    }
    
    // MARK: - Navigation
    
    private func goToChapters() {
        let scene = ChapterScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: .push(with: .right, duration: 0.4))
    }
    
    private func goToNextMission() {
        let scene = GameScene(size: size)
        scene.scaleMode = .aspectFill
        scene.missionId = missionId + 1
        view?.presentScene(scene, transition: .push(with: .left, duration: 0.4))
    }
    
    private func goToComplete() {
        let scene = CompleteScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: .fade(withDuration: 0.5))
    }
    
    // MARK: - Mouse Handling

    override func mouseDown(with event: NSEvent) {
        let loc = event.location(in: self)
        let allNodes = nodes(at: loc)

        // Check if we're clicking on a part card
        for node in allNodes {
            if let card = findPartCard(in: node) {
                draggedCard = card
                dragStartPosition = loc
                return
            }
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let card = draggedCard, let startPos = dragStartPosition else { return }

        let loc = event.location(in: self)
        let distance = hypot(loc.x - startPos.x, loc.y - startPos.y)

        // Create ghost card if dragged beyond threshold
        if distance > dragThreshold && ghostCard == nil {
            createGhostCard(from: card)
        }

        // Update ghost position and highlight
        if let ghost = ghostCard {
            ghost.position = loc
            updateSlotHighlight(at: loc, for: card.part)
        }
    }

    override func mouseUp(with event: NSEvent) {
        let loc = event.location(in: self)

        // 1. If we have a ghost card, handle drop
        if ghostCard != nil {
            handleDrop(at: loc)
            cleanupDrag()
            return
        }

        // 2. If we started dragging but didn't create ghost (below threshold), treat as click
        if let card = draggedCard {
            card.onSelect?(card.part)
            cleanupDrag()
            return
        }

        // 3. Normal click handling (buttons, cards, etc.)
        let allNodes = nodes(at: loc)
        for node in allNodes {
            // Check ButtonNode
            if let btn = findButton(in: node) {
                btn.action?()
                return
            }
            // Check PartCardNode
            if let card = findPartCard(in: node) {
                card.onSelect?(card.part)
                return
            }
            // Check MergeCardNode
            if let merge = findMergeCard(in: node) {
                merge.onMerge?()
                return
            }
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        // Handle hover states via tracking areas if needed
    }
    
    private func findButton(in node: SKNode) -> ButtonNode? {
        if let btn = node as? ButtonNode { return btn }
        if let parent = node.parent { return findButton(in: parent) }
        return nil
    }
    
    private func findPartCard(in node: SKNode) -> PartCardNode? {
        if let card = node as? PartCardNode { return card }
        if let parent = node.parent { return findPartCard(in: parent) }
        return nil
    }
    
    private func findMergeCard(in node: SKNode) -> MergeCardNode? {
        if let card = node as? MergeCardNode { return card }
        if let parent = node.parent { return findMergeCard(in: parent) }
        return nil
    }

    // MARK: - Drag & Drop Methods

    private func createGhostCard(from card: PartCardNode) {
        // Create a copy of the card for dragging
        let ghost = PartCardNode(part: card.part)
        ghost.position = card.convert(card.position, to: self)
        ghost.zPosition = 100 // Above everything
        ghost.alpha = 0.8
        ghost.setScale(1.15)

        // Add glow effect
        let glow = SKShapeNode(rectOf: CGSize(width: 130, height: 110), cornerRadius: 12)
        glow.fillColor = .clear
        glow.strokeColor = C.blue.withAlphaComponent(0.6)
        glow.lineWidth = 2
        glow.glowWidth = 8
        glow.zPosition = -1
        ghost.addChild(glow)

        addChild(ghost)
        ghostCard = ghost

        // Dim the original card
        card.alpha = 0.5
    }

    private func findDropTarget(at location: CGPoint, for part: RobotPart) -> SKNode? {
        // Find the slot for this part type
        guard let slotNode = robotNode.slots[part.slot] else { return nil }

        // Convert slot position to scene coordinates
        let slotPosition = robotNode.convert(slotNode.position, to: self)

        // Check if location is close enough to the slot
        let distance = hypot(location.x - slotPosition.x, location.y - slotPosition.y)
        let threshold: CGFloat = 40

        return distance <= threshold ? slotNode : nil
    }

    private func updateSlotHighlight(at location: CGPoint, for part: RobotPart) {
        // Remove previous highlight
        currentHighlight?.removeFromParent()
        currentHighlight = nil

        // Find if we're hovering over the correct slot
        guard let targetSlot = findDropTarget(at: location, for: part) else { return }

        // Create highlight
        let size = part.slot == .torso ? CGSize(width: 55, height: 55) : CGSize(width: 48, height: 48)
        let highlight = SKShapeNode(rectOf: size, cornerRadius: 8)
        highlight.fillColor = C.green.withAlphaComponent(0.2)
        highlight.strokeColor = C.green.withAlphaComponent(0.8)
        highlight.lineWidth = 2
        highlight.zPosition = -1

        // Add pulse animation
        let pulse = SKAction.sequence([
            .scale(to: 1.1, duration: 0.4),
            .scale(to: 1.0, duration: 0.4)
        ])
        highlight.run(.repeatForever(pulse))

        targetSlot.addChild(highlight)
        currentHighlight = highlight
    }

    private func handleDrop(at location: CGPoint) {
        guard let ghost = ghostCard, let card = draggedCard else { return }

        if let targetSlot = findDropTarget(at: location, for: card.part) {
            // Success! Install the part
            let slotPosition = robotNode.convert(targetSlot.position, to: self)

            // Animate ghost to slot position
            let move = SKAction.move(to: slotPosition, duration: 0.2)
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            ghost.run(.group([move, fadeOut]))

            // Install part and complete phase
            robotNode.installPart(card.part)
            completePhaseAction()
        } else {
            // Failed - show feedback
            let shake = SKAction.sequence([
                .moveBy(x: -8, y: 0, duration: 0.05),
                .moveBy(x: 16, y: 0, duration: 0.1),
                .moveBy(x: -16, y: 0, duration: 0.1),
                .moveBy(x: 8, y: 0, duration: 0.05)
            ])

            // Red flash
            let flash = SKShapeNode(rectOf: CGSize(width: 130, height: 110), cornerRadius: 12)
            flash.fillColor = .clear
            flash.strokeColor = NSColor.red.withAlphaComponent(0.8)
            flash.lineWidth = 3
            flash.zPosition = -1
            ghost.addChild(flash)

            let fadeFlash = SKAction.sequence([
                .wait(forDuration: 0.3),
                .fadeOut(withDuration: 0.2),
                .removeFromParent()
            ])
            flash.run(fadeFlash)

            let shrinkFade = SKAction.sequence([
                shake,
                .group([
                    .scale(to: 0.5, duration: 0.2),
                    .fadeOut(withDuration: 0.2)
                ])
            ])
            ghost.run(shrinkFade)
        }
    }

    private func cleanupDrag() {
        // Restore original card alpha
        if let card = draggedCard {
            card.alpha = 1.0
        }

        // Remove ghost card
        ghostCard?.removeFromParent()

        // Remove highlight
        currentHighlight?.removeFromParent()

        // Reset state
        draggedCard = nil
        ghostCard = nil
        dragStartPosition = nil
        currentHighlight = nil
    }
}
