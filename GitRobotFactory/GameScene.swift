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
    private let terminalH: CGFloat = 75
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
        // Dark bar
        let bar = SKShapeNode(rectOf: CGSize(width: size.width, height: topBarH))
        bar.fillColor = NSColor(white: 0.05, alpha: 1)
        bar.strokeColor = .clear
        bar.position = CGPoint(x: size.width/2, y: size.height - topBarH/2)
        bar.zPosition = 10
        addChild(bar)
        
        // Left: Back button
        let back = ButtonNode(text: "◀ 목록", width: 70, height: 28, color: NSColor(white: 0.12, alpha: 1), fontSize: 11)
        back.position = CGPoint(x: 50, y: size.height - topBarH/2)
        back.zPosition = 11
        back.action = { [weak self] in self?.goToChapters() }
        addChild(back)
        
        // Mission title (compact)
        let title = makeLabel("M\(mission.id): \(mission.title)", size: 14, color: C.text, bold: true)
        title.position = CGPoint(x: 150, y: size.height - topBarH/2)
        title.horizontalAlignmentMode = .left
        title.zPosition = 11
        addChild(title)

        // Phase counter
        phaseCounter = makeLabel("1/\(mission.phases.count)", size: 12, color: C.textDim, mono: true)
        phaseCounter.position = CGPoint(x: 320, y: size.height - topBarH/2)
        phaseCounter.zPosition = 11
        addChild(phaseCounter)

        // Branch badge (right side)
        branchBadge = makeBadge(currentBranch, color: C.branchColor(currentBranch), fontSize: 10)
        branchBadge.position = CGPoint(x: size.width - 180, y: size.height - topBarH/2)
        branchBadge.zPosition = 11
        addChild(branchBadge)

        // Stars
        let stars = makeLabel("⭐\(GameData.shared.totalStars)", size: 12, color: C.yellow)
        stars.position = CGPoint(x: size.width - 50, y: size.height - topBarH/2)
        stars.zPosition = 11
        addChild(stars)
        
        // Git toolbar (inline, compact)
        setupGitToolbar()
    }

    private func setupGitToolbar() {
        let toolbarY = size.height - topBarH/2
        let buttonW: CGFloat = 42
        let buttonH: CGFloat = 24
        let spacing: CGFloat = 3
        let startX = size.width - 450

        let buttons: [(text: String, icon: String, action: Selector, enabled: Bool)] = [
            ("", "↶", #selector(handleUndo), false),
            ("", "↷", #selector(handleRedo), false),
            ("", "↓", #selector(handlePull), true),
            ("", "↑", #selector(handlePush), true),
            ("", "⎇", #selector(handleBranchUI), true),
        ]

        for (index, button) in buttons.enumerated() {
            let x = startX + CGFloat(index) * (buttonW + spacing)

            let btn = SKShapeNode(rectOf: CGSize(width: buttonW, height: buttonH), cornerRadius: 5)
            btn.fillColor = button.enabled ? NSColor(white: 0.12, alpha: 1) : NSColor(white: 0.08, alpha: 0.5)
            btn.strokeColor = button.enabled ? C.border : NSColor(white: 0.06, alpha: 1)
            btn.lineWidth = 1
            btn.position = CGPoint(x: x, y: toolbarY)
            btn.name = "gitBtn_\(index)"
            btn.zPosition = 12
            addChild(btn)

            let icon = makeLabel(button.icon, size: 14, color: button.enabled ? C.textDim : NSColor(white: 0.2, alpha: 1))
            icon.position = CGPoint(x: x, y: toolbarY)
            icon.zPosition = 13
            addChild(icon)

            btn.userData = NSMutableDictionary()
            btn.userData?["action"] = button.action
            btn.userData?["enabled"] = button.enabled
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

        let bg = SKShapeNode(rectOf: CGSize(width: 400, height: 40), cornerRadius: 8)
        bg.fillColor = NSColor(red: 0.1, green: 0.15, blue: 0.2, alpha: 0.95)
        bg.strokeColor = C.blue
        bg.lineWidth = 1
        bg.position = CGPoint(x: size.width / 2, y: size.height - topBarH - 30)
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
        dialog.fillColor = NSColor(red: 0.08, green: 0.1, blue: 0.14, alpha: 1)
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

        let cancelBtn = ButtonNode(text: "취소", width: 80, height: 28, color: NSColor(white: 0.3, alpha: 1), fontSize: 12)
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
        branchBadge.position = CGPoint(x: size.width - 180, y: size.height - topBarH/2)
        branchBadge.zPosition = 11
        addChild(branchBadge)
    }

    private func setupProgressBar() {
        let y = size.height - topBarH - 2
        progressBar = SKShapeNode(rectOf: CGSize(width: size.width, height: 2))
        progressBar.fillColor = NSColor(white: 0.1, alpha: 1)
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
        
        // ═══ LEFT PANEL: Git Status ═══
        let gitPanel = SKShapeNode(rectOf: CGSize(width: gitPanelWidth - 8, height: panelHeight), cornerRadius: 10)
        gitPanel.fillColor = NSColor(white: 0.03, alpha: 0.6)
        gitPanel.strokeColor = C.border
        gitPanel.lineWidth = 1
        gitPanel.position = CGPoint(x: gitPanelCenterX, y: midY)
        addChild(gitPanel)
        
        let gitTitle = makeLabel("📂 GIT", size: 11, color: C.blue, bold: true, mono: true)
        gitTitle.position = CGPoint(x: gitPanelCenterX, y: panelTop - 12)
        addChild(gitTitle)
        
        // Divider 1
        let div1 = SKShapeNode(rectOf: CGSize(width: 1, height: panelHeight - 20))
        div1.fillColor = C.border
        div1.strokeColor = .clear
        div1.position = CGPoint(x: gitPanelWidth, y: midY)
        addChild(div1)
        
        // ═══ CENTER PANEL: Robot Assembly ═══
        let robotPanel = SKShapeNode(rectOf: CGSize(width: robotPanelWidth - 8, height: panelHeight), cornerRadius: 10)
        robotPanel.fillColor = NSColor(white: 0.03, alpha: 0.6)
        robotPanel.strokeColor = C.border
        robotPanel.lineWidth = 1
        robotPanel.position = CGPoint(x: robotPanelCenterX, y: midY)
        addChild(robotPanel)
        
        let robotTitle = makeLabel("🤖 조립", size: 11, color: C.green, bold: true, mono: true)
        robotTitle.position = CGPoint(x: robotPanelCenterX, y: panelTop - 12)
        addChild(robotTitle)
        
        // Robot node - positioned in upper half
        let robotY = midY + panelHeight * 0.15
        robotNode.position = CGPoint(x: robotPanelCenterX, y: robotY)
        addChild(robotNode)

        // Assembly zone - positioned in lower half
        let assemblyY = midY - panelHeight * 0.25
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
        
        // Divider 2
        let div2 = SKShapeNode(rectOf: CGSize(width: 1, height: panelHeight - 20))
        div2.fillColor = C.border
        div2.strokeColor = .clear
        div2.position = CGPoint(x: gitPanelWidth + robotPanelWidth, y: midY)
        addChild(div2)
        
        // ═══ RIGHT PANEL: Git Graph ═══
        let graphPanel = SKShapeNode(rectOf: CGSize(width: graphPanelWidth - 8, height: panelHeight), cornerRadius: 10)
        graphPanel.fillColor = NSColor(white: 0.03, alpha: 0.6)
        graphPanel.strokeColor = C.border
        graphPanel.lineWidth = 1
        graphPanel.position = CGPoint(x: graphPanelCenterX, y: midY)
        addChild(graphPanel)
        
        let graphTitle = makeLabel("🌳 GRAPH", size: 11, color: C.purple, bold: true, mono: true)
        graphTitle.position = CGPoint(x: graphPanelCenterX, y: panelTop - 12)
        addChild(graphTitle)

        gitGraph.position = CGPoint(x: gitPanelWidth + robotPanelWidth + 20, y: panelTop - 35)
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

        phaseCounter.text = "\(phaseIndex + 1)/\(mission.phases.count)"
        updateProgress()
        updateBranchBadge(phase.branchContext)
        
        childNode(withName: "missionHeader")?.removeFromParent()
        
        actionDone = false
        currentGitState = .waiting
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
        branchBadge.position = CGPoint(x: size.width - 180, y: size.height - topBarH/2)
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
        bg.fillColor = NSColor(red: 0.1, green: 0.1, blue: 0.05, alpha: 0.98)
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
        exp.fontColor = NSColor(white: 0.8, alpha: 1)
        exp.verticalAlignmentMode = .center
        exp.horizontalAlignmentMode = .center
        exp.preferredMaxLayoutWidth = modalW - 40
        exp.numberOfLines = 0
        exp.position = CGPoint(x: cx, y: cy + 20)
        group.addChild(exp)

        // Git command
        let cmdBg = SKShapeNode(rectOf: CGSize(width: modalW - 40, height: 24), cornerRadius: 5)
        cmdBg.fillColor = NSColor(white: 0.03, alpha: 1)
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
        bg.fillColor = NSColor(red: 0.15, green: 0.2, blue: 0.3, alpha: 0.95)
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
        let leftX: CGFloat = padding + 4
        let rightX: CGFloat = panelW - padding - 4
        
        // Available height for content
        let topY = size.height - topBarH - 28
        var y = topY
        
        // ═══ GOAL SECTION (Compact) ═══
        if phaseIndex < mission.phases.count {
            let phase = mission.phases[phaseIndex]
            let goalText = getGoalText(for: phase)
            
            let goalBg = SKShapeNode(rectOf: CGSize(width: panelW - padding * 2, height: 32), cornerRadius: 6)
            goalBg.fillColor = C.yellow.withAlphaComponent(0.08)
            goalBg.strokeColor = C.yellow.withAlphaComponent(0.25)
            goalBg.lineWidth = 1
            goalBg.position = CGPoint(x: cx, y: y - 16)
            group.addChild(goalBg)

            let goalLabel = makeLabel("🎯 \(goalText)", size: 11, color: C.yellow, bold: true)
            goalLabel.position = CGPoint(x: cx, y: y - 16)
            group.addChild(goalLabel)
            
            y -= 42
        }
        
        // ═══ WORKING DIRECTORY (Collapsible) ═══
        let modifiedFiles = files.filter { $0.status == .modified || $0.status == .untracked }
        y = addCollapsibleSection(
            to: group,
            title: "Working Dir",
            icon: "📂",
            color: C.orange,
            isExpanded: isWorkingDirExpanded,
            toggleName: "toggleWorkingDir",
            files: modifiedFiles,
            isStaged: false,
            emptyText: "✓ clean",
            y: y,
            panelW: panelW
        )
        
        y -= sectionGap
        
        // ═══ STAGING AREA (Collapsible) ═══
        let stagedFiles = files.filter { $0.status == .staged }
        y = addCollapsibleSection(
            to: group,
            title: "Staging",
            icon: "📦",
            color: C.green,
            isExpanded: isStagingExpanded,
            toggleName: "toggleStaging",
            files: stagedFiles,
            isStaged: true,
            emptyText: "→ 없음",
            y: y,
            panelW: panelW
        )
        
        y -= sectionGap
        
        // ═══ COMMIT SECTION (Always visible, compact) ═══
        let commitBg = SKShapeNode(rectOf: CGSize(width: panelW - padding * 2, height: sectionHeaderH), cornerRadius: 5)
        commitBg.fillColor = C.blue.withAlphaComponent(0.1)
        commitBg.strokeColor = .clear
        commitBg.position = CGPoint(x: cx, y: y - sectionHeaderH/2)
        group.addChild(commitBg)

        let commitTitle = makeLabel("💾 Commit", size: 11, color: C.blue, bold: true, mono: true)
        commitTitle.position = CGPoint(x: cx, y: y - sectionHeaderH/2)
        group.addChild(commitTitle)
        
        y -= sectionHeaderH + 6
        
        // Commit message + button in one row
        let rowH: CGFloat = inputH
        let inputW = panelW - padding * 2 - 70  // Leave space for button
        
        let msgBg = SKShapeNode(rectOf: CGSize(width: inputW, height: rowH), cornerRadius: 5)
        msgBg.fillColor = NSColor(white: 0.05, alpha: 1)
        msgBg.strokeColor = stagedFiles.isEmpty ? C.border : C.blue
        msgBg.lineWidth = 1
        msgBg.position = CGPoint(x: leftX + inputW/2, y: y - rowH/2)
        msgBg.name = "commitMsgBg"
        group.addChild(msgBg)

        let msgText = commitMessageText.isEmpty ? "메시지..." : commitMessageText
        let msgLabel = makeLabel(msgText, size: 10, color: commitMessageText.isEmpty ? C.textFaint : C.text, mono: true)
        msgLabel.position = msgBg.position
        group.addChild(msgLabel)
        
        // Commit button (inline)
        let commitBtn = ButtonNode(
            text: "✓",
            width: 50,
            height: rowH,
            color: stagedFiles.isEmpty ? NSColor(white: 0.12, alpha: 0.5) : C.green,
            fontSize: 14
        )
        commitBtn.position = CGPoint(x: rightX - 25, y: y - rowH/2)
        commitBtn.name = "commitButton"
        if !stagedFiles.isEmpty {
            commitBtn.action = { [weak self] in self?.performCommit() }
        }
        group.addChild(commitBtn)
        
        y -= rowH + sectionGap
        
        // ═══ TODO CHECKLIST (Collapsible, compact) ═══
        if !currentTodos.isEmpty {
            y = addChecklistSection(to: group, y: y, panelW: panelW)
        }

        addChild(group)
        fileSystemUI = group

        // Tutorial auto-advance
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
        let leftX: CGFloat = padding + 4
        
        // Section header (clickable)
        let headerBg = SKShapeNode(rectOf: CGSize(width: panelW - padding * 2, height: sectionHeaderH), cornerRadius: 5)
        headerBg.fillColor = color.withAlphaComponent(0.1)
        headerBg.strokeColor = .clear
        headerBg.position = CGPoint(x: cx, y: currentY - sectionHeaderH/2)
        headerBg.name = toggleName
        group.addChild(headerBg)

        let arrow = isExpanded ? "▼" : "▶"
        let count = files.isEmpty ? "" : " (\(files.count))"
        let headerLabel = makeLabel("\(arrow) \(icon) \(title)\(count)", size: 11, color: color, bold: true, mono: true)
        headerLabel.position = CGPoint(x: cx, y: currentY - sectionHeaderH/2)
        headerLabel.name = "\(toggleName)_label"
        group.addChild(headerLabel)
        
        currentY -= sectionHeaderH + 4
        
        // Content (if expanded)
        if isExpanded {
            if files.isEmpty {
                let emptyLabel = makeLabel(emptyText, size: 10, color: emptyText.contains("✓") ? C.green : C.textFaint)
                emptyLabel.horizontalAlignmentMode = .left
                emptyLabel.position = CGPoint(x: leftX + 8, y: currentY - 10)
                group.addChild(emptyLabel)
                currentY -= 22
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
        let cx = panelW / 2
        
        // Status badge (compact)
        let statusText: String
        let statusColor: NSColor
        switch file.status {
        case .untracked: statusText = "?"; statusColor = C.purple
        case .modified: statusText = "M"; statusColor = C.orange
        case .staged: statusText = "A"; statusColor = C.green
        case .committed: statusText = ""; statusColor = C.textFaint
        }

        if !statusText.isEmpty {
            let badge = SKShapeNode(rectOf: CGSize(width: 18, height: 16), cornerRadius: 3)
            badge.fillColor = statusColor.withAlphaComponent(0.2)
            badge.strokeColor = statusColor.withAlphaComponent(0.4)
            badge.lineWidth = 1
            badge.position = CGPoint(x: x + 12, y: y)
            row.addChild(badge)

            let statusLabel = makeLabel(statusText, size: 9, color: statusColor, bold: true, mono: true)
            statusLabel.position = CGPoint(x: x + 12, y: y)
            row.addChild(statusLabel)
        }

        // File name (truncated)
        let maxNameLen = 8
        let displayName = file.name.count > maxNameLen ? String(file.name.prefix(maxNameLen)) + "…" : file.name
        let fileName = makeLabel(displayName, size: 10, color: C.text, mono: true)
        fileName.horizontalAlignmentMode = .left
        fileName.position = CGPoint(x: x + 28, y: y)
        row.addChild(fileName)

        // Stage/Unstage button
        let btnText = isStaged ? "↓" : "↑"
        let btnColor = isStaged ? C.orange : C.green
        
        let btn = SKShapeNode(rectOf: CGSize(width: 24, height: 20), cornerRadius: 5)
        btn.fillColor = isStaged ? btnColor.withAlphaComponent(0.2) : btnColor.withAlphaComponent(0.35)
        btn.strokeColor = btnColor
        btn.lineWidth = isStaged ? 1 : 1.5
        btn.position = CGPoint(x: panelW - padding - 16, y: y)
        btn.name = "stageBtn_\(file.name)"
        btn.userData = NSMutableDictionary()
        btn.userData?["fileName"] = file.name
        btn.userData?["isStaged"] = isStaged
        
        // Glow effect for stage button (↑)
        if !isStaged {
            btn.glowWidth = 3
        }
        row.addChild(btn)

        let btnLabel = makeLabel(btnText, size: 14, color: isStaged ? btnColor : .white, bold: true)
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
        panel.fillColor = NSColor(red: 0.05, green: 0.08, blue: 0.05, alpha: 0.98)
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
        lesson.fontColor = NSColor(white: 0.65, alpha: 1)
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
    
    // MARK: - Action Handlers

    private func handlePartSelected(_ part: RobotPart) {
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

        let size = part.slot == .torso ? CGSize(width: 50, height: 50) : CGSize(width: 44, height: 44)
        let highlight = SKShapeNode(rectOf: size, cornerRadius: 7)
        highlight.fillColor = C.green.withAlphaComponent(0.15)
        highlight.strokeColor = C.green.withAlphaComponent(0.7)
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
            // Failed drop
            let shake = SKAction.sequence([
                .moveBy(x: -6, y: 0, duration: 0.04),
                .moveBy(x: 12, y: 0, duration: 0.08),
                .moveBy(x: -12, y: 0, duration: 0.08),
                .moveBy(x: 6, y: 0, duration: 0.04)
            ])

            let flash = SKShapeNode(rectOf: CGSize(width: 120, height: 100), cornerRadius: 10)
            flash.fillColor = .clear
            flash.strokeColor = NSColor.red.withAlphaComponent(0.7)
            flash.lineWidth = 2
            flash.zPosition = -1
            ghost.addChild(flash)

            flash.run(.sequence([.wait(forDuration: 0.25), .fadeOut(withDuration: 0.15), .removeFromParent()]))
            ghost.run(.sequence([shake, .group([.scale(to: 0.4, duration: 0.15), .fadeOut(withDuration: 0.15)])]))
        }
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
