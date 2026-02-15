import SpriteKit

class AssemblyZone: SKNode {
    var onPartSelected: ((RobotPart) -> Void)?
    var onWorkstationOpened: ((String) -> Void)?
    var onMerge: ((String, String) -> Void)?
    var onConflictResolved: (() -> Void)?
    var onTagged: ((String) -> Void)?
    var onShipped: (() -> Void)?
    var onCleanup: ((String) -> Void)?
    var onEmergencyFix: ((RobotPart) -> Void)?
    
    private var currentNodes: [SKNode] = []
    
    override init() {
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    func showAction(_ action: AssemblyAction) {
        clearCurrent()
        
        switch action {
        case .pickPart(let parts):
            showPartPicker(parts)
        case .openWorkstation(let name):
            showWorkstationOpener(name)
        case .installPart(let part):
            showPartInstaller(part)
        case .mergeParts(let from, let to):
            showMergeUI(from: from, to: to)
        case .resolveConflict(let a, let b):
            showConflictUI(a, b)
        case .tagVersion(let ver):
            showTagUI(ver)
        case .shipRobot:
            showShipUI()
        case .cleanupLine(let name):
            showCleanupUI(name)
        case .emergencyFix(let part):
            showEmergencyUI(part)
        }
    }
    
    func clearCurrent() {
        for node in currentNodes {
            node.run(.sequence([.fadeOut(withDuration: 0.15), .removeFromParent()]))
        }
        currentNodes = []
    }
    
    // MARK: - Part Picker
    private func showPartPicker(_ parts: [RobotPart]) {
        let title = makeLabel("부품을 선택하세요", size: 18, color: C.textDim, bold: true)  // Increased for better visibility
        title.position = CGPoint(x: 0, y: -105)  // Positioned just above the part cards
        addChild(title)
        currentNodes.append(title)

        let spacing: CGFloat = 130  // Reduced to fit within center panel (420 width)
        let startX = -CGFloat(parts.count - 1) * spacing / 2

        for (i, part) in parts.enumerated() {
            let card = PartCardNode(part: part)
            card.position = CGPoint(x: startX + CGFloat(i) * spacing, y: -175)  // Positioned below title with more space
            card.onSelect = { [weak self] p in
                self?.onPartSelected?(p)
            }
            
            // Animate in
            card.alpha = 0
            card.setScale(0.8)
            card.run(.group([
                .fadeIn(withDuration: 0.2),
                .scale(to: 1.0, duration: 0.2)
            ]))
            
            addChild(card)
            currentNodes.append(card)
        }
        
        let hint = makeLabel("💡 부품을 드래그해서 로봇 슬롯에 드롭하세요", size: 12, color: C.textFaint)
        hint.position = CGPoint(x: 0, y: -80)
        addChild(hint)
        currentNodes.append(hint)
    }
    
    // MARK: - Workstation Opener
    private func showWorkstationOpener(_ name: String) {
        let title = makeLabel("새 워크스테이션 개설", size: 17, color: C.textDim, bold: true)
        title.position = CGPoint(x: 0, y: 60)
        addChild(title)
        currentNodes.append(title)

        let btn = ButtonNode(text: "🔀  \(name)", width: 260, height: 50, color: C.branchColor(name), fontSize: 16)
        btn.position = CGPoint(x: 0, y: 0)
        btn.action = { [weak self] in self?.onWorkstationOpened?(name) }
        
        btn.alpha = 0; btn.setScale(0.8)
        btn.run(.group([.fadeIn(withDuration: 0.2), .scale(to: 1.0, duration: 0.2)]))
        
        addChild(btn)
        currentNodes.append(btn)
        
        let hint = makeLabel("클릭하여 개설", size: 13, color: C.textFaint)
        hint.position = CGPoint(x: 0, y: -40)
        addChild(hint)
        currentNodes.append(hint)
    }
    
    // MARK: - Part Installer
    private func showPartInstaller(_ part: RobotPart) {
        let card = PartCardNode(part: part, cardSize: CGSize(width: 140, height: 150))
        card.position = CGPoint(x: 0, y: 0)
        card.onSelect = { [weak self] p in self?.onPartSelected?(p) }
        
        card.alpha = 0; card.setScale(0.8)
        card.run(.group([.fadeIn(withDuration: 0.2), .scale(to: 1.0, duration: 0.2)]))
        
        addChild(card)
        currentNodes.append(card)
    }
    
    // MARK: - Merge UI
    private func showMergeUI(from: String, to: String) {
        let mergeCard = MergeCardNode(from: from, to: to)
        mergeCard.position = CGPoint(x: 0, y: 0)
        mergeCard.onMerge = { [weak self] in self?.onMerge?(from, to) }
        
        mergeCard.alpha = 0; mergeCard.setScale(0.8)
        mergeCard.run(.group([.fadeIn(withDuration: 0.2), .scale(to: 1.0, duration: 0.2)]))
        
        addChild(mergeCard)
        currentNodes.append(mergeCard)
    }
    
    // MARK: - Conflict UI
    private func showConflictUI(_ partA: RobotPart, _ partB: RobotPart) {
        let alert = makeLabel("⚡ MERGE CONFLICT!", size: 22, color: C.red, bold: true)
        alert.position = CGPoint(x: 0, y: 60)
        alert.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.5, duration: 0.5),
            .fadeAlpha(to: 1.0, duration: 0.5)
        ])))
        addChild(alert)
        currentNodes.append(alert)

        let desc = makeLabel("포트A를 두 부품이 동시에 사용!", size: 15, color: C.orange)
        desc.position = CGPoint(x: 0, y: 35)
        addChild(desc)
        currentNodes.append(desc)

        // Show both parts
        let aLabel = makeLabel("\(partA.emoji) \(partA.name) → 포트A 유지", size: 15, color: C.green, bold: true)
        aLabel.position = CGPoint(x: 0, y: 5)
        addChild(aLabel)
        currentNodes.append(aLabel)

        let bLabel = makeLabel("\(partB.emoji) \(partB.name) → 포트B로 이동", size: 15, color: C.orange, bold: true)
        bLabel.position = CGPoint(x: 0, y: -18)
        addChild(bLabel)
        currentNodes.append(bLabel)

        let btn = ButtonNode(text: "✅ 이렇게 해결!", width: 200, height: 44, color: C.green, fontSize: 16)
        btn.position = CGPoint(x: 0, y: -55)
        btn.action = { [weak self] in self?.onConflictResolved?() }
        addChild(btn)
        currentNodes.append(btn)
    }
    
    // MARK: - Tag UI
    private func showTagUI(_ version: String) {
        let emoji = makeEmoji("🏷️", size: 52)
        emoji.position = CGPoint(x: 0, y: 25)
        addChild(emoji)
        currentNodes.append(emoji)

        let btn = ButtonNode(text: version, width: 160, height: 44, color: C.yellow, fontSize: 20)
        btn.position = CGPoint(x: 0, y: -30)
        btn.action = { [weak self] in self?.onTagged?(version) }
        
        btn.alpha = 0; btn.setScale(0.8)
        btn.run(.group([.fadeIn(withDuration: 0.2), .scale(to: 1.0, duration: 0.2)]))
        addChild(btn)
        currentNodes.append(btn)
    }
    
    // MARK: - Ship UI
    private func showShipUI() {
        let emoji = makeEmoji("📦", size: 52)
        emoji.position = CGPoint(x: 0, y: 25)
        addChild(emoji)
        currentNodes.append(emoji)

        let btn = ButtonNode(text: "📦 main에 출하!", width: 220, height: 50, color: C.green, fontSize: 17)
        btn.position = CGPoint(x: 0, y: -30)
        btn.action = { [weak self] in self?.onShipped?() }
        
        btn.alpha = 0; btn.setScale(0.8)
        btn.run(.group([.fadeIn(withDuration: 0.2), .scale(to: 1.0, duration: 0.2)]))
        addChild(btn)
        currentNodes.append(btn)
    }
    
    // MARK: - Cleanup UI
    private func showCleanupUI(_ name: String) {
        let emoji = makeEmoji("🧹", size: 48)
        emoji.position = CGPoint(x: 0, y: 25)
        addChild(emoji)
        currentNodes.append(emoji)

        let btn = ButtonNode(text: "🧹 \(name) 정리", width: 240, height: 44, color: NSColor(white: 0.3, alpha: 1), fontSize: 16)
        btn.position = CGPoint(x: 0, y: -25)
        btn.action = { [weak self] in self?.onCleanup?(name) }
        addChild(btn)
        currentNodes.append(btn)
    }
    
    // MARK: - Emergency UI
    private func showEmergencyUI(_ part: RobotPart) {
        let alert = makeLabel("🚨 긴급 수리", size: 20, color: C.red, bold: true)
        alert.position = CGPoint(x: 0, y: 50)
        alert.run(.repeatForever(.sequence([.fadeAlpha(to: 0.5, duration: 0.4), .fadeAlpha(to: 1.0, duration: 0.4)])))
        addChild(alert)
        currentNodes.append(alert)
        
        let card = PartCardNode(part: part)
        card.position = CGPoint(x: 0, y: -15)
        card.bg.strokeColor = C.red
        card.onSelect = { [weak self] p in self?.onEmergencyFix?(p) }
        addChild(card)
        currentNodes.append(card)
        
        // Red pulse bg
        let pulse = SKShapeNode(rectOf: CGSize(width: 160, height: 170), cornerRadius: 14)
        pulse.fillColor = C.red.withAlphaComponent(0.05)
        pulse.strokeColor = .clear
        pulse.position = CGPoint(x: 0, y: -15)
        pulse.zPosition = -1
        pulse.run(.repeatForever(.sequence([
            .run { pulse.fillColor = C.red.withAlphaComponent(0.1) },
            .wait(forDuration: 0.4),
            .run { pulse.fillColor = C.red.withAlphaComponent(0.03) },
            .wait(forDuration: 0.4)
        ])))
        addChild(pulse)
        currentNodes.append(pulse)
    }
}
