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
        var content: [String] = []  // File content lines
        var previousContent: [String] = []  // For diff comparison
    }

    private var files: [GitFile] = []
    private var fileSystemUI: SKNode?
    private var commitMessageText: String = ""

    // Tutorial system
    private enum TutorialStep {
        case dragPart           // 1. 부품을 드래그하세요
        case waitForModified    // 2. 변경사항 확인
        case clickStage         // 3. Stage 버튼 클릭
        case waitForStaged      // 4. Staging Area 확인
        case enterCommitMsg     // 5. 커밋 메시지 입력
        case clickCommit        // 6. Commit 버튼 클릭
        case completed          // 완료
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
    
    // Layout constants - 3섹션 레이아웃
    private let gitPanelWidth: CGFloat = 380    // 왼쪽: Git UI
    private let robotPanelWidth: CGFloat = 420  // 가운데: 로봇 조립
    private let graphPanelWidth: CGFloat = 400  // 오른쪽: Git Graph
    private let topBarH: CGFloat = 70           // 상단바 높이
    private let terminalH: CGFloat = 85         // 터미널 높이
    private let padding: CGFloat = 28           // 기본 여백
    private let elementSpacing: CGFloat = 18    // 요소 간 간격

    // Element heights - CRITICAL for preventing overlap
    private let missionHeaderHeight: CGFloat = 60      // Mission header total height
    private let robotSlotSize: CGFloat = 62           // Robot slot dimensions
    private let partCardHeight: CGFloat = 125         // Part card height
    private let minMargin: CGFloat = 20               // Minimum spacing between elements (reduced to fit)

    // 패널 X 좌표
    private var gitPanelCenterX: CGFloat { gitPanelWidth / 2 }
    private var robotPanelCenterX: CGFloat { gitPanelWidth + robotPanelWidth / 2 }
    private var graphPanelCenterX: CGFloat { gitPanelWidth + robotPanelWidth + graphPanelWidth / 2 }
    
    // Alias for compatibility
    private var leftWidth: CGFloat { gitPanelWidth }
    
    // Y positions - Calculated to prevent overlap (checklist collapsed by default for space)
    private var missionHeaderY: CGFloat {
        size.height - topBarH - minMargin - missionHeaderHeight/2
    }
    private var robotCenterY: CGFloat {
        // Center robot in available space (no mission header in center panel)
        let availableHeight = size.height - topBarH - terminalH - 110  // 110 for terminal bg
        let robotTop = size.height - topBarH - 30  // Start 30px below top bar
        let robotHeadOffset: CGFloat = 100  // From RobotNode.swift
        return robotTop - robotHeadOffset
    }
    private var assemblyZoneCenterY: CGFloat {
        // Position assembly zone: well above terminal with clear spacing
        let terminalTop = terminalH + 110/2 + 10  // Terminal bg top edge
        let cardOffset: CGFloat = 130  // From AssemblyZone.swift
        let clearMargin: CGFloat = 30  // Extra margin to prevent overlap
        return terminalTop + clearMargin + cardOffset + partCardHeight/2
    }
    private var fileSystemY: CGFloat { size.height - topBarH - 90 }
    private var robotAreaY: CGFloat { (size.height - topBarH + terminalH) / 2 }
    private var checklistY: CGFloat { terminalH + 100 }
    
    // 체크리스트 상태 - 기본적으로 접어서 공간 확보
    private var isChecklistVisible: Bool = false  // Changed to false to save space
    
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
        setupGitToolbar()
        setupProgressBar()
        setupLeftPanel()
        setupRightPanel()
        setupTerminal()
        setupFileSystem()
        initializeFileContents()

        showCurrentPhase()
    }

    private func setupFileSystem() {
        // Initialize file system with all robot parts
        // Start with committed status (clean working tree)
        files = [
            GitFile(name: "머리.txt", partSlot: .head, status: .committed),
            GitFile(name: "몸통.txt", partSlot: .torso, status: .committed),
            GitFile(name: "왼팔.txt", partSlot: .leftArm, status: .committed),
            GitFile(name: "오른팔.txt", partSlot: .rightArm, status: .committed),
            GitFile(name: "다리.txt", partSlot: .legs, status: .committed),
            GitFile(name: "백팩.txt", partSlot: .backpack, status: .committed)
        ]
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
        let title = makeLabel("Mission \(mission.id): \(mission.title)", size: 17, color: C.text, bold: true)  // Increased
        title.position = CGPoint(x: 240, y: size.height - topBarH/2)
        title.zPosition = 11
        addChild(title)

        // Branch label
        let branchLabel = makeLabel("Branch:", size: 12, color: C.textDim, bold: true)
        branchLabel.position = CGPoint(x: size.width - 670, y: size.height - topBarH/2)
        branchLabel.zPosition = 11
        addChild(branchLabel)

        // Branch badge
        branchBadge = makeBadge(currentBranch, color: C.branchColor(currentBranch))
        branchBadge.position = CGPoint(x: size.width - 610, y: size.height - topBarH/2)
        branchBadge.zPosition = 11
        addChild(branchBadge)

        // Phase counter
        phaseCounter = makeLabel("Phase 1/\(mission.phases.count)", size: 13, color: C.textDim, mono: true)  // Increased
        phaseCounter.position = CGPoint(x: size.width - 740, y: size.height - topBarH/2)
        phaseCounter.zPosition = 11
        addChild(phaseCounter)

        // Stars
        let stars = makeLabel("⭐\(GameData.shared.totalStars)", size: 14, color: C.yellow)  // Increased
        stars.position = CGPoint(x: size.width - 750, y: size.height - topBarH/2)
        stars.zPosition = 11
        addChild(stars)
    }

    private func setupGitToolbar() {
        let toolbarY = size.height - topBarH/2  // Aligned with other top bar elements
        let buttonWidth: CGFloat = 65
        let buttonHeight: CGFloat = 28
        let spacing: CGFloat = 4
        let startX = size.width - 540

        let buttons: [(text: String, icon: String, action: Selector, enabled: Bool)] = [
            ("Undo", "↶", #selector(handleUndo), false),
            ("Redo", "↷", #selector(handleRedo), false),
            ("Pull", "↓", #selector(handlePull), true),
            ("Push", "↑", #selector(handlePush), true),
            ("Branch", "⎇", #selector(handleBranchUI), true),
            ("Stash", "📥", #selector(handleStash), true),
            ("Pop", "📤", #selector(handlePop), false)
        ]

        for (index, button) in buttons.enumerated() {
            let x = startX + CGFloat(index) * (buttonWidth + spacing)

            // Button background
            let btn = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 6)
            btn.fillColor = button.enabled ? NSColor(white: 0.15, alpha: 1) : NSColor(white: 0.1, alpha: 0.5)
            btn.strokeColor = button.enabled ? C.border : NSColor(white: 0.08, alpha: 1)
            btn.lineWidth = 1
            btn.position = CGPoint(x: x, y: toolbarY)
            btn.name = "gitBtn_\(button.text.lowercased())"
            btn.zPosition = 12
            addChild(btn)

            // Icon
            let icon = makeLabel(button.icon, size: 16, color: button.enabled ? C.textDim : NSColor(white: 0.2, alpha: 1))  // Increased
            icon.position = CGPoint(x: x, y: toolbarY + 5)
            icon.zPosition = 13
            addChild(icon)

            // Label
            let label = makeLabel(button.text, size: 10, color: button.enabled ? C.textDim : NSColor(white: 0.2, alpha: 1), mono: true)  // Increased
            label.position = CGPoint(x: x, y: toolbarY - 8)
            label.zPosition = 13
            addChild(label)

            // Store action for click handling
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
        showNotification("↶ Undo 완료: 마지막 커밋을 취소했습니다")
        updateGitButton("redo", enabled: true)

        if historyIndex == 0 {
            updateGitButton("undo", enabled: false)
        }
    }

    @objc private func handleRedo() {
        guard historyIndex < gitHistory.count - 1 else {
            showNotification("⚠️ Redo할 항목이 없습니다")
            return
        }

        historyIndex += 1
        let entry = gitHistory[historyIndex]
        terminal.addCommand("git reset HEAD@{1}")
        showNotification("↷ Redo 완료: 취소한 커밋을 복원했습니다")
        updateGitButton("undo", enabled: true)

        if historyIndex >= gitHistory.count - 1 {
            updateGitButton("redo", enabled: false)
        }
    }

    @objc private func handlePull() {
        terminal.addCommand("git pull origin \(currentBranch)")
        showNotification("📥 Pull 완료: 원격 저장소에서 최신 변경사항을 가져왔습니다")
    }

    @objc private func handlePush() {
        terminal.addCommand("git push origin \(currentBranch)")
        showNotification("📤 Push 완료: 원격 저장소에 변경사항을 올렸습니다")
    }

    @objc private func handleBranchUI() {
        showBranchCreationUI()
    }

    @objc private func handleStash() {
        guard currentGitState == .modified || currentGitState == .staged else {
            showNotification("⚠️ Stash할 변경사항이 없습니다")
            return
        }

        // Find the last installed part from robot
        // For simplicity, we'll just store the state
        terminal.addCommand("git stash save \"WIP: 작업 임시 저장\"")
        currentGitState = .waiting
        gitWorkflowUI?.removeFromParent()
        gitWorkflowUI = nil

        // Mark that we have stashed work
        stashedPart = RobotPart(id: "stashed", name: "임시저장", emoji: "📦", slot: .torso, portId: nil)

        showNotification("📥 Stash 완료: 변경사항을 임시 저장했습니다")
        updateGitButton("pop", enabled: true)
        updateGitButton("stash", enabled: false)
    }

    @objc private func handlePop() {
        guard stashedPart != nil else {
            showNotification("⚠️ Stash된 항목이 없습니다")
            return
        }

        terminal.addCommand("git stash pop")
        currentGitState = .modified
        stashedPart = nil
        showGitWorkflowUI()
        showNotification("📤 Pop 완료: 임시 저장한 변경사항을 복원했습니다")
        updateGitButton("pop", enabled: false)
        updateGitButton("stash", enabled: true)
    }

    private func updateGitButton(_ name: String, enabled: Bool) {
        if let btn = childNode(withName: "gitBtn_\(name)") as? SKShapeNode {
            btn.fillColor = enabled ? NSColor(white: 0.15, alpha: 1) : NSColor(white: 0.1, alpha: 0.5)
            btn.userData?["enabled"] = enabled
        }
    }

    private func showNotification(_ message: String) {
        let notification = SKNode()
        notification.zPosition = 100

        let bg = SKShapeNode(rectOf: CGSize(width: 500, height: 50), cornerRadius: 8)
        bg.fillColor = NSColor(red: 0.1, green: 0.15, blue: 0.2, alpha: 0.95)
        bg.strokeColor = C.blue
        bg.lineWidth = 2
        bg.position = CGPoint(x: size.width / 2, y: size.height - 120)
        notification.addChild(bg)

        let label = makeLabel(message, size: 15, color: C.text, bold: true)  // Increased
        label.position = bg.position
        notification.addChild(label)

        addChild(notification)

        // Auto-remove after 2 seconds
        notification.run(.sequence([
            .wait(forDuration: 2.0),
            .fadeOut(withDuration: 0.3),
            .removeFromParent()
        ]))
    }

    private func showBranchCreationUI() {
        let group = SKNode()
        group.name = "branchCreationUI"
        group.zPosition = 50

        // Semi-transparent background
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = NSColor(white: 0, alpha: 0.7)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        group.addChild(overlay)

        // Dialog box
        let dialog = SKShapeNode(rectOf: CGSize(width: 400, height: 250), cornerRadius: 16)
        dialog.fillColor = NSColor(red: 0.08, green: 0.1, blue: 0.14, alpha: 1)
        dialog.strokeColor = C.blue
        dialog.lineWidth = 2
        dialog.position = CGPoint(x: size.width / 2, y: size.height / 2)
        group.addChild(dialog)

        // Title
        let title = makeLabel("🎋 새 브랜치 생성", size: 19, color: C.blue, bold: true)  // Increased
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 90)
        group.addChild(title)

        // Current branch info
        let currentInfo = makeLabel("현재 브랜치: \(currentBranch)", size: 15, color: C.textDim)  // Increased
        currentInfo.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)
        group.addChild(currentInfo)

        // Predefined branch options
        let branchOptions = ["feature/new-feature", "bugfix/fix-issue", "hotfix/urgent"]
        let startY = size.height / 2 + 20

        for (index, branchName) in branchOptions.enumerated() {
            let btn = ButtonNode(text: branchName, width: 300, height: 40, color: C.purple, fontSize: 15)  // Increased
            btn.position = CGPoint(x: size.width / 2, y: startY - CGFloat(index) * 50)
            btn.action = { [weak self] in
                self?.createBranch(branchName)
                group.removeFromParent()
            }
            group.addChild(btn)
        }

        // Cancel button
        let cancelBtn = ButtonNode(text: "취소", width: 120, height: 36, color: NSColor(white: 0.3, alpha: 1), fontSize: 15)  // Increased
        cancelBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 - 100)
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
        showNotification("🎋 브랜치 생성: \(branchName)")

        // Update branch badge
        branchBadge.removeFromParent()
        branchBadge = makeBadge(branchName, color: C.branchColor(branchName))
        branchBadge.position = CGPoint(x: size.width - 620, y: size.height - topBarH/2)
        branchBadge.zPosition = 11
        addChild(branchBadge)
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
    
    // MARK: - 3-Column Layout Setup
    
    private func setupLeftPanel() {
        // ═══ 왼쪽 패널: Git UI ═══
        let panelHeight = size.height - topBarH - terminalH
        let midY = terminalH + panelHeight / 2
        
        // 패널 배경
        let gitPanelBg = SKShapeNode(rectOf: CGSize(width: gitPanelWidth - 10, height: panelHeight - 10), cornerRadius: 12)
        gitPanelBg.fillColor = NSColor(white: 0.03, alpha: 0.5)
        gitPanelBg.strokeColor = C.border
        gitPanelBg.lineWidth = 1
        gitPanelBg.position = CGPoint(x: gitPanelCenterX, y: midY)
        addChild(gitPanelBg)
        
        // 섹션 타이틀
        let gitTitle = makeLabel("📂 GIT STATUS", size: 15, color: C.blue, bold: true, mono: true)  // Increased
        gitTitle.position = CGPoint(x: gitPanelCenterX, y: size.height - topBarH - 25)
        addChild(gitTitle)

        // File system UI will be shown dynamically
        showFileSystemUI()
        
        // Divider 1
        let divider1 = SKShapeNode(rectOf: CGSize(width: 1, height: panelHeight))
        divider1.fillColor = C.border
        divider1.strokeColor = .clear
        divider1.position = CGPoint(x: gitPanelWidth, y: midY)
        addChild(divider1)
    }
    
    private func setupRightPanel() {
        // ═══ 가운데 패널: 로봇 조립 ═══
        let panelHeight = size.height - topBarH - terminalH
        let midY = terminalH + panelHeight / 2
        
        // 패널 배경
        let robotPanelBg = SKShapeNode(rectOf: CGSize(width: robotPanelWidth - 10, height: panelHeight - 10), cornerRadius: 12)
        robotPanelBg.fillColor = NSColor(white: 0.03, alpha: 0.5)
        robotPanelBg.strokeColor = C.border
        robotPanelBg.lineWidth = 1
        robotPanelBg.position = CGPoint(x: robotPanelCenterX, y: midY)
        addChild(robotPanelBg)
        
        // 섹션 타이틀
        let robotTitle = makeLabel("🤖 로봇 조립", size: 15, color: C.green, bold: true, mono: true)  // Increased
        robotTitle.position = CGPoint(x: robotPanelCenterX, y: size.height - topBarH - 25)
        addChild(robotTitle)
        
        // 로봇 (위쪽) - Positioned with calculated spacing to prevent overlap
        robotNode.position = CGPoint(x: robotPanelCenterX, y: robotCenterY)
        addChild(robotNode)

        // 부품 선택 영역 (아래쪽) - Positioned with calculated spacing above terminal
        assemblyZone.position = CGPoint(x: robotPanelCenterX, y: assemblyZoneCenterY)
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
        
        // Divider 2
        let divider2 = SKShapeNode(rectOf: CGSize(width: 1, height: panelHeight))
        divider2.fillColor = C.border
        divider2.strokeColor = .clear
        divider2.position = CGPoint(x: gitPanelWidth + robotPanelWidth, y: midY)
        addChild(divider2)
        
        // ═══ 오른쪽 패널: Git Graph ═══
        let graphPanelBg = SKShapeNode(rectOf: CGSize(width: graphPanelWidth - 10, height: panelHeight - 10), cornerRadius: 12)
        graphPanelBg.fillColor = NSColor(white: 0.03, alpha: 0.5)
        graphPanelBg.strokeColor = C.border
        graphPanelBg.lineWidth = 1
        graphPanelBg.position = CGPoint(x: graphPanelCenterX, y: midY)
        addChild(graphPanelBg)
        
        // Git Graph 타이틀
        let graphTitle = makeLabel("🌳 GIT GRAPH", size: 15, color: C.purple, bold: true, mono: true)  // Increased
        graphTitle.position = CGPoint(x: graphPanelCenterX, y: size.height - topBarH - 25)
        addChild(graphTitle)

        // Position git graph with more top padding (start from top, grow downward)
        gitGraph.position = CGPoint(x: gitPanelWidth + robotPanelWidth + 30, y: size.height - topBarH - 70)
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

        // Enable tutorial mode for Mission 1
        isTutorialMode = (missionId == 1)
        if isTutorialMode {
            currentTutorialStep = .dragPart
        }

        // Update UI
        phaseCounter.text = "Phase \(phaseIndex + 1)/\(mission.phases.count)"
        updateProgress()
        updateBranchBadge(phase.branchContext)
        
        // Mission goal moved to left panel (in File System UI)
        // Center panel now has more space for robot and parts
        childNode(withName: "missionHeader")?.removeFromParent()
        
        // Show assembly action
        actionDone = false
        currentGitState = .waiting
        assemblyZone.showAction(phase.assemblyAction)

        // Remove old explanation and goal indicators
        explanationGroup?.removeFromParent()
        explanationGroup = nil
        goalIndicators?.removeFromParent()
        goalIndicators = nil
        gitWorkflowUI?.removeFromParent()
        gitWorkflowUI = nil

        // Initialize TODO checklist for this phase
        initializeTodos(for: phase)

        // Update file system UI
        showFileSystemUI()
        
        // Show goal indicators (로봇 슬롯 하이라이트)
        showGoalIndicators(for: phase)

        // Show tutorial if Mission 1
        if isTutorialMode {
            showTutorialStep()
        }

        // Show TODO checklist
        showTodoChecklist()
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
            return "\(version) 태그 부착"
        case .shipRobot:
            return "로봇 출하"
        case .cleanupLine(let name):
            return "\(name) 라인 정리"
        case .emergencyFix(let part):
            return "긴급: \(part.name) 수리"
        }
    }
    
    private func updateBranchBadge(_ context: String) {
        branchBadge.removeFromParent()
        let branchName = context.components(separatedBy: " ").last ?? currentBranch
        branchBadge = makeBadge(branchName, color: C.branchColor(branchName))
        branchBadge.position = CGPoint(x: size.width - 620, y: size.height - topBarH/2)
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
        bg.position = CGPoint(x: leftWidth/2, y: (size.height - topBarH + terminalH) / 2)
        group.addChild(bg)
        
        let bulb = makeLabel("💡 Git 개념", size: 16, color: C.yellow, bold: true)  // Increased
        bulb.position = CGPoint(x: leftWidth/2, y: bg.position.y + 65)
        group.addChild(bulb)

        let exp = SKLabelNode(text: phase.explanation)
        exp.fontName = "Helvetica"
        exp.fontSize = 15  // Increased
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
                                size: 13, color: C.green, bold: true, mono: true)  // Increased
        cmdText.position = cmdBg.position
        group.addChild(cmdText)

        // Continue button
        let nextBtn = ButtonNode(text: "이해했어요! →", width: 160, height: 36, color: C.green, fontSize: 16)  // Increased
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

        // Remove goal indicators
        goalIndicators?.removeFromParent()
        goalIndicators = nil

        phaseIndex += 1

        if phaseIndex >= mission.phases.count {
            showReward()
        } else {
            showCurrentPhase()
        }
    }

    // MARK: - Goal Indicators (로봇 슬롯 하이라이트만)

    private func showGoalIndicators(for phase: MissionPhase) {
        // 목표 텍스트는 이제 missionHeader에 표시됨
        // 여기서는 로봇 슬롯 하이라이트만 처리
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
            // 다른 액션은 하이라이트 불필요
            break
        }

        if group.children.isEmpty {
            return  // 하이라이트 없으면 추가하지 않음
        }

        addChild(group)
        goalIndicators = group
        group.alpha = 0
        group.run(.fadeIn(withDuration: 0.3))
    }

    private func highlightTargetSlot(_ slot: PartSlot, in group: SKNode) {
        // Find the slot position on the robot
        guard let slotNode = robotNode.slots[slot] else { return }

        let slotPosition = robotNode.convert(slotNode.position, to: self)

        // Create pulsing highlight
        let size = slot == .torso ? CGSize(width: 60, height: 60) : CGSize(width: 52, height: 52)
        let highlight = SKShapeNode(rectOf: size, cornerRadius: 10)
        highlight.fillColor = .clear
        highlight.strokeColor = C.yellow.withAlphaComponent(0.9)
        highlight.lineWidth = 3
        highlight.glowWidth = 6
        highlight.position = slotPosition

        // Pulsing animation
        let pulse = SKAction.sequence([
            .group([
                .scale(to: 1.15, duration: 0.6),
                .fadeAlpha(to: 0.4, duration: 0.6)
            ]),
            .group([
                .scale(to: 1.0, duration: 0.6),
                .fadeAlpha(to: 1.0, duration: 0.6)
            ])
        ])
        highlight.run(.repeatForever(pulse))

        group.addChild(highlight)

        // Add arrow pointing to slot
        let arrow = makeLabel("⬇️", size: 24)
        arrow.position = CGPoint(x: slotPosition.x, y: slotPosition.y + 50)
        let float = SKAction.sequence([
            .moveBy(x: 0, y: -8, duration: 0.8),
            .moveBy(x: 0, y: 8, duration: 0.8)
        ])
        arrow.run(.repeatForever(float))
        group.addChild(arrow)
    }

    // addGoalLabel removed - 목표는 이제 missionHeader에 통합 표시

    // MARK: - Tutorial System

    private func showTutorialStep() {
        tutorialUI?.removeFromParent()
        tutorialUI = nil

        let group = SKNode()
        group.name = "tutorial"
        group.zPosition = 100

        let message: String
        let highlightArea: CGRect?
        let arrowPosition: CGPoint?
        let arrowDirection: String

        switch currentTutorialStep {
        case .dragPart:
            message = "1️⃣ 부품을 드래그해서\n로봇의 슬롯에 드롭하세요!"
            // Highlight: 가운데 로봇 조립 영역
            let robotAreaX = gitPanelWidth + 40
            let robotAreaWidth = robotPanelWidth - 80
            highlightArea = CGRect(x: robotAreaX, y: terminalH + 120, width: robotAreaWidth, height: 350)
            arrowPosition = CGPoint(x: robotPanelCenterX, y: terminalH + 500)
            arrowDirection = "⬇️"

        case .waitForModified:
            message = "2️⃣ 변경사항이 생겼습니다!\n파일 상태를 확인하세요"
            // Highlight: Working Directory 섹션
            highlightArea = CGRect(x: padding, y: fileSystemY - 80, width: gitPanelWidth - padding * 2, height: 90)
            arrowPosition = CGPoint(x: gitPanelWidth + 30, y: fileSystemY - 35)
            arrowDirection = "👈"

        case .clickStage:
            message = "3️⃣ [↑] 버튼을 눌러서\n변경사항을 Stage하세요"
            // Highlight: Stage 버튼 (파일 행 우측)
            highlightArea = CGRect(x: gitPanelWidth - padding - 50, y: fileSystemY - 70, width: 50, height: 35)
            arrowPosition = CGPoint(x: gitPanelWidth - padding - 70, y: fileSystemY - 52)
            arrowDirection = "➡️"

        case .waitForStaged:
            message = "4️⃣ Staging Area로 이동했습니다!\n이제 커밋할 준비가 되었어요"
            // Highlight: Staging Area 섹션
            highlightArea = CGRect(x: padding, y: fileSystemY - 200, width: gitPanelWidth - padding * 2, height: 90)
            arrowPosition = CGPoint(x: gitPanelWidth + 30, y: fileSystemY - 155)
            arrowDirection = "👈"

        case .enterCommitMsg:
            message = "5️⃣ 커밋 메시지를 입력하세요\n(박스를 클릭하면 입력 가능)"
            // Highlight: 커밋 메시지 입력 박스
            highlightArea = CGRect(x: padding, y: fileSystemY - 310, width: gitPanelWidth - padding * 2, height: 45)
            arrowPosition = CGPoint(x: gitPanelCenterX, y: fileSystemY - 260)
            arrowDirection = "⬇️"

        case .clickCommit:
            message = "6️⃣ [💾 Commit] 버튼을 눌러\n변경사항을 영구 기록하세요!"
            // Highlight: Commit 버튼
            highlightArea = CGRect(x: padding + 10, y: fileSystemY - 380, width: gitPanelWidth - padding * 2 - 20, height: 50)
            arrowPosition = CGPoint(x: gitPanelCenterX, y: fileSystemY - 320)
            arrowDirection = "⬇️"

        case .completed:
            return
        }

        // Create highlight overlay
        if let rect = highlightArea {
            let overlay = createTutorialOverlay(highlightRect: rect)
            group.addChild(overlay)
        }

        // Create message box - 화면 상단 중앙에 배치
        let messageBox = createTutorialMessageBox(message: message, at: CGPoint(x: size.width / 2, y: size.height - topBarH - 60))
        group.addChild(messageBox)

        // Create arrow
        if let arrowPos = arrowPosition {
            let arrow = makeLabel(arrowDirection, size: 32)
            arrow.position = arrowPos

            // Animate arrow
            let pulse = SKAction.sequence([
                .scale(to: 1.2, duration: 0.5),
                .scale(to: 1.0, duration: 0.5)
            ])
            arrow.run(.repeatForever(pulse))
            group.addChild(arrow)
        }

        addChild(group)
        tutorialUI = group
    }

    private func createTutorialOverlay(highlightRect: CGRect) -> SKNode {
        let overlay = SKNode()

        // Semi-transparent background covering everything
        let fullBg = SKShapeNode(rectOf: size)
        fullBg.fillColor = NSColor(white: 0, alpha: 0.7)
        fullBg.strokeColor = .clear
        fullBg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        fullBg.zPosition = -2
        overlay.addChild(fullBg)

        // Clear highlight area
        let highlight = SKShapeNode(rect: highlightRect, cornerRadius: 12)
        highlight.fillColor = .clear
        highlight.strokeColor = C.yellow
        highlight.lineWidth = 3
        highlight.glowWidth = 8
        highlight.zPosition = -1

        // Pulse animation
        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.6, duration: 0.8),
            .fadeAlpha(to: 1.0, duration: 0.8)
        ])
        highlight.run(.repeatForever(pulse))
        overlay.addChild(highlight)

        return overlay
    }

    private func createTutorialMessageBox(message: String, at position: CGPoint) -> SKNode {
        let box = SKNode()

        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: 380, height: 90), cornerRadius: 12)
        bg.fillColor = NSColor(red: 0.15, green: 0.2, blue: 0.3, alpha: 0.95)
        bg.strokeColor = C.yellow
        bg.lineWidth = 2
        bg.position = position
        box.addChild(bg)

        // Icon
        let icon = makeLabel("💡", size: 24)
        icon.position = CGPoint(x: position.x - 160, y: position.y + 10)
        box.addChild(icon)

        // Message
        let label = SKLabelNode(text: message)
        label.fontName = "Helvetica-Bold"
        label.fontSize = 13
        label.fontColor = C.yellow
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = 300
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: position.x + 10, y: position.y + 10)
        box.addChild(label)

        // Close hint
        let closeHint = makeLabel("💬 화면을 클릭하면 닫을 수 있어요", size: 12, color: NSColor(white: 0.6, alpha: 1))  // Increased
        closeHint.position = CGPoint(x: position.x, y: position.y - 30)
        box.addChild(closeHint)

        return box
    }

    private func hideTutorial() {
        tutorialUI?.run(.sequence([
            .fadeOut(withDuration: 0.2),
            .removeFromParent()
        ]))
        tutorialUI = nil
    }

    private func advanceTutorial() {
        switch currentTutorialStep {
        case .dragPart:
            currentTutorialStep = .waitForModified
        case .waitForModified:
            currentTutorialStep = .clickStage
        case .clickStage:
            currentTutorialStep = .waitForStaged
        case .waitForStaged:
            currentTutorialStep = .enterCommitMsg
        case .enterCommitMsg:
            currentTutorialStep = .clickCommit
        case .clickCommit:
            currentTutorialStep = .completed
            hideTutorial()
            return
        case .completed:
            return
        }

        showTutorialStep()
    }

    // MARK: - TODO Checklist System

    private func initializeTodos(for phase: MissionPhase) {
        currentTodos = []
        completedTodos = []

        // Define TODOs based on assembly action
        switch phase.assemblyAction {
        case .pickPart, .installPart, .emergencyFix:
            currentTodos = [.dragPart, .stage, .commitMessage, .commit]
        case .openWorkstation, .mergeParts, .resolveConflict, .tagVersion, .shipRobot, .cleanupLine:
            // These actions complete immediately
            currentTodos = []
        }
    }

    private func createChecklistNode(at position: CGPoint, panelWidth: CGFloat) -> SKNode {
        let group = SKNode()
        group.name = "todoChecklist"

        let itemHeight: CGFloat = 20
        let leftX: CGFloat = -(panelWidth / 2 - padding - 20)

        // 토글 버튼
        let toggleBtn = SKNode()
        toggleBtn.name = "checklistToggle"

        let toggleBg = SKShapeNode(rectOf: CGSize(width: panelWidth - padding * 2, height: 26), cornerRadius: 6)
        toggleBg.fillColor = C.purple.withAlphaComponent(0.15)
        toggleBg.strokeColor = C.purple.withAlphaComponent(0.5)
        toggleBg.lineWidth = 1
        toggleBtn.addChild(toggleBg)

        let toggleIcon = isChecklistVisible ? "▼" : "▶"
        let completedCount = completedTodos.count
        let totalCount = currentTodos.count
        let toggleLabel = makeLabel("\(toggleIcon) 체크리스트 \(completedCount)/\(totalCount)", size: 12, color: C.purple, bold: true, mono: true)  // Increased
        toggleBtn.addChild(toggleLabel)

        toggleBtn.position = CGPoint(x: 0, y: 0)
        group.addChild(toggleBtn)

        // 체크리스트 내용 - 아래로 펼쳐짐
        if isChecklistVisible {
            var yOffset: CGFloat = -18

            for (index, todo) in currentTodos.enumerated() {
                let isCompleted = completedTodos.contains(todo)
                let checkbox = isCompleted ? "✅" : "⬜"
                let todoText = getTodoText(for: todo)
                let color = isCompleted ? C.green : C.text

                let label = makeLabel("\(checkbox) \(index + 1). \(todoText)", size: 11, color: color, mono: true)  // Increased
                label.horizontalAlignmentMode = .left
                label.position = CGPoint(x: leftX, y: yOffset)
                group.addChild(label)

                yOffset -= itemHeight
            }
        }

        group.position = position
        return group
    }

    private func showTodoChecklist() {
        // Now handled inside showFileSystemUI()
        showFileSystemUI()
    }
    
    private func toggleChecklist() {
        isChecklistVisible.toggle()
        showFileSystemUI()  // Redraw entire file system UI with updated checklist state
    }

    private func getTodoText(for item: TodoItem) -> String {
        switch item {
        case .dragPart:
            return "부품을 로봇에 드롭"
        case .stage:
            return "변경사항 Stage"
        case .commitMessage:
            return "커밋 메시지 입력"
        case .commit:
            return "Commit 실행"
        }
    }

    private func completeTodo(_ item: TodoItem) {
        guard currentTodos.contains(item) else { return }
        completedTodos.insert(item)
        showTodoChecklist()

        // Check if all todos are completed
        if completedTodos.count == currentTodos.count {
            showAllTodosCompleted()
        }
    }

    private func showAllTodosCompleted() {
        // Show a completion message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showNotification("🎉 모든 작업 완료! 다음 단계로 진행합니다")
        }
    }

    // MARK: - File System UI

    private func showFileSystemUI() {
        fileSystemUI?.removeFromParent()
        fileSystemUI = nil

        let group = SKNode()
        group.name = "fileSystem"
        group.zPosition = 8

        let panelWidth = gitPanelWidth
        let centerX = gitPanelCenterX
        var startY = fileSystemY
        let leftX: CGFloat = padding + 8
        let sectionHeight: CGFloat = 26
        let fileRowHeight: CGFloat = 28
        let sectionSpacing: CGFloat = 20

        // Mission Goal at the top (moved from center panel)
        if phaseIndex < mission.phases.count {
            let phase = mission.phases[phaseIndex]
            let goalText = getGoalText(for: phase)

            // Position at very top of left panel
            let goalY = size.height - topBarH - 35

            let goalBg = SKShapeNode(rectOf: CGSize(width: panelWidth - padding * 2, height: 50), cornerRadius: 8)
            goalBg.fillColor = C.yellow.withAlphaComponent(0.1)
            goalBg.strokeColor = C.yellow.withAlphaComponent(0.3)
            goalBg.lineWidth = 1.5
            goalBg.position = CGPoint(x: centerX, y: goalY)
            group.addChild(goalBg)

            let goalIcon = makeLabel("🎯", size: 16)
            goalIcon.position = CGPoint(x: leftX + 10, y: goalY + 8)
            goalIcon.horizontalAlignmentMode = .left
            group.addChild(goalIcon)

            let goalLabel = makeLeftLabel(goalText, size: 13, color: C.yellow, bold: true)
            goalLabel.position = CGPoint(x: leftX + 30, y: goalY + 8)
            goalLabel.preferredMaxLayoutWidth = panelWidth - padding * 2 - 40
            goalLabel.numberOfLines = 1
            group.addChild(goalLabel)

            let instructLabel = makeLeftLabel(phase.instruction, size: 11, color: C.text)
            instructLabel.position = CGPoint(x: leftX + 10, y: goalY - 12)
            instructLabel.preferredMaxLayoutWidth = panelWidth - padding * 2 - 20
            instructLabel.numberOfLines = 1
            group.addChild(instructLabel)

            // Adjust startY to be below the goal section
            startY = goalY - 40
        }

        // Working Directory Section
        let workingBg = SKShapeNode(rectOf: CGSize(width: panelWidth - padding * 2, height: sectionHeight), cornerRadius: 6)
        workingBg.fillColor = C.orange.withAlphaComponent(0.12)
        workingBg.strokeColor = .clear
        workingBg.position = CGPoint(x: centerX, y: startY)
        group.addChild(workingBg)

        let workingTitle = makeLabel("📂 Working Directory", size: 14, color: C.orange, bold: true, mono: true)  // Increased
        workingTitle.position = CGPoint(x: centerX, y: startY)
        group.addChild(workingTitle)

        let modifiedFiles = files.filter { $0.status == .modified || $0.status == .untracked }
        var yOffset = startY - 28

        if modifiedFiles.isEmpty {
            let noChanges = makeLabel("✓ clean", size: 13, color: C.green)  // Increased
            noChanges.horizontalAlignmentMode = .left
            noChanges.position = CGPoint(x: leftX + 12, y: yOffset)
            group.addChild(noChanges)
            yOffset -= 26
        } else {
            for file in modifiedFiles {
                let fileNode = createFileRow(file: file, x: leftX + 12, y: yOffset, isStaged: false, panelWidth: panelWidth)
                group.addChild(fileNode)
                yOffset -= fileRowHeight
            }
        }

        // Staging Area Section
        yOffset -= sectionSpacing + 4
        let stagingBg = SKShapeNode(rectOf: CGSize(width: panelWidth - padding * 2, height: sectionHeight), cornerRadius: 6)
        stagingBg.fillColor = C.green.withAlphaComponent(0.12)
        stagingBg.strokeColor = .clear
        stagingBg.position = CGPoint(x: centerX, y: yOffset)
        group.addChild(stagingBg)

        let stagingTitle = makeLabel("📦 Staging Area", size: 14, color: C.green, bold: true, mono: true)  // Increased
        stagingTitle.position = CGPoint(x: centerX, y: yOffset)
        group.addChild(stagingTitle)

        let stagedFiles = files.filter { $0.status == .staged }
        yOffset -= 30

        if stagedFiles.isEmpty {
            let noStaged = makeLabel("→ 없음", size: 13, color: C.textFaint)  // Increased
            noStaged.horizontalAlignmentMode = .left
            noStaged.position = CGPoint(x: leftX + 12, y: yOffset)
            group.addChild(noStaged)
            yOffset -= 26
        } else {
            for file in stagedFiles {
                let fileNode = createFileRow(file: file, x: leftX + 12, y: yOffset, isStaged: true, panelWidth: panelWidth)
                group.addChild(fileNode)
                yOffset -= fileRowHeight
            }
        }

        // Commit Section
        yOffset -= sectionSpacing + 4
        let commitBg = SKShapeNode(rectOf: CGSize(width: panelWidth - padding * 2, height: sectionHeight), cornerRadius: 6)
        commitBg.fillColor = C.blue.withAlphaComponent(0.12)
        commitBg.strokeColor = .clear
        commitBg.position = CGPoint(x: centerX, y: yOffset)
        group.addChild(commitBg)

        let commitTitle = makeLabel("💾 Commit", size: 14, color: C.blue, bold: true, mono: true)  // Increased
        commitTitle.position = CGPoint(x: centerX, y: yOffset)
        group.addChild(commitTitle)

        yOffset -= 32

        // Commit message input
        let msgBg = SKShapeNode(rectOf: CGSize(width: panelWidth - padding * 2 - 8, height: 38), cornerRadius: 6)
        msgBg.fillColor = NSColor(white: 0.06, alpha: 1)
        msgBg.strokeColor = stagedFiles.isEmpty ? C.border : C.blue
        msgBg.lineWidth = 1
        msgBg.position = CGPoint(x: centerX, y: yOffset - 19)
        msgBg.name = "commitMsgBg"
        group.addChild(msgBg)

        let msgPlaceholder = makeLabel(
            commitMessageText.isEmpty ? "메시지 입력..." : commitMessageText,
            size: 13,  // Increased
            color: commitMessageText.isEmpty ? C.textFaint : C.text,
            mono: true
        )
        msgPlaceholder.position = CGPoint(x: centerX, y: yOffset - 19)
        msgPlaceholder.name = "commitMsgLabel"
        group.addChild(msgPlaceholder)

        yOffset -= 58

        // Commit button
        let commitBtn = ButtonNode(
            text: "💾 Commit",
            width: panelWidth - padding * 2 - 8,
            height: 40,
            color: stagedFiles.isEmpty ? NSColor(white: 0.15, alpha: 0.5) : C.green,
            fontSize: 16  // Increased
        )
        commitBtn.position = CGPoint(x: centerX, y: yOffset - 20)
        commitBtn.name = "commitButton"
        if !stagedFiles.isEmpty {
            commitBtn.action = { [weak self] in self?.performCommit() }
        }
        group.addChild(commitBtn)

        // Add TODO checklist below commit button
        if !currentTodos.isEmpty {
            yOffset -= 70
            let checklistNode = createChecklistNode(at: CGPoint(x: centerX, y: yOffset), panelWidth: panelWidth)
            group.addChild(checklistNode)
        }

        addChild(group)
        fileSystemUI = group

        // Tutorial: auto-advance when file appears in Working Directory
        if isTutorialMode && currentTutorialStep == .waitForModified {
            if !modifiedFiles.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.advanceTutorial()
                }
            }
        }

        // Tutorial: auto-advance when file appears in Staging Area
        if isTutorialMode && currentTutorialStep == .waitForStaged {
            if !stagedFiles.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.advanceTutorial()
                }
            }
        }
    }

    private func createFileRow(file: GitFile, x: CGFloat, y: CGFloat, isStaged: Bool, panelWidth: CGFloat? = nil) -> SKNode {
        let row = SKNode()
        let pWidth = panelWidth ?? gitPanelWidth
        let centerX = pWidth / 2

        // Row background (make it clickable)
        let rowBg = SKShapeNode(rectOf: CGSize(width: pWidth - padding * 2 - 16, height: 24), cornerRadius: 5)
        rowBg.fillColor = NSColor(white: 0.04, alpha: 0.5)
        rowBg.strokeColor = .clear
        rowBg.position = CGPoint(x: centerX, y: y)
        rowBg.name = "fileRow_\(file.name)"
        rowBg.userData = NSMutableDictionary()
        rowBg.userData?["fileName"] = file.name
        row.addChild(rowBg)

        // Status indicator with badge
        let statusText: String
        let statusColor: NSColor
        switch file.status {
        case .untracked:
            statusText = "??"
            statusColor = C.purple
        case .modified:
            statusText = " M"
            statusColor = C.orange
        case .staged:
            statusText = " A"
            statusColor = C.green
        case .committed:
            statusText = "  "
            statusColor = C.textFaint
        }

        let statusBadge = SKShapeNode(rectOf: CGSize(width: 28, height: 18), cornerRadius: 4)
        statusBadge.fillColor = statusColor.withAlphaComponent(0.2)
        statusBadge.strokeColor = statusColor.withAlphaComponent(0.5)
        statusBadge.lineWidth = 1
        statusBadge.position = CGPoint(x: x + 18, y: y)
        row.addChild(statusBadge)

        let status = makeLabel(statusText, size: 11, color: statusColor, bold: true, mono: true)  // Increased
        status.position = CGPoint(x: x + 18, y: y)
        row.addChild(status)

        // File name
        let fileName = makeLabel(file.name, size: 13, color: C.text, mono: true)  // Increased
        fileName.horizontalAlignmentMode = .left
        fileName.position = CGPoint(x: x + 44, y: y)
        row.addChild(fileName)

        // Click hint (show if file has been modified)
        if file.status == .modified || file.status == .staged {
            let hintIcon = makeLabel("📝", size: 12)  // Increased
            hintIcon.position = CGPoint(x: pWidth - padding - 65, y: y)
            row.addChild(hintIcon)
        }

        // Stage/Unstage button
        let btnText = isStaged ? "↓" : "↑"
        let btnColor = isStaged ? C.orange : C.green
        let btnWidth: CGFloat = 30
        let btnHeight: CGFloat = 20

        let btn = SKShapeNode(rectOf: CGSize(width: btnWidth, height: btnHeight), cornerRadius: 5)
        btn.fillColor = btnColor.withAlphaComponent(0.25)
        btn.strokeColor = btnColor.withAlphaComponent(0.8)
        btn.lineWidth = 1
        btn.position = CGPoint(x: pWidth - padding - 28, y: y)
        btn.name = "stageBtn_\(file.name)"
        btn.userData = NSMutableDictionary()
        btn.userData?["fileName"] = file.name
        btn.userData?["isStaged"] = isStaged
        row.addChild(btn)

        let btnLabel = makeLabel(btnText, size: 15, color: btnColor, bold: true)  // Increased
        btnLabel.position = CGPoint(x: pWidth - padding - 28, y: y)
        row.addChild(btnLabel)

        return row
    }

    private func performCommit() {
        let stagedFiles = files.filter { $0.status == .staged }
        guard !stagedFiles.isEmpty else { return }

        // Commit the staged files
        for index in files.indices {
            if files[index].status == .staged {
                files[index].status = .committed
                // Clear previous content after commit (changes are now baseline)
                files[index].previousContent = files[index].content
            }
        }

        // Use default message if empty
        let message = commitMessageText.isEmpty ? "로봇 부품 업데이트" : commitMessageText
        commitMessageText = ""

        // Add to terminal
        terminal.addCommand("git commit -m \"\(message)\"")

        // Add to git graph
        let branchName = currentBranch
        gitGraph.addEntry(branch: branchName, label: message, type: "commit")

        // Record in history
        let entry = GitHistoryEntry(part: nil, action: "commit", branchName: currentBranch)
        if historyIndex < gitHistory.count - 1 {
            gitHistory = Array(gitHistory[0...historyIndex])
        }
        gitHistory.append(entry)
        historyIndex = gitHistory.count - 1
        updateGitButton("undo", enabled: true)

        // Update UI
        currentGitState = .committed
        showFileSystemUI()
        showNotification("✅ 커밋 완료: \(message)")

        // Complete TODO: commit
        completeTodo(.commit)

        // Tutorial: complete after commit
        if isTutorialMode && currentTutorialStep == .clickCommit {
            advanceTutorial()
        }

        // Complete the current phase
        if !actionDone {
            actionDone = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.completePhaseWithExplanation()
            }
        }
    }

    private func completePhaseWithExplanation() {
        guard phaseIndex < mission.phases.count else { return }
        let phase = mission.phases[phaseIndex]
        showExplanation(phase)
    }

    // MARK: - Git Workflow UI

    private func showGitWorkflowUI() {
        // Remove previous workflow UI
        gitWorkflowUI?.removeFromParent()
        gitWorkflowUI = nil

        let group = SKNode()
        group.name = "gitWorkflow"
        group.zPosition = 18

        let cx = leftWidth / 2
        let cy = (size.height - topBarH + terminalH) / 2 - 50

        switch currentGitState {
        case .waiting:
            // No UI needed
            return

        case .modified:
            // Show "Changes in Working Directory"
            let statusBg = SKShapeNode(rectOf: CGSize(width: 360, height: 50), cornerRadius: 10)
            statusBg.fillColor = C.orange.withAlphaComponent(0.1)
            statusBg.strokeColor = C.orange.withAlphaComponent(0.5)
            statusBg.lineWidth = 2
            statusBg.position = CGPoint(x: cx, y: cy + 60)
            group.addChild(statusBg)

            let statusLabel = makeLabel("📝 Working Directory: 변경사항 있음", size: 15, color: C.orange, bold: true)  // Increased
            statusLabel.position = CGPoint(x: cx, y: cy + 60)
            group.addChild(statusLabel)

            // Stage button
            let stageBtn = ButtonNode(text: "📦 Stage (git add)", width: 200, height: 44, color: C.blue, fontSize: 16)  // Increased
            stageBtn.position = CGPoint(x: cx, y: cy + 10)
            stageBtn.action = { [weak self] in self?.handleStage() }
            group.addChild(stageBtn)

            let hint = makeLabel("💡 Stage하면 커밋 준비 완료", size: 13, color: C.textDim)  // Increased
            hint.position = CGPoint(x: cx, y: cy - 20)
            group.addChild(hint)

        case .staged:
            // Show "Changes Staged"
            let statusBg = SKShapeNode(rectOf: CGSize(width: 360, height: 50), cornerRadius: 10)
            statusBg.fillColor = C.green.withAlphaComponent(0.1)
            statusBg.strokeColor = C.green.withAlphaComponent(0.5)
            statusBg.lineWidth = 2
            statusBg.position = CGPoint(x: cx, y: cy + 60)
            group.addChild(statusBg)

            let statusLabel = makeLabel("✅ Staging Area: 커밋 준비 완료", size: 15, color: C.green, bold: true)  // Increased
            statusLabel.position = CGPoint(x: cx, y: cy + 60)
            group.addChild(statusLabel)

            // Commit button
            let commitBtn = ButtonNode(text: "💾 Commit", width: 200, height: 44, color: C.green, fontSize: 17)  // Increased
            commitBtn.position = CGPoint(x: cx, y: cy + 10)
            commitBtn.action = { [weak self] in self?.handleCommit() }
            group.addChild(commitBtn)

            let hint = makeLabel("💡 커밋하면 영구 기록됩니다", size: 13, color: C.textDim)  // Increased
            hint.position = CGPoint(x: cx, y: cy - 20)
            group.addChild(hint)

        case .committed:
            // This state is handled by completePhaseAction
            return
        }

        // Fade in
        group.alpha = 0
        group.run(.fadeIn(withDuration: 0.3))

        addChild(group)
        gitWorkflowUI = group
    }

    private func handleStage() {
        guard phaseIndex < mission.phases.count else { return }
        let phase = mission.phases[phaseIndex]

        currentGitState = .staged

        // Add git add command to terminal
        terminal.addCommand("git add .")

        // Update UI
        showGitWorkflowUI()
    }

    private func handleCommit() {
        guard phaseIndex < mission.phases.count else { return }
        let phase = mission.phases[phaseIndex]

        currentGitState = .committed

        // Record in git history
        let entry = GitHistoryEntry(part: nil, action: "commit", branchName: currentBranch)

        // Truncate history if we're not at the end (for redo)
        if historyIndex < gitHistory.count - 1 {
            gitHistory = Array(gitHistory[0...historyIndex])
        }

        gitHistory.append(entry)
        historyIndex = gitHistory.count - 1

        // Enable undo button
        updateGitButton("undo", enabled: true)
        updateGitButton("redo", enabled: false)

        // Remove workflow UI
        gitWorkflowUI?.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
        gitWorkflowUI = nil

        // Complete the phase (add commit to terminal and git graph)
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
        childNode(withName: "instructionPrefix")?.removeFromParent()
        childNode(withName: "missionHeader")?.removeFromParent()
        
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
        let name = makeLabel(mission.rewardName, size: 17, color: C.textDim, bold: true)  // Increased
        name.position = CGPoint(x: cx, y: cy + 10)
        group.addChild(name)

        // Stars
        for i in 0..<mission.stars {
            let star = SKLabelNode(text: "★")
            star.fontSize = 26  // Increased
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
        let complete = makeLabel("미션 완료! 🎉", size: 21, color: C.green, bold: true)  // Increased
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
        lesson.fontSize = 14  // Increased
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

        // Update file status and content
        if let index = files.firstIndex(where: { $0.partSlot == part.slot }) {
            // Save previous content for diff
            files[index].previousContent = files[index].content

            // Update content with accumulated parts
            let allParts = robotNode.getInstalledParts(for: part.slot)
            files[index].content = generateFileContent(for: part.slot, parts: allParts)
            files[index].status = .modified
        }

        // Don't commit immediately - show staging workflow
        currentGitState = .modified
        showFileSystemUI()  // Update file system UI
        // Enable stash button when there are changes
        updateGitButton("stash", enabled: true)
    }

    private func generateFileContent(for slot: PartSlot, parts: [RobotPart]) -> [String] {
        var lines: [String] = []
        lines.append("// \(slot.label) 파일")
        lines.append("")

        for (index, part) in parts.enumerated() {
            lines.append("// 부품 \(index + 1): \(part.name)")
            lines.append("struct \(part.id.capitalized)Part {")
            lines.append("    let name = \"\(part.name)\"")
            lines.append("    let emoji = \"\(part.emoji)\"")
            lines.append("    let slot = .\(slot.rawValue)")
            lines.append("}")
            lines.append("")
        }

        return lines
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
        // Emergency fix also uses staging workflow
        currentGitState = .modified
        showGitWorkflowUI()
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

                // Tutorial: hide when user starts dragging
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

        // 2. If we started dragging but didn't create ghost (below threshold), just cleanup
        // Don't treat as click - require full drag & drop
        if draggedCard != nil {
            cleanupDrag()
            return
        }

        // 3. Normal click handling (buttons, etc. - but NOT part cards)
        let allNodes = nodes(at: loc)
        for node in allNodes {
            // Check diff overlay (close popup)
            if node.name == "diffOverlay" {
                node.parent?.removeFromParent()
                return
            }
            // Check checklist toggle button
            if node.name == "checklistToggle" || node.parent?.name == "checklistToggle" {
                toggleChecklist()
                return
            }
            // Check file row clicks (for diff view)
            if let fileRow = node as? SKShapeNode, let name = fileRow.name, name.hasPrefix("fileRow_") {
                if let fileName = fileRow.userData?["fileName"] as? String {
                    showFileDiff(fileName: fileName)
                    return
                }
            }
            // Check stage/unstage buttons
            if let stageBtn = node as? SKShapeNode, let name = stageBtn.name, name.hasPrefix("stageBtn_") {
                if let fileName = stageBtn.userData?["fileName"] as? String,
                   let isStaged = stageBtn.userData?["isStaged"] as? Bool {
                    // Tutorial: hide when user clicks stage button
                    if isTutorialMode && currentTutorialStep == .clickStage {
                        hideTutorial()
                    }
                    handleStageToggle(fileName: fileName, isStaged: isStaged)
                    return
                }
            }
            // Check commit message input
            if let msgNode = node as? SKShapeNode, msgNode.name == "commitMsgBg" {
                // Tutorial: hide when user clicks commit message box
                if isTutorialMode && currentTutorialStep == .enterCommitMsg {
                    hideTutorial()
                }
                showCommitMessageInput()
                return
            }
            // Check Git toolbar buttons
            if let gitBtn = node as? SKShapeNode, let name = gitBtn.name, name.hasPrefix("gitBtn_") {
                if let enabled = gitBtn.userData?["enabled"] as? Bool, enabled,
                   let action = gitBtn.userData?["action"] as? Selector {
                    perform(action)
                    return
                }
            }
            // Check ButtonNode
            if let btn = findButton(in: node) {
                // Tutorial: hide when user clicks commit button
                if isTutorialMode && currentTutorialStep == .clickCommit && btn.name == "commitButton" {
                    hideTutorial()
                }
                btn.action?()
                return
            }
            // PartCardNode clicks are DISABLED - must use drag & drop
            // Check MergeCardNode
            if let merge = findMergeCard(in: node) {
                merge.onMerge?()
                return
            }
        }

        // If tutorial is showing and user clicks anywhere, hide it
        if isTutorialMode && tutorialUI != nil {
            hideTutorial()
        }
    }

    private func showFileDiff(fileName: String) {
        guard let file = files.first(where: { $0.name == fileName }) else { return }

        // Get current state from robot (real-time)
        let currentParts = robotNode.getInstalledParts(for: file.partSlot)
        let currentContent = generateFileContent(for: file.partSlot, parts: currentParts)

        // Create diff popup
        let popup = SKNode()
        popup.name = "diffPopup"
        popup.zPosition = 200

        // Semi-transparent overlay (clickable to close)
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = NSColor(white: 0, alpha: 0.7)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.name = "diffOverlay"
        popup.addChild(overlay)

        // Diff panel
        let panelWidth: CGFloat = 600
        let panelHeight: CGFloat = 400
        let panel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 12)
        panel.fillColor = NSColor(red: 0.08, green: 0.1, blue: 0.14, alpha: 1)
        panel.strokeColor = C.blue
        panel.lineWidth = 2
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        popup.addChild(panel)

        // Title
        let title = makeLabel("📄 \(fileName) - 파일 내용", size: 16, color: C.blue, bold: true, mono: true)  // Increased
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + panelHeight / 2 - 25)
        popup.addChild(title)

        // Subtitle with part count
        let subtitle = makeLabel("📦 현재 \(currentParts.count)개 부품 포함", size: 13, color: C.textDim, mono: true)  // Increased
        subtitle.position = CGPoint(x: size.width / 2, y: size.height / 2 + panelHeight / 2 - 45)
        popup.addChild(subtitle)

        // File content (show current state)
        let contentStartY = size.height / 2 + panelHeight / 2 - 70
        var yOffset = contentStartY

        // Show file content (all lines)
        if currentContent.isEmpty || currentParts.isEmpty {
            let emptyMsg = makeLabel("아직 부품이 설치되지 않았습니다", size: 14, color: C.textDim)  // Increased
            emptyMsg.position = CGPoint(x: size.width / 2, y: size.height / 2)
            popup.addChild(emptyMsg)
        } else {
            // Generate diff to show what changed
            let diffLines = generateDiffLines(previousContent: file.previousContent, currentContent: currentContent)

            for diffLine in diffLines.prefix(18) {  // Show first 18 lines
                let lineLabel = makeLabel(diffLine.text, size: 11, color: diffLine.color, mono: true)  // Increased
                lineLabel.horizontalAlignmentMode = .left
                lineLabel.position = CGPoint(x: size.width / 2 - panelWidth / 2 + 20, y: yOffset)
                popup.addChild(lineLabel)
                yOffset -= 14
            }

            // Add scroll hint if there are more lines
            if diffLines.count > 18 {
                let moreHint = makeLabel("... 외 \(diffLines.count - 18)줄", size: 11, color: C.textFaint, mono: true)  // Increased
                moreHint.position = CGPoint(x: size.width / 2, y: yOffset - 10)
                popup.addChild(moreHint)
            }
        }

        // Close button
        let closeBtn = ButtonNode(text: "✕ 닫기", width: 100, height: 36, color: NSColor(white: 0.3, alpha: 1), fontSize: 15)  // Increased
        closeBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 - panelHeight / 2 + 30)
        closeBtn.action = { [weak self] in
            popup.removeFromParent()
        }
        popup.addChild(closeBtn)

        addChild(popup)
    }

    private struct DiffLine {
        let text: String
        let color: NSColor
    }

    private func generateDiffLines(previousContent: [String], currentContent: [String]) -> [DiffLine] {
        var lines: [DiffLine] = []

        // If no previous content, show all as new (green)
        if previousContent.isEmpty {
            for line in currentContent {
                let color = line.hasPrefix("//") || line.isEmpty ? C.textDim : NSColor.green.withAlphaComponent(0.8)
                let prefix = line.hasPrefix("//") || line.isEmpty ? "  " : "+ "
                lines.append(DiffLine(text: "\(prefix)\(line)", color: color))
            }
            return lines
        }

        // Better diff: show line-by-line comparison
        let prevSet = Set(previousContent)
        let currSet = Set(currentContent)

        // First, show removed lines
        for line in previousContent {
            if !currSet.contains(line) && !line.isEmpty {
                lines.append(DiffLine(text: "- \(line)", color: NSColor.red.withAlphaComponent(0.7)))
            }
        }

        // Then show current content with proper coloring
        for line in currentContent {
            if !prevSet.contains(line) && !line.isEmpty && !line.hasPrefix("//") {
                // New line (green)
                lines.append(DiffLine(text: "+ \(line)", color: NSColor.green.withAlphaComponent(0.8)))
            } else {
                // Unchanged line (show for context)
                lines.append(DiffLine(text: "  \(line)", color: C.textDim))
            }
        }

        return lines
    }

    private func handleStageToggle(fileName: String, isStaged: Bool) {
        guard let index = files.firstIndex(where: { $0.name == fileName }) else { return }

        if isStaged {
            // Unstage: staged → modified
            files[index].status = .modified
            terminal.addCommand("git restore --staged \(fileName)")
            showNotification("↓ Unstage: \(fileName)")
        } else {
            // Stage: modified → staged
            files[index].status = .staged
            terminal.addCommand("git add \(fileName)")
            showNotification("↑ Stage: \(fileName)")

            // Complete TODO: stage
            completeTodo(.stage)

            // Tutorial: advance after staging
            if isTutorialMode && currentTutorialStep == .clickStage {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.advanceTutorial()
                }
            }
        }

        showFileSystemUI()
    }

    // Initialize file contents
    private func initializeFileContents() {
        for index in files.indices {
            let slot = files[index].partSlot
            let parts = robotNode.getInstalledParts(for: slot)
            files[index].content = generateFileContent(for: slot, parts: parts)
            files[index].previousContent = files[index].content
        }
    }

    private func showCommitMessageInput() {
        // Create a simple dialog for commit message input
        let alert = NSAlert()
        alert.messageText = "커밋 메시지"
        alert.informativeText = "변경사항을 설명하는 메시지를 입력하세요"
        alert.addButton(withTitle: "확인")
        alert.addButton(withTitle: "취소")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        input.stringValue = commitMessageText
        input.placeholderString = "예: 로봇 머리 부품 추가"
        alert.accessoryView = input

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            commitMessageText = input.stringValue
            showFileSystemUI()

            // Complete TODO: commit message
            completeTodo(.commitMessage)

            // Tutorial: advance after entering message
            if isTutorialMode && currentTutorialStep == .enterCommitMsg {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.advanceTutorial()
                }
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

            // Install part
            robotNode.installPart(card.part)

            // Update file status - THIS WAS MISSING!
            if let index = files.firstIndex(where: { $0.partSlot == card.part.slot }) {
                files[index].status = .modified
                currentGitState = .modified
                showFileSystemUI()
                updateGitButton("stash", enabled: true)

                // Complete TODO: drag part
                completeTodo(.dragPart)

                // Tutorial: advance after drop
                if isTutorialMode && currentTutorialStep == .dragPart {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.advanceTutorial()
                    }
                }
            }

            // Don't auto-complete phase anymore - user must stage and commit
            // completePhaseAction()
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
