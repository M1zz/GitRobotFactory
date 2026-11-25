import SpriteKit

class GameScene: SKScene {
    var missionId: Int = 1

    private var mission: Mission!
    private var phaseIndex = 0
    private var actionDone = false

    // Git workflow states
    private enum GitState {
        case waiting        // Waiting for user action
        case modified       // Changes in working directory
        case staged         // Changes staged (git add)
        case committed      // Changes committed
    }
    private var currentGitState: GitState = .waiting

    // Git history for undo/redo
    private var gitHistory: [GitHistoryEntry] = []
    private var historyIndex: Int = -1
    private var stashedPart: RobotPart?

    private struct GitHistoryEntry {
        let part: RobotPart?
        let action: String
        let branchName: String
    }

    // File system tracking
    private enum FileStatus {
        case untracked
        case modified
        case staged
        case committed
    }

    private struct GitFile {
        let name: String
        let partSlot: PartSlot
        var status: FileStatus
        var content: [String] = []
        var previousContent: [String] = []
    }

    private var files: [GitFile] = []
    private var fileSystemUI: SKNode?
    private var commitMessageText: String = ""

    // Tutorial system
    private enum TutorialStep {
        case dragPart
        case waitForModified
        case clickStage
        case waitForStaged
        case enterCommitMsg
        case clickCommit
        case completed
    }

    private var currentTutorialStep: TutorialStep = .dragPart
    private var tutorialUI: SKNode?
    private var isTutorialMode: Bool = false

    // TODO checklist system
    private enum TodoItem {
        case dragPart
        case stage
        case commitMessage
        case commit
    }

    private var currentTodos: [TodoItem] = []
    private var completedTodos: Set<TodoItem> = []
    private var todoUI: SKNode?
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - 🎨 NEW RESPONSIVE LAYOUT SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════
    
    // Panel proportions (percentage-based for flexibility)
    private var gitPanelWidth: CGFloat { floor(size.width * 0.30) }   // 30% - Git UI
    private var robotPanelWidth: CGFloat { floor(size.width * 0.38) } // 38% - Robot
    private var graphPanelWidth: CGFloat { size.width - gitPanelWidth - robotPanelWidth } // Rest
    
    // Fixed heights
    private let topBarH: CGFloat = 56
    private let terminalH: CGFloat = 100
    private let padding: CGFloat = 16
    private let sectionGap: CGFloat = 8
    
    // Compact element sizes
    private let sectionHeaderH: CGFloat = 24
    private let fileRowH: CGFloat = 26
    private let buttonH: CGFloat = 36
    private let inputH: CGFloat = 32
    
    // Panel centers
    private var gitPanelCenterX: CGFloat { gitPanelWidth / 2 }
    private var robotPanelCenterX: CGFloat { gitPanelWidth + robotPanelWidth / 2 }
    private var graphPanelCenterX: CGFloat { gitPanelWidth + robotPanelWidth + graphPanelWidth / 2 }
    
    // Collapsible sections state
    private var isWorkingDirExpanded: Bool = true
    private var isStagingExpanded: Bool = true
    private var isChecklistExpanded: Bool = false
    
    // Legacy aliases
    private var leftWidth: CGFloat { gitPanelWidth }
    
    // Calculated positions
    private var contentAreaTop: CGFloat { size.height - topBarH - 8 }
    private var contentAreaBottom: CGFloat { terminalH + 8 }
    private var contentAreaHeight: CGFloat { contentAreaTop - contentAreaBottom }
    
    // Sub-nodes
    private var robotNode = RobotNode()
    private var gitGraph = GitGraphNode()
    private var terminal: TerminalNode!
    private var assemblyZone = AssemblyZone()
    
    // UI elements
    private var branchBadge: SKNode!
    private var phaseCounter: SKLabelNode!
    private var progressBar: SKShapeNode!
    private var progressFill: SKShapeNode!
    private var explanationGroup: SKNode?
    private var goalIndicators: SKNode?
    private var gitWorkflowUI: SKNode?

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
        setupPanels()
        setupTerminal()
        setupFileSystem()
        initializeFileContents()

        showCurrentPhase()
    }

    private func setupFileSystem() {
        files = [
            GitFile(name: "머리.txt", partSlot: .head, status: .committed),
            GitFile(name: "몸통.txt", partSlot: .torso, status: .committed),
            GitFile(name: "왼팔.txt", partSlot: .leftArm, status: .committed),
            GitFile(name: "오른팔.txt", partSlot: .rightArm, status: .committed),
            GitFile(name: "다리.txt", partSlot: .legs, status: .committed),
            GitFile(name: "백팩.txt", partSlot: .backpack, status: .committed)
        ]
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - 🎨 CLEAN TOP BAR
    // ═══════════════════════════════════════════════════════════════════════════
    
    private func setupTopBar() {
        let barY = size.height - topBarH/2

        // Background
        let bar = SKShapeNode(rectOf: CGSize(width: size.width, height: topBarH))
        bar.fillColor = C.topBarBg
        bar.strokeColor = .clear
        bar.position = CGPoint(x: size.width/2, y: barY)
        bar.zPosition = 10
        addChild(bar)

        // Bottom separator line
        let divider = SKShapeNode(rectOf: CGSize(width: size.width, height: 1))
        divider.fillColor = C.border
        divider.strokeColor = .clear
        divider.position = CGPoint(x: size.width/2, y: size.height - topBarH)
        divider.zPosition = 10
        addChild(divider)

        // Back button
        let back = ButtonNode(text: "◀ 목록", width: 68, height: 28, color: C.buttonSecondary, fontSize: 11)
        back.position = CGPoint(x: 44, y: barY)
        back.zPosition = 11
        back.action = { [weak self] in self?.goToChapters() }
        addChild(back)

        // Vertical separator
        let sep = SKShapeNode(rectOf: CGSize(width: 1, height: 24))
        sep.fillColor = C.border
        sep.strokeColor = .clear
        sep.position = CGPoint(x: 84, y: barY)
        sep.zPosition = 11
        addChild(sep)

        // Mission title (left-aligned, starts at x=94)
        let title = makeLabel("M\(mission.id)  \(mission.title)", size: 13, color: C.text, bold: true)
        title.position = CGPoint(x: 94, y: barY)
        title.horizontalAlignmentMode = .left
        title.zPosition = 11
        addChild(title)

        // Phase counter — fixed safe position
        phaseCounter = makeLabel("  1 / \(mission.phases.count)", size: 11, color: C.textDim, mono: true)
        phaseCounter.position = CGPoint(x: 340, y: barY)
        phaseCounter.horizontalAlignmentMode = .left
        phaseCounter.zPosition = 11
        addChild(phaseCounter)

        // Right side: git tools → branch → stars
        setupGitToolbar()

        // Branch badge (positioned after toolbar, before stars)
        branchBadge = makeBadge(currentBranch, color: C.branchColor(currentBranch), fontSize: 10)
        branchBadge.position = CGPoint(x: size.width - 110, y: barY)
        branchBadge.zPosition = 11
        addChild(branchBadge)

        // Stars (far right)
        let stars = makeLabel("⭐\(GameData.shared.totalStars)", size: 12, color: C.yellow)
        stars.position = CGPoint(x: size.width - 28, y: barY)
        stars.zPosition = 11
        addChild(stars)
    }

    private func setupGitToolbar() {
        let toolbarY = size.height - topBarH/2
        let buttonW: CGFloat = 32
        let buttonH: CGFloat = 24
        let spacing: CGFloat = 5
        // 3 buttons × (32+5) = 111px; placed so last button ends well before branch badge
        let startX = size.width - 305

        let buttons: [(icon: String, action: Selector)] = [
            ("↓", #selector(handlePull)),
            ("↑", #selector(handlePush)),
            ("⎇", #selector(handleBranchUI)),
        ]

        for (index, button) in buttons.enumerated() {
            let x = startX + CGFloat(index) * (buttonW + spacing)

            let btn = SKShapeNode(rectOf: CGSize(width: buttonW, height: buttonH), cornerRadius: 5)
            btn.fillColor = C.buttonSecondary
            btn.strokeColor = C.border
            btn.lineWidth = 1
            btn.position = CGPoint(x: x, y: toolbarY)
            btn.name = "gitBtn_\(index)"
            btn.zPosition = 12
            addChild(btn)

            let icon = makeLabel(button.icon, size: 13, color: C.textDim)
            icon.position = CGPoint(x: x, y: toolbarY)
            icon.zPosition = 13
            addChild(icon)

            btn.userData = NSMutableDictionary()
            btn.userData?["action"] = button.action
            btn.userData?["enabled"] = true
        }
    }

    @objc private func handleUndo() {
        guard historyIndex > 0 else {
            showNotification("⚠️ Undo할 항목이 없습니다")
            return
        }
        historyIndex -= 1
        terminal.addCommand("git reset HEAD~1")
        showNotification("↶ Undo 완료")
    }

    @objc private func handleRedo() {
        guard historyIndex < gitHistory.count - 1 else {
            showNotification("⚠️ Redo할 항목이 없습니다")
            return
        }
        historyIndex += 1
        terminal.addCommand("git reset HEAD@{1}")
        showNotification("↷ Redo 완료")
    }

    @objc private func handlePull() {
        terminal.addCommand("git pull origin \(currentBranch)")
        showNotification("📥 Pull 완료")
    }

    @objc private func handlePush() {
        terminal.addCommand("git push origin \(currentBranch)")
        showNotification("📤 Push 완료")
    }

    @objc private func handleBranchUI() {
        showBranchCreationUI()
    }

    @objc private func handleStash() {
        guard currentGitState == .modified || currentGitState == .staged else {
            showNotification("⚠️ Stash할 변경사항이 없습니다")
            return
        }
        terminal.addCommand("git stash save \"WIP\"")
        currentGitState = .waiting
        stashedPart = RobotPart(id: "stashed", name: "임시저장", emoji: "📦", slot: .torso, portId: nil)
        showNotification("📥 Stash 완료")
    }

    @objc private func handlePop() {
        guard stashedPart != nil else {
            showNotification("⚠️ Stash된 항목이 없습니다")
            return
        }
        terminal.addCommand("git stash pop")
        currentGitState = .modified
        stashedPart = nil
        showNotification("📤 Pop 완료")
    }

    private func updateGitButton(_ name: String, enabled: Bool) {
        // No-op for simplified toolbar
    }

    private func showNotification(_ message: String) {
        let notification = SKNode()
        notification.zPosition = 100

        let bg = SKShapeNode(rectOf: CGSize(width: 420, height: 40), cornerRadius: 8)
        bg.fillColor = C.notificationBg
        bg.strokeColor = C.blue
        bg.lineWidth = 1
        bg.position = CGPoint(x: size.width / 2, y: size.height - topBarH - 58)
        notification.addChild(bg)

        let label = makeLabel(message, size: 13, color: C.text, bold: true)
        label.position = bg.position
        notification.addChild(label)

        addChild(notification)
        notification.run(.sequence([
            .wait(forDuration: 1.5),
            .fadeOut(withDuration: 0.2),
            .removeFromParent()
        ]))
    }

    private func showBranchCreationUI() {
        let group = SKNode()
        group.name = "branchCreationUI"
        group.zPosition = 50

        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = NSColor(white: 0, alpha: 0.7)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        group.addChild(overlay)

        let dialog = SKShapeNode(rectOf: CGSize(width: 320, height: 200), cornerRadius: 12)
        dialog.fillColor = C.dialogBg
        dialog.strokeColor = C.blue
        dialog.lineWidth = 2
        dialog.position = CGPoint(x: size.width / 2, y: size.height / 2)
        group.addChild(dialog)

        let title = makeLabel("🎋 새 브랜치", size: 16, color: C.blue, bold: true)
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 70)
        group.addChild(title)

        let branchOptions = ["feature/new", "bugfix/fix", "hotfix/urgent"]
        let startY = size.height / 2 + 25

        for (index, branchName) in branchOptions.enumerated() {
            let btn = ButtonNode(text: branchName, width: 200, height: 32, color: C.purple, fontSize: 12)
            btn.position = CGPoint(x: size.width / 2, y: startY - CGFloat(index) * 38)
            btn.action = { [weak self] in
                self?.createBranch(branchName)
                group.removeFromParent()
            }
            group.addChild(btn)
        }

        let cancelBtn = ButtonNode(text: "취소", width: 80, height: 28, color: C.buttonCancel, fontSize: 12)
        cancelBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 - 75)
        cancelBtn.action = { group.removeFromParent() }
        group.addChild(cancelBtn)

        addChild(group)
    }

    private func createBranch(_ branchName: String) {
        if !activeBranches.contains(branchName) {
            activeBranches.append(branchName)
        }
        currentBranch = branchName
        terminal.addCommand("git checkout -b \(branchName)")
        showNotification("🎋 브랜치: \(branchName)")

        branchBadge.removeFromParent()
        branchBadge = makeBadge(branchName, color: C.branchColor(branchName), fontSize: 10)
        branchBadge.position = CGPoint(x: size.width - 110, y: size.height - topBarH/2)
        branchBadge.zPosition = 11
        addChild(branchBadge)
    }

    private func setupProgressBar() {
        let y = size.height - topBarH - 2
        progressBar = SKShapeNode(rectOf: CGSize(width: size.width, height: 2))
        progressBar.fillColor = C.progressBg
        progressBar.strokeColor = .clear
        progressBar.position = CGPoint(x: size.width/2, y: y)
        progressBar.zPosition = 10
        addChild(progressBar)
        
        progressFill = SKShapeNode(rectOf: CGSize(width: 0, height: 2))
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
        progressFill = SKShapeNode(rectOf: CGSize(width: w, height: 2))
        progressFill.fillColor = C.green
        progressFill.strokeColor = .clear
        progressFill.position = CGPoint(x: w/2, y: size.height - topBarH - 2)
        progressFill.zPosition = 11
        addChild(progressFill)
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - 🎨 CLEAN 3-PANEL LAYOUT
    // ═══════════════════════════════════════════════════════════════════════════
    
    private func setupPanels() {
        let panelTop = size.height - topBarH - 6
        let panelBottom = terminalH + 6
        let panelHeight = panelTop - panelBottom
        let midY = (panelTop + panelBottom) / 2

        // ── LEFT PANEL: Git Status ──
        let gitBg = SKShapeNode(rectOf: CGSize(width: gitPanelWidth - 8, height: panelHeight), cornerRadius: 10)
        gitBg.fillColor = C.panelBg
        gitBg.strokeColor = C.border
        gitBg.lineWidth = 1
        gitBg.position = CGPoint(x: gitPanelCenterX, y: midY)
        addChild(gitBg)

        // Left panel top accent strip
        let gitAccent = SKShapeNode(rectOf: CGSize(width: gitPanelWidth - 8, height: 28), cornerRadius: 5)
        gitAccent.fillColor = C.blue.withAlphaComponent(0.08)
        gitAccent.strokeColor = .clear
        gitAccent.position = CGPoint(x: gitPanelCenterX, y: panelTop - 14)
        addChild(gitAccent)

        let gitTitle = makeLabel("📂  GIT STATUS", size: 10, color: C.blue, bold: true, mono: true)
        gitTitle.position = CGPoint(x: gitPanelCenterX, y: panelTop - 14)
        addChild(gitTitle)

        // Vertical divider 1
        let div1 = SKShapeNode(rectOf: CGSize(width: 1, height: panelHeight - 12))
        div1.fillColor = C.border
        div1.strokeColor = .clear
        div1.position = CGPoint(x: gitPanelWidth + 0.5, y: midY)
        addChild(div1)

        // ── CENTER PANEL: Robot Assembly ──
        let robotBg = SKShapeNode(rectOf: CGSize(width: robotPanelWidth - 8, height: panelHeight), cornerRadius: 10)
        robotBg.fillColor = C.panelBg
        robotBg.strokeColor = C.border
        robotBg.lineWidth = 1
        robotBg.position = CGPoint(x: robotPanelCenterX, y: midY)
        addChild(robotBg)

        let robotAccent = SKShapeNode(rectOf: CGSize(width: robotPanelWidth - 8, height: 28), cornerRadius: 5)
        robotAccent.fillColor = C.green.withAlphaComponent(0.07)
        robotAccent.strokeColor = .clear
        robotAccent.position = CGPoint(x: robotPanelCenterX, y: panelTop - 14)
        addChild(robotAccent)

        let robotTitle = makeLabel("🤖  ROBOT ASSEMBLY", size: 10, color: C.green, bold: true, mono: true)
        robotTitle.position = CGPoint(x: robotPanelCenterX, y: panelTop - 14)
        addChild(robotTitle)

        // Center divider (horizontal) between robot and assembly zone
        let robotDivY = midY + panelHeight * 0.07
        let centerDiv = SKShapeNode(rectOf: CGSize(width: robotPanelWidth - 32, height: 1))
        centerDiv.fillColor = C.border
        centerDiv.strokeColor = .clear
        centerDiv.position = CGPoint(x: robotPanelCenterX, y: robotDivY)
        addChild(centerDiv)

        // Robot node - upper area
        let robotY = midY + panelHeight * 0.28
        robotNode.position = CGPoint(x: robotPanelCenterX, y: robotY)
        addChild(robotNode)

        // Assembly zone - lower area
        let assemblyY = midY - panelHeight * 0.23
        assemblyZone.position = CGPoint(x: robotPanelCenterX, y: assemblyY)
        addChild(assemblyZone)

        // Wire up callbacks
        assemblyZone.onPartSelected = { [weak self] part in self?.handlePartSelected(part) }
        assemblyZone.onWorkstationOpened = { [weak self] name in self?.handleWorkstationOpened(name) }
        assemblyZone.onMerge = { [weak self] from, to in self?.handleMerge(from, to) }
        assemblyZone.onConflictResolved = { [weak self] in self?.handleConflictResolved() }
        assemblyZone.onTagged = { [weak self] ver in self?.handleTagged(ver) }
        assemblyZone.onShipped = { [weak self] in self?.handleShipped() }
        assemblyZone.onCleanup = { [weak self] name in self?.handleCleanup(name) }
        assemblyZone.onEmergencyFix = { [weak self] part in self?.handleEmergencyFix(part) }

        // Vertical divider 2
        let div2 = SKShapeNode(rectOf: CGSize(width: 1, height: panelHeight - 12))
        div2.fillColor = C.border
        div2.strokeColor = .clear
        div2.position = CGPoint(x: gitPanelWidth + robotPanelWidth + 0.5, y: midY)
        addChild(div2)

        // ── RIGHT PANEL: Git Graph ──
        let graphBg = SKShapeNode(rectOf: CGSize(width: graphPanelWidth - 8, height: panelHeight), cornerRadius: 10)
        graphBg.fillColor = C.panelBg
        graphBg.strokeColor = C.border
        graphBg.lineWidth = 1
        graphBg.position = CGPoint(x: graphPanelCenterX, y: midY)
        addChild(graphBg)

        let graphAccent = SKShapeNode(rectOf: CGSize(width: graphPanelWidth - 8, height: 28), cornerRadius: 5)
        graphAccent.fillColor = C.purple.withAlphaComponent(0.07)
        graphAccent.strokeColor = .clear
        graphAccent.position = CGPoint(x: graphPanelCenterX, y: panelTop - 14)
        addChild(graphAccent)

        let graphTitle = makeLabel("🌿  GIT GRAPH", size: 10, color: C.purple, bold: true, mono: true)
        graphTitle.position = CGPoint(x: graphPanelCenterX, y: panelTop - 14)
        addChild(graphTitle)

        gitGraph.position = CGPoint(x: gitPanelWidth + robotPanelWidth + 16, y: panelTop - 44)
        addChild(gitGraph)
    }
    
    private func setupTerminal() {
        terminal = TerminalNode(width: size.width - 24)
        terminal.position = CGPoint(x: size.width / 2, y: terminalH / 2 + 4)
        addChild(terminal)
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - Phase Management
    // ═══════════════════════════════════════════════════════════════════════════
    
    private func showCurrentPhase() {
        guard phaseIndex < mission.phases.count else { return }
        let phase = mission.phases[phaseIndex]

        isTutorialMode = (missionId == 1)
        if isTutorialMode {
            currentTutorialStep = .dragPart
        }

        phaseCounter.text = "  \(phaseIndex + 1) / \(mission.phases.count)"
        updateProgress()
        updateBranchBadge(phase.branchContext)
        
        childNode(withName: "missionHeader")?.removeFromParent()
        
        actionDone = false
        currentGitState = .waiting
        assemblyZone.correctPart = currentExpectedPart
        assemblyZone.showAction(phase.assemblyAction)

        explanationGroup?.removeFromParent()
        explanationGroup = nil
        goalIndicators?.removeFromParent()
        goalIndicators = nil
        gitWorkflowUI?.removeFromParent()
        gitWorkflowUI = nil

        initializeTodos(for: phase)
        showFileSystemUI()
        showGoalIndicators(for: phase)

        if isTutorialMode {
            showTutorialStep()
        }
    }
    
    private func getGoalText(for phase: MissionPhase) -> String {
        switch phase.assemblyAction {
        case .pickPart(let parts):
            if let firstPart = parts.first {
                return "\(firstPart.slot.label)에 \(firstPart.name) 장착"
            }
            return "부품 선택"
        case .installPart(let part):
            return "\(part.slot.label)에 \(part.name) 장착"
        case .openWorkstation(let name):
            return "\(name) 워크스테이션 개설"
        case .mergeParts(let from, let to):
            return "\(from) → \(to) 병합"
        case .resolveConflict(_, _):
            return "충돌 해결"
        case .tagVersion(let version):
            return "\(version) 태그"
        case .shipRobot:
            return "로봇 출하"
        case .cleanupLine(let name):
            return "\(name) 정리"
        case .emergencyFix(let part):
            return "긴급: \(part.name)"
        }
    }
    
    private func updateBranchBadge(_ context: String) {
        branchBadge.removeFromParent()
        let branchName = context.components(separatedBy: " ").last ?? currentBranch
        branchBadge = makeBadge(branchName, color: C.branchColor(branchName), fontSize: 10)
        branchBadge.position = CGPoint(x: size.width - 110, y: size.height - topBarH/2)
        branchBadge.zPosition = 11
        addChild(branchBadge)
    }
    
    private func completePhaseAction() {
        guard !actionDone, phaseIndex < mission.phases.count else { return }
        actionDone = true
        let phase = mission.phases[phaseIndex]
        
        terminal.addCommand(phase.gitCommand)
        
        let branchName = phase.branchContext.components(separatedBy: " ").last ?? currentBranch
        let nodeType: String
        switch phase.assemblyAction {
        case .mergeParts, .shipRobot: nodeType = "merge"
        case .openWorkstation: nodeType = "branch"
        case .tagVersion: nodeType = "tag"
        case .resolveConflict: nodeType = "conflict"
        default: nodeType = "commit"
        }
        gitGraph.addEntry(branch: branchName, label: String(phase.instruction.prefix(25)), type: nodeType)
        
        assemblyZone.clearCurrent()
        showExplanation(phase)
    }
    
    private func showExplanation(_ phase: MissionPhase) {
        let group = SKNode()
        group.name = "explanation"
        group.zPosition = 50
        
        // Centered modal
        let modalW: CGFloat = 380
        let modalH: CGFloat = 180
        let cx = size.width / 2
        let cy = size.height / 2
        
        // Dark overlay
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = NSColor(white: 0, alpha: 0.6)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: cx, y: cy)
        group.addChild(overlay)
        
        let bg = SKShapeNode(rectOf: CGSize(width: modalW, height: modalH), cornerRadius: 12)
        bg.fillColor = C.explanationBg
        bg.strokeColor = C.yellow.withAlphaComponent(0.4)
        bg.lineWidth = 1
        bg.position = CGPoint(x: cx, y: cy)
        group.addChild(bg)
        
        let bulb = makeLabel("💡 Git 개념", size: 14, color: C.yellow, bold: true)
        bulb.position = CGPoint(x: cx, y: cy + 60)
        group.addChild(bulb)

        let exp = SKLabelNode(text: phase.explanation)
        exp.fontName = "Helvetica"
        exp.fontSize = 13
        exp.fontColor = C.text
        exp.verticalAlignmentMode = .center
        exp.horizontalAlignmentMode = .center
        exp.preferredMaxLayoutWidth = modalW - 40
        exp.numberOfLines = 0
        exp.position = CGPoint(x: cx, y: cy + 20)
        group.addChild(exp)

        // Git command
        let cmdBg = SKShapeNode(rectOf: CGSize(width: modalW - 40, height: 24), cornerRadius: 5)
        cmdBg.fillColor = C.terminalBg
        cmdBg.strokeColor = .clear
        cmdBg.position = CGPoint(x: cx, y: cy - 20)
        group.addChild(cmdBg)

        let cmdText = makeLabel(phase.gitCommand.components(separatedBy: "\n").first ?? phase.gitCommand,
                                size: 11, color: C.green, bold: true, mono: true)
        cmdText.position = cmdBg.position
        group.addChild(cmdText)

        let nextBtn = ButtonNode(text: "확인 →", width: 120, height: 32, color: C.green, fontSize: 13)
        nextBtn.position = CGPoint(x: cx, y: cy - 60)
        nextBtn.zPosition = 51
        nextBtn.action = { [weak self] in self?.advancePhase() }
        group.addChild(nextBtn)
        
        group.alpha = 0
        group.run(.fadeIn(withDuration: 0.2))
        
        addChild(group)
        explanationGroup = group
    }
    
    private func advancePhase() {
        cleanupDrag()
        explanationGroup?.run(.sequence([.fadeOut(withDuration: 0.1), .removeFromParent()]))
        explanationGroup = nil
        childNode(withName: "instructionBg")?.removeFromParent()
        childNode(withName: "instructionPrefix")?.removeFromParent()
        goalIndicators?.removeFromParent()
        goalIndicators = nil

        phaseIndex += 1

        if phaseIndex >= mission.phases.count {
            showReward()
        } else {
            showCurrentPhase()
        }
    }

    // MARK: - Goal Indicators

    private func showGoalIndicators(for phase: MissionPhase) {
        let group = SKNode()
        group.name = "goalIndicators"
        group.zPosition = 15

        switch phase.assemblyAction {
        case .pickPart(let parts):
            if let firstPart = parts.first {
                highlightTargetSlot(firstPart.slot, in: group)
            }
        case .installPart(let part):
            highlightTargetSlot(part.slot, in: group)
        case .emergencyFix(let part):
            highlightTargetSlot(part.slot, in: group)
        default:
            break
        }

        if group.children.isEmpty { return }

        addChild(group)
        goalIndicators = group
        group.alpha = 0
        group.run(.fadeIn(withDuration: 0.25))
    }

    private func highlightTargetSlot(_ slot: PartSlot, in group: SKNode) {
        guard let slotNode = robotNode.slots[slot] else { return }
        let slotPosition = robotNode.convert(slotNode.position, to: self)

        let size = slot == .torso ? CGSize(width: 55, height: 55) : CGSize(width: 48, height: 48)
        let highlight = SKShapeNode(rectOf: size, cornerRadius: 8)
        highlight.fillColor = .clear
        highlight.strokeColor = C.yellow.withAlphaComponent(0.8)
        highlight.lineWidth = 2
        highlight.glowWidth = 4
        highlight.position = slotPosition

        let pulse = SKAction.sequence([
            .group([.scale(to: 1.1, duration: 0.5), .fadeAlpha(to: 0.5, duration: 0.5)]),
            .group([.scale(to: 1.0, duration: 0.5), .fadeAlpha(to: 1.0, duration: 0.5)])
        ])
        highlight.run(.repeatForever(pulse))
        group.addChild(highlight)
    }

    // MARK: - Tutorial System

    private func showTutorialStep() {
        tutorialUI?.removeFromParent()
        tutorialUI = nil

        let group = SKNode()
        group.name = "tutorial"
        group.zPosition = 100

        let message: String
        switch currentTutorialStep {
        case .dragPart:
            message = "1️⃣ 부품을 드래그 → 로봇 슬롯에 드롭"
        case .waitForModified:
            message = "2️⃣ 변경사항 발생! 파일 상태 확인"
        case .clickStage:
            message = "3️⃣ [↑] 버튼으로 Stage"
        case .waitForStaged:
            message = "4️⃣ Staging Area 확인"
        case .enterCommitMsg:
            message = "5️⃣ 커밋 메시지 입력"
        case .clickCommit:
            message = "6️⃣ Commit 실행!"
        case .completed:
            return
        }

        // Compact tutorial banner at top
        let bannerH: CGFloat = 36
        let bannerY = size.height - topBarH - 25
        
        let bg = SKShapeNode(rectOf: CGSize(width: 340, height: bannerH), cornerRadius: 8)
        bg.fillColor = C.branchDialogBg
        bg.strokeColor = C.yellow
        bg.lineWidth = 1
        bg.position = CGPoint(x: size.width / 2, y: bannerY)
        group.addChild(bg)

        let label = makeLabel(message, size: 12, color: C.yellow, bold: true)
        label.position = CGPoint(x: size.width / 2, y: bannerY)
        group.addChild(label)

        addChild(group)
        tutorialUI = group
    }

    private func hideTutorial() {
        tutorialUI?.run(.sequence([.fadeOut(withDuration: 0.15), .removeFromParent()]))
        tutorialUI = nil
    }

    private func advanceTutorial() {
        switch currentTutorialStep {
        case .dragPart: currentTutorialStep = .waitForModified
        case .waitForModified: currentTutorialStep = .clickStage
        case .clickStage: currentTutorialStep = .waitForStaged
        case .waitForStaged: currentTutorialStep = .enterCommitMsg
        case .enterCommitMsg: currentTutorialStep = .clickCommit
        case .clickCommit:
            currentTutorialStep = .completed
            hideTutorial()
            return
        case .completed: return
        }
        showTutorialStep()
    }

    // MARK: - TODO Checklist

    private func initializeTodos(for phase: MissionPhase) {
        currentTodos = []
        completedTodos = []
        switch phase.assemblyAction {
        case .pickPart, .installPart, .emergencyFix:
            currentTodos = [.dragPart, .stage, .commitMessage, .commit]
        default:
            currentTodos = []
        }
    }

    private func getTodoText(for item: TodoItem) -> String {
        switch item {
        case .dragPart: return "부품 드롭"
        case .stage: return "Stage"
        case .commitMessage: return "메시지"
        case .commit: return "Commit"
        }
    }

    private func completeTodo(_ item: TodoItem) {
        guard currentTodos.contains(item) else { return }
        completedTodos.insert(item)
        showFileSystemUI()
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK: - 🎨 CLEAN FILE SYSTEM UI (Left Panel)
    // ═══════════════════════════════════════════════════════════════════════════

    private func showFileSystemUI() {
        fileSystemUI?.removeFromParent()
        fileSystemUI = nil

        let group = SKNode()
        group.name = "fileSystem"
        group.zPosition = 8

        let panelW = gitPanelWidth
        let cx = gitPanelCenterX
        let innerW = panelW - padding * 2
        let leftX: CGFloat = padding + 4
        let rightX: CGFloat = panelW - padding - 4

        // Content starts below the panel title accent strip (28px) + gap
        var y = size.height - topBarH - 44

        // ── GOAL CARD ──
        if phaseIndex < mission.phases.count {
            let phase = mission.phases[phaseIndex]
            let goalText = getGoalText(for: phase)

            let goalCard = SKShapeNode(rectOf: CGSize(width: innerW, height: 36), cornerRadius: 7)
            goalCard.fillColor = C.yellow.withAlphaComponent(0.10)
            goalCard.strokeColor = C.yellow.withAlphaComponent(0.40)
            goalCard.lineWidth = 1
            goalCard.position = CGPoint(x: cx, y: y - 18)
            group.addChild(goalCard)

            // Left accent bar on goal card
            let accentBar = SKShapeNode(rectOf: CGSize(width: 3, height: 28), cornerRadius: 2)
            accentBar.fillColor = C.yellow
            accentBar.strokeColor = .clear
            accentBar.position = CGPoint(x: cx - innerW/2 + 6, y: y - 18)
            group.addChild(accentBar)

            let goalLabel = makeLabel("🎯  \(goalText)", size: 11, color: C.yellow, bold: true)
            goalLabel.position = CGPoint(x: cx + 4, y: y - 18)
            group.addChild(goalLabel)

            y -= 46
        }

        // ── WORKING DIRECTORY SECTION ──
        let modifiedFiles = files.filter { $0.status == .modified || $0.status == .untracked }
        y = addCollapsibleSection(
            to: group, title: "Working Dir", icon: "📂", color: C.orange,
            isExpanded: isWorkingDirExpanded, toggleName: "toggleWorkingDir",
            files: modifiedFiles, isStaged: false, emptyText: "✓ clean",
            y: y, panelW: panelW
        )

        y -= sectionGap

        // ── STAGING AREA SECTION ──
        let stagedFiles = files.filter { $0.status == .staged }
        y = addCollapsibleSection(
            to: group, title: "Staging", icon: "📦", color: C.green,
            isExpanded: isStagingExpanded, toggleName: "toggleStaging",
            files: stagedFiles, isStaged: true, emptyText: "→ 없음",
            y: y, panelW: panelW
        )

        y -= sectionGap + 2

        // ── COMMIT SECTION ──
        let commitCard = SKShapeNode(rectOf: CGSize(width: innerW, height: sectionHeaderH), cornerRadius: 6)
        commitCard.fillColor = C.blue.withAlphaComponent(0.08)
        commitCard.strokeColor = C.blue.withAlphaComponent(0.25)
        commitCard.lineWidth = 1
        commitCard.position = CGPoint(x: cx, y: y - sectionHeaderH/2)
        group.addChild(commitCard)

        let commitAccent = SKShapeNode(rectOf: CGSize(width: 3, height: sectionHeaderH - 8), cornerRadius: 2)
        commitAccent.fillColor = C.blue
        commitAccent.strokeColor = .clear
        commitAccent.position = CGPoint(x: cx - innerW/2 + 6, y: y - sectionHeaderH/2)
        group.addChild(commitAccent)

        let commitTitle = makeLabel("💾  Commit", size: 11, color: C.blue, bold: true, mono: true)
        commitTitle.position = CGPoint(x: cx + 4, y: y - sectionHeaderH/2)
        group.addChild(commitTitle)

        y -= sectionHeaderH + 6

        // Commit message input + commit button row
        let inputW = innerW - 56
        let msgBg = SKShapeNode(rectOf: CGSize(width: inputW, height: inputH), cornerRadius: 6)
        msgBg.fillColor = C.commitInputBg
        msgBg.strokeColor = stagedFiles.isEmpty ? C.border : C.blue
        msgBg.lineWidth = stagedFiles.isEmpty ? 1 : 1.5
        msgBg.position = CGPoint(x: leftX + inputW/2, y: y - inputH/2)
        msgBg.name = "commitMsgBg"
        group.addChild(msgBg)

        let msgText = commitMessageText.isEmpty ? "커밋 메시지..." : commitMessageText
        let msgLabel = makeLabel(msgText, size: 10, color: commitMessageText.isEmpty ? C.textFaint : C.text, mono: true)
        msgLabel.position = msgBg.position
        group.addChild(msgLabel)

        let commitBtn = ButtonNode(
            text: "✓",
            width: 44, height: inputH,
            color: stagedFiles.isEmpty ? C.buttonSecondary.withAlphaComponent(0.5) : C.green,
            fontSize: 15
        )
        commitBtn.position = CGPoint(x: rightX - 22, y: y - inputH/2)
        commitBtn.name = "commitButton"
        if !stagedFiles.isEmpty {
            commitBtn.action = { [weak self] in self?.performCommit() }
        }
        group.addChild(commitBtn)

        y -= inputH + sectionGap

        // ── TODO CHECKLIST ──
        if !currentTodos.isEmpty {
            y = addChecklistSection(to: group, y: y, panelW: panelW)
        }

        addChild(group)
        fileSystemUI = group

        if isTutorialMode {
            if currentTutorialStep == .waitForModified && !modifiedFiles.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    self?.advanceTutorial()
                }
            }
            if currentTutorialStep == .waitForStaged && !stagedFiles.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    self?.advanceTutorial()
                }
            }
        }
    }
    
    private func addCollapsibleSection(
        to group: SKNode,
        title: String,
        icon: String,
        color: NSColor,
        isExpanded: Bool,
        toggleName: String,
        files: [GitFile],
        isStaged: Bool,
        emptyText: String,
        y: CGFloat,
        panelW: CGFloat
    ) -> CGFloat {
        var currentY = y
        let cx = panelW / 2
        let innerW = panelW - padding * 2
        let leftX: CGFloat = padding + 4

        // Section header card
        let headerCard = SKShapeNode(rectOf: CGSize(width: innerW, height: sectionHeaderH), cornerRadius: 6)
        headerCard.fillColor = color.withAlphaComponent(0.08)
        headerCard.strokeColor = color.withAlphaComponent(0.22)
        headerCard.lineWidth = 1
        headerCard.position = CGPoint(x: cx, y: currentY - sectionHeaderH/2)
        headerCard.name = toggleName
        group.addChild(headerCard)

        // Left accent bar
        let accentBar = SKShapeNode(rectOf: CGSize(width: 3, height: sectionHeaderH - 8), cornerRadius: 2)
        accentBar.fillColor = color
        accentBar.strokeColor = .clear
        accentBar.position = CGPoint(x: cx - innerW/2 + 6, y: currentY - sectionHeaderH/2)
        group.addChild(accentBar)

        let arrow = isExpanded ? "▾" : "▸"
        let count = files.isEmpty ? "" : " \(files.count)"
        let headerLabel = makeLabel("\(arrow) \(icon)  \(title)\(count)", size: 11, color: color, bold: true, mono: true)
        headerLabel.position = CGPoint(x: cx + 4, y: currentY - sectionHeaderH/2)
        headerLabel.name = "\(toggleName)_label"
        group.addChild(headerLabel)

        currentY -= sectionHeaderH + 4

        if isExpanded {
            if files.isEmpty {
                let emptyLabel = makeLabel(emptyText, size: 10, color: emptyText.contains("✓") ? C.green : C.textFaint)
                emptyLabel.horizontalAlignmentMode = .left
                emptyLabel.position = CGPoint(x: leftX + 14, y: currentY - 12)
                group.addChild(emptyLabel)
                currentY -= 24
            } else {
                for file in files {
                    let fileNode = createCompactFileRow(file: file, x: leftX, y: currentY - fileRowH/2, isStaged: isStaged, panelW: panelW)
                    group.addChild(fileNode)
                    currentY -= fileRowH
                }
            }
        }

        return currentY
    }
    
    private func createCompactFileRow(file: GitFile, x: CGFloat, y: CGFloat, isStaged: Bool, panelW: CGFloat) -> SKNode {
        let row = SKNode()

        // Row background (subtle)
        let rowBg = SKShapeNode(rectOf: CGSize(width: panelW - padding * 2 - 4, height: fileRowH - 2), cornerRadius: 4)
        rowBg.fillColor = C.bg.withAlphaComponent(0.5)
        rowBg.strokeColor = .clear
        rowBg.position = CGPoint(x: x + (panelW - padding * 2 - 4)/2, y: y)
        row.addChild(rowBg)

        // Status badge
        let (statusText, statusColor): (String, NSColor) = {
            switch file.status {
            case .modified:  return ("M", C.orange)
            case .staged:    return ("S", C.green)
            case .untracked: return ("U", C.purple)
            default:         return ("", C.textFaint)
            }
        }()

        if !statusText.isEmpty {
            let badge = SKShapeNode(rectOf: CGSize(width: 16, height: 15), cornerRadius: 3)
            badge.fillColor = statusColor.withAlphaComponent(0.18)
            badge.strokeColor = statusColor.withAlphaComponent(0.5)
            badge.lineWidth = 1
            badge.position = CGPoint(x: x + 10, y: y)
            row.addChild(badge)

            let statusLabel = makeLabel(statusText, size: 9, color: statusColor, bold: true, mono: true)
            statusLabel.position = badge.position
            row.addChild(statusLabel)
        }

        // File name
        let maxNameLen = 9
        let displayName = file.name.count > maxNameLen ? String(file.name.prefix(maxNameLen)) + "…" : file.name
        let fileName = makeLabel(displayName, size: 10, color: C.text, mono: true)
        fileName.horizontalAlignmentMode = .left
        fileName.position = CGPoint(x: x + 24, y: y)
        row.addChild(fileName)

        // Stage/Unstage button
        let btnText = isStaged ? "↓" : "↑"
        let btnColor = isStaged ? C.orange : C.green

        let btn = SKShapeNode(rectOf: CGSize(width: 22, height: 18), cornerRadius: 4)
        btn.fillColor = btnColor.withAlphaComponent(0.15)
        btn.strokeColor = btnColor.withAlphaComponent(0.6)
        btn.lineWidth = 1
        btn.position = CGPoint(x: panelW - padding - 14, y: y)
        btn.name = "stageBtn_\(file.name)"
        btn.userData = NSMutableDictionary()
        btn.userData?["fileName"] = file.name
        btn.userData?["isStaged"] = isStaged

        if !isStaged {
            btn.glowWidth = 2
        }
        row.addChild(btn)

        let btnLabel = makeLabel(btnText, size: 12, color: btnColor, bold: true)
        btnLabel.position = btn.position
        row.addChild(btnLabel)

        return row
    }
    
    private func addChecklistSection(to group: SKNode, y: CGFloat, panelW: CGFloat) -> CGFloat {
        var currentY = y
        let cx = panelW / 2
        let leftX: CGFloat = padding + 4
        
        // Header
        let arrow = isChecklistExpanded ? "▼" : "▶"
        let completed = completedTodos.count
        let total = currentTodos.count
        
        let headerBg = SKShapeNode(rectOf: CGSize(width: panelW - padding * 2, height: sectionHeaderH), cornerRadius: 5)
        headerBg.fillColor = C.purple.withAlphaComponent(0.1)
        headerBg.strokeColor = .clear
        headerBg.position = CGPoint(x: cx, y: currentY - sectionHeaderH/2)
        headerBg.name = "toggleChecklist"
        group.addChild(headerBg)

        let headerLabel = makeLabel("\(arrow) 📋 진행 \(completed)/\(total)", size: 11, color: C.purple, bold: true, mono: true)
        headerLabel.position = CGPoint(x: cx, y: currentY - sectionHeaderH/2)
        group.addChild(headerLabel)
        
        currentY -= sectionHeaderH + 4
        
        if isChecklistExpanded {
            for todo in currentTodos {
                let isCompleted = completedTodos.contains(todo)
                let checkbox = isCompleted ? "✓" : "○"
                let todoText = getTodoText(for: todo)
                let color = isCompleted ? C.green : C.textDim
                
                let label = makeLabel("\(checkbox) \(todoText)", size: 10, color: color, mono: true)
                label.horizontalAlignmentMode = .left
                label.position = CGPoint(x: leftX + 8, y: currentY - 10)
                group.addChild(label)
                currentY -= 18
            }
        }
        
        return currentY
    }

    private func performCommit() {
        let stagedFiles = files.filter { $0.status == .staged }
        guard !stagedFiles.isEmpty else { return }

        for index in files.indices {
            if files[index].status == .staged {
                files[index].status = .committed
                files[index].previousContent = files[index].content
            }
        }

        let message = commitMessageText.isEmpty ? "업데이트" : commitMessageText
        commitMessageText = ""

        terminal.addCommand("git commit -m \"\(message)\"")
        gitGraph.addEntry(branch: currentBranch, label: message, type: "commit")

        let entry = GitHistoryEntry(part: nil, action: "commit", branchName: currentBranch)
        if historyIndex < gitHistory.count - 1 {
            gitHistory = Array(gitHistory[0...historyIndex])
        }
        gitHistory.append(entry)
        historyIndex = gitHistory.count - 1

        currentGitState = .committed
        showFileSystemUI()
        showNotification("✅ 커밋 완료")

        completeTodo(.commit)

        if isTutorialMode && currentTutorialStep == .clickCommit {
            advanceTutorial()
        }

        if !actionDone {
            actionDone = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.completePhaseWithExplanation()
            }
        }
    }

    private func completePhaseWithExplanation() {
        guard phaseIndex < mission.phases.count else { return }
        let phase = mission.phases[phaseIndex]
        showExplanation(phase)
    }

    // MARK: - Git Workflow UI (Simplified - now handled by File System UI)

    private func showGitWorkflowUI() {
        // Git workflow is now integrated into showFileSystemUI()
        showFileSystemUI()
    }

    private func handleStage() {
        currentGitState = .staged
        terminal.addCommand("git add .")
        showFileSystemUI()
    }

    private func handleCommit() {
        currentGitState = .committed

        let entry = GitHistoryEntry(part: nil, action: "commit", branchName: currentBranch)
        if historyIndex < gitHistory.count - 1 {
            gitHistory = Array(gitHistory[0...historyIndex])
        }
        gitHistory.append(entry)
        historyIndex = gitHistory.count - 1

        gitWorkflowUI?.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
        gitWorkflowUI = nil

        completePhaseAction()
    }

    // MARK: - Reward
    
    private func showReward() {
        let data = GameData.shared
        data.completedMissions.insert(missionId)
        data.totalStars += mission.stars
        data.collectedRobots.append((emoji: mission.rewardEmoji, name: mission.rewardName))

        assemblyZone.clearCurrent()
        childNode(withName: "instructionBg")?.removeFromParent()
        childNode(withName: "missionHeader")?.removeFromParent()
        
        let group = SKNode()
        group.zPosition = 50
        let cx = size.width / 2
        let cy = size.height / 2
        
        // Overlay
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = NSColor(white: 0, alpha: 0.7)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: cx, y: cy)
        group.addChild(overlay)
        
        // Reward panel
        let panelW: CGFloat = 340
        let panelH: CGFloat = 280
        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 12)
        panel.fillColor = C.completionBg
        panel.strokeColor = C.green.withAlphaComponent(0.5)
        panel.lineWidth = 2
        panel.position = CGPoint(x: cx, y: cy)
        group.addChild(panel)
        
        // Robot emoji
        let emoji = makeEmoji(mission.rewardEmoji, size: 56)
        emoji.position = CGPoint(x: cx, y: cy + 80)
        emoji.setScale(0.2)
        emoji.run(.sequence([.scale(to: 1.15, duration: 0.15), .scale(to: 1.0, duration: 0.1)]))
        group.addChild(emoji)
        
        // Name
        let name = makeLabel(mission.rewardName, size: 14, color: C.textDim, bold: true)
        name.position = CGPoint(x: cx, y: cy + 40)
        group.addChild(name)

        // Stars
        for i in 0..<mission.stars {
            let star = SKLabelNode(text: "★")
            star.fontSize = 22
            star.fontColor = C.yellow
            star.verticalAlignmentMode = .center
            star.position = CGPoint(x: cx + CGFloat(i - mission.stars/2) * 24, y: cy + 10)
            star.setScale(0)
            star.run(.sequence([
                .wait(forDuration: 0.2 + Double(i) * 0.12),
                .scale(to: 1.15, duration: 0.12),
                .scale(to: 1.0, duration: 0.08)
            ]))
            group.addChild(star)
        }

        let complete = makeLabel("미션 완료! 🎉", size: 18, color: C.green, bold: true)
        complete.position = CGPoint(x: cx, y: cy - 25)
        group.addChild(complete)

        // Lesson
        let lesson = SKLabelNode(text: mission.gitLesson)
        lesson.fontName = "Helvetica"
        lesson.fontSize = 11
        lesson.fontColor = C.textDim
        lesson.preferredMaxLayoutWidth = panelW - 40
        lesson.numberOfLines = 0
        lesson.verticalAlignmentMode = .center
        lesson.position = CGPoint(x: cx, y: cy - 65)
        group.addChild(lesson)
        
        // Next button
        let isLast = missionId >= GameData.missions.count
        let nextBtn = ButtonNode(text: isLast ? "🏆 결과" : "다음 →", width: 120, height: 36, color: C.green, fontSize: 13)
        nextBtn.position = CGPoint(x: cx, y: cy - 110)
        nextBtn.zPosition = 51
        nextBtn.action = { [weak self] in
            if isLast { self?.goToComplete() }
            else { self?.goToNextMission() }
        }
        group.addChild(nextBtn)
        
        addChild(group)
    }
    
    // MARK: - Part Validation

    /// 현재 페이즈에서 기대하는 정답 부품
    private var currentExpectedPart: RobotPart? {
        guard phaseIndex < mission.phases.count else { return nil }
        switch mission.phases[phaseIndex].assemblyAction {
        case .pickPart(let parts):   return parts.first
        case .installPart(let part): return part
        case .emergencyFix(let part): return part
        default: return nil
        }
    }

    private func isCorrectPart(_ part: RobotPart) -> Bool {
        guard let expected = currentExpectedPart else { return true }
        return part.id == expected.id
    }

    private func showWrongPartFeedback(for wrong: RobotPart) {
        guard let expected = currentExpectedPart else { return }
        showErrorNotification("❌ '\(wrong.name)'이(가) 아닙니다! '\(expected.name)' 을(를) 장착하세요")

        // Shake the goal highlight to draw attention
        goalIndicators?.run(.sequence([
            .moveBy(x: -7, y: 0, duration: 0.05),
            .moveBy(x: 14, y: 0, duration: 0.08),
            .moveBy(x: -14, y: 0, duration: 0.08),
            .moveBy(x: 7, y: 0, duration: 0.05)
        ]))
    }

    private func showErrorNotification(_ message: String) {
        let notification = SKNode()
        notification.zPosition = 101

        let bg = SKShapeNode(rectOf: CGSize(width: 460, height: 40), cornerRadius: 8)
        bg.fillColor = C.red.withAlphaComponent(0.92)
        bg.strokeColor = C.red
        bg.lineWidth = 1
        bg.position = CGPoint(x: size.width / 2, y: size.height - topBarH - 58)
        notification.addChild(bg)

        let label = makeLabel(message, size: 12, color: .white, bold: true)
        label.position = bg.position
        notification.addChild(label)

        addChild(notification)
        notification.run(.sequence([
            .wait(forDuration: 2.2),
            .fadeOut(withDuration: 0.3),
            .removeFromParent()
        ]))
    }

    // MARK: - Action Handlers

    private func handlePartSelected(_ part: RobotPart) {
        guard isCorrectPart(part) else {
            showWrongPartFeedback(for: part)
            return
        }

        robotNode.installPart(part)

        if let index = files.firstIndex(where: { $0.partSlot == part.slot }) {
            files[index].previousContent = files[index].content
            let allParts = robotNode.getInstalledParts(for: part.slot)
            files[index].content = generateFileContent(for: part.slot, parts: allParts)
            files[index].status = .modified
        }

        currentGitState = .modified
        showFileSystemUI()
    }

    private func generateFileContent(for slot: PartSlot, parts: [RobotPart]) -> [String] {
        var lines: [String] = []
        lines.append("// \(slot.label)")
        for (index, part) in parts.enumerated() {
            lines.append("part\(index): \(part.name) \(part.emoji)")
        }
        return lines
    }
    
    private func handleWorkstationOpened(_ name: String) {
        if !activeBranches.contains(name) { activeBranches.append(name) }
        currentBranch = name
        completePhaseAction()
    }
    
    private func handleMerge(_ from: String, _ to: String) {
        currentBranch = to
        completePhaseAction()
    }
    
    private func handleConflictResolved() { completePhaseAction() }
    private func handleTagged(_ version: String) { completePhaseAction() }
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
        currentGitState = .modified
        showFileSystemUI()
    }
    
    // MARK: - Navigation
    
    private func goToChapters() {
        let scene = ChapterScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: .push(with: .right, duration: 0.3))
    }
    
    private func goToNextMission() {
        let scene = GameScene(size: size)
        scene.scaleMode = .aspectFill
        scene.missionId = missionId + 1
        view?.presentScene(scene, transition: .push(with: .left, duration: 0.3))
    }
    
    private func goToComplete() {
        let scene = CompleteScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: .fade(withDuration: 0.4))
    }
    
    // MARK: - Mouse Handling

    override func mouseDown(with event: NSEvent) {
        let loc = event.location(in: self)
        let allNodes = nodes(at: loc)

        for node in allNodes {
            if let card = findPartCard(in: node) {
                draggedCard = card
                dragStartPosition = loc
                if isTutorialMode && currentTutorialStep == .dragPart {
                    hideTutorial()
                }
                return
            }
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let card = draggedCard, let startPos = dragStartPosition else { return }

        let loc = event.location(in: self)
        let distance = hypot(loc.x - startPos.x, loc.y - startPos.y)

        if distance > dragThreshold && ghostCard == nil {
            createGhostCard(from: card)
        }

        if let ghost = ghostCard {
            ghost.position = loc
            updateSlotHighlight(at: loc, for: card.part)
        }
    }

    override func mouseUp(with event: NSEvent) {
        let loc = event.location(in: self)

        if ghostCard != nil {
            handleDrop(at: loc)
            cleanupDrag()
            return
        }

        if draggedCard != nil {
            cleanupDrag()
            return
        }

        let allNodes = nodes(at: loc)
        for node in allNodes {
            // Toggle sections
            if node.name == "toggleWorkingDir" || node.parent?.name == "toggleWorkingDir" {
                isWorkingDirExpanded.toggle()
                showFileSystemUI()
                return
            }
            if node.name == "toggleStaging" || node.parent?.name == "toggleStaging" {
                isStagingExpanded.toggle()
                showFileSystemUI()
                return
            }
            if node.name == "toggleChecklist" || node.parent?.name == "toggleChecklist" {
                isChecklistExpanded.toggle()
                showFileSystemUI()
                return
            }
            
            // Stage buttons
            if let stageBtn = node as? SKShapeNode, let name = stageBtn.name, name.hasPrefix("stageBtn_") {
                if let fileName = stageBtn.userData?["fileName"] as? String,
                   let isStaged = stageBtn.userData?["isStaged"] as? Bool {
                    if isTutorialMode && currentTutorialStep == .clickStage { hideTutorial() }
                    handleStageToggle(fileName: fileName, isStaged: isStaged)
                    return
                }
            }
            
            // Commit message
            if let msgNode = node as? SKShapeNode, msgNode.name == "commitMsgBg" {
                if isTutorialMode && currentTutorialStep == .enterCommitMsg { hideTutorial() }
                showCommitMessageInput()
                return
            }
            
            // Buttons
            if let btn = findButton(in: node) {
                if isTutorialMode && currentTutorialStep == .clickCommit && btn.name == "commitButton" {
                    hideTutorial()
                }
                btn.action?()
                return
            }
            
            if let merge = findMergeCard(in: node) {
                merge.onMerge?()
                return
            }
        }

        if isTutorialMode && tutorialUI != nil {
            hideTutorial()
        }
    }

    private func handleStageToggle(fileName: String, isStaged: Bool) {
        guard let index = files.firstIndex(where: { $0.name == fileName }) else { return }

        if isStaged {
            files[index].status = .modified
            terminal.addCommand("git restore --staged \(fileName)")
            showNotification("↓ Unstage")
        } else {
            files[index].status = .staged
            terminal.addCommand("git add \(fileName)")
            showNotification("↑ Stage")
            completeTodo(.stage)
            if isTutorialMode && currentTutorialStep == .clickStage {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                    self?.advanceTutorial()
                }
            }
        }
        showFileSystemUI()
    }

    private func initializeFileContents() {
        for index in files.indices {
            let slot = files[index].partSlot
            let parts = robotNode.getInstalledParts(for: slot)
            files[index].content = generateFileContent(for: slot, parts: parts)
            files[index].previousContent = files[index].content
        }
    }

    private func showCommitMessageInput() {
        let alert = NSAlert()
        alert.messageText = "커밋 메시지"
        alert.informativeText = "변경사항 설명"
        alert.addButton(withTitle: "확인")
        alert.addButton(withTitle: "취소")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        input.stringValue = commitMessageText
        input.placeholderString = "예: 머리 부품 추가"
        alert.accessoryView = input

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            commitMessageText = input.stringValue
            showFileSystemUI()
            completeTodo(.commitMessage)
            if isTutorialMode && currentTutorialStep == .enterCommitMsg {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.advanceTutorial()
                }
            }
        }
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

    // MARK: - Drag & Drop

    private func createGhostCard(from card: PartCardNode) {
        let ghost = PartCardNode(part: card.part)
        ghost.position = card.convert(card.position, to: self)
        ghost.zPosition = 100
        ghost.alpha = 0.85
        ghost.setScale(1.1)

        let glow = SKShapeNode(rectOf: CGSize(width: 120, height: 100), cornerRadius: 10)
        glow.fillColor = .clear
        glow.strokeColor = C.blue.withAlphaComponent(0.5)
        glow.lineWidth = 2
        glow.glowWidth = 6
        glow.zPosition = -1
        ghost.addChild(glow)

        addChild(ghost)
        ghostCard = ghost
        card.alpha = 0.4
    }

    private func findDropTarget(at location: CGPoint, for part: RobotPart) -> SKNode? {
        guard let slotNode = robotNode.slots[part.slot] else { return nil }
        let slotPosition = robotNode.convert(slotNode.position, to: self)
        let distance = hypot(location.x - slotPosition.x, location.y - slotPosition.y)
        return distance <= 35 ? slotNode : nil
    }

    private func updateSlotHighlight(at location: CGPoint, for part: RobotPart) {
        currentHighlight?.removeFromParent()
        currentHighlight = nil

        guard let targetSlot = findDropTarget(at: location, for: part) else { return }

        let correct = isCorrectPart(part)
        let highlightColor = correct ? C.green : C.orange

        let size = part.slot == .torso ? CGSize(width: 50, height: 50) : CGSize(width: 44, height: 44)
        let highlight = SKShapeNode(rectOf: size, cornerRadius: 7)
        highlight.fillColor = highlightColor.withAlphaComponent(0.15)
        highlight.strokeColor = highlightColor.withAlphaComponent(0.7)
        highlight.lineWidth = 2
        highlight.zPosition = -1

        let pulse = SKAction.sequence([
            .scale(to: 1.08, duration: 0.35),
            .scale(to: 1.0, duration: 0.35)
        ])
        highlight.run(.repeatForever(pulse))

        targetSlot.addChild(highlight)
        currentHighlight = highlight
    }

    private func handleDrop(at location: CGPoint) {
        guard let ghost = ghostCard, let card = draggedCard else { return }

        if let targetSlot = findDropTarget(at: location, for: card.part) {
            // 정답 부품 검증
            if !isCorrectPart(card.part) {
                showWrongPartFeedback(for: card.part)
                rejectGhost(ghost)
                return
            }

            let slotPosition = robotNode.convert(targetSlot.position, to: self)
            let move = SKAction.move(to: slotPosition, duration: 0.15)
            let fadeOut = SKAction.fadeOut(withDuration: 0.15)
            ghost.run(.group([move, fadeOut]))

            robotNode.installPart(card.part)

            if let index = files.firstIndex(where: { $0.partSlot == card.part.slot }) {
                files[index].status = .modified
                currentGitState = .modified
                showFileSystemUI()

                completeTodo(.dragPart)

                if isTutorialMode && currentTutorialStep == .dragPart {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                        self?.advanceTutorial()
                    }
                }
            }
        } else {
            rejectGhost(ghost)
        }
    }

    private func rejectGhost(_ ghost: SKNode) {
        let shake = SKAction.sequence([
            .moveBy(x: -6, y: 0, duration: 0.04),
            .moveBy(x: 12, y: 0, duration: 0.08),
            .moveBy(x: -12, y: 0, duration: 0.08),
            .moveBy(x: 6, y: 0, duration: 0.04)
        ])
        let flash = SKShapeNode(rectOf: CGSize(width: 120, height: 100), cornerRadius: 10)
        flash.fillColor = .clear
        flash.strokeColor = C.red.withAlphaComponent(0.7)
        flash.lineWidth = 2
        flash.zPosition = -1
        ghost.addChild(flash)
        flash.run(.sequence([.wait(forDuration: 0.25), .fadeOut(withDuration: 0.15), .removeFromParent()]))
        ghost.run(.sequence([shake, .group([.scale(to: 0.4, duration: 0.15), .fadeOut(withDuration: 0.15)])]))
    }

    private func cleanupDrag() {
        if let card = draggedCard { card.alpha = 1.0 }
        ghostCard?.removeFromParent()
        currentHighlight?.removeFromParent()
        draggedCard = nil
        ghostCard = nil
        dragStartPosition = nil
        currentHighlight = nil
    }
}
