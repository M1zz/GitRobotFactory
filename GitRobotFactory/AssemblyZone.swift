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
            node.run(.sequence([.fadeOut(withDuration: 0.1), .removeFromParent()]))
        }
        currentNodes = []
    }
    
    // MARK: - Part Picker (Compact)
    private func showPartPicker(_ parts: [RobotPart]) {
        // Title + Hint in one line
        let title = makeLabel("부품 선택  💡 드래그 → 슬롯", size: 11, color: C.textDim, bold: true)
        title.position = CGPoint(x: 0, y: 58)
        addChild(title)
        currentNodes.append(title)

        // Tight card spacing
        let spacing: CGFloat = 102  // Just enough for card width (95) + 7px gap
        let startX = -CGFloat(parts.count - 1) * spacing / 2

        for (i, part) in parts.enumerated() {
            let card = PartCardNode(part: part)
            card.position = CGPoint(x: startX + CGFloat(i) * spacing, y: -5)
            card.onSelect = { [weak self] p in
                self?.onPartSelected?(p)
            }

            // Animate in
            card.alpha = 0
            card.setScale(0.9)
            card.run(.group([
                .fadeIn(withDuration: 0.12),
                .scale(to: 1.0, duration: 0.12)
            ]))

            addChild(card)
            currentNodes.append(card)
        }
    }
    
    // MARK: - Workstation Opener (Compact)
    private func showWorkstationOpener(_ name: String) {
        let title = makeLabel("새 워크스테이션", size: 13, color: C.textDim, bold: true)
        title.position = CGPoint(x: 0, y: 40)
        addChild(title)
        currentNodes.append(title)

        let btn = ButtonNode(text: "🔀 \(name)", width: 200, height: 40, color: C.branchColor(name), fontSize: 13)
        btn.position = CGPoint(x: 0, y: -5)
        btn.action = { [weak self] in self?.onWorkstationOpened?(name) }
        
        btn.alpha = 0; btn.setScale(0.85)
        btn.run(.group([.fadeIn(withDuration: 0.15), .scale(to: 1.0, duration: 0.15)]))
        
        addChild(btn)
        currentNodes.append(btn)
        
        let hint = makeLabel("클릭하여 개설", size: 10, color: C.textFaint)
        hint.position = CGPoint(x: 0, y: -35)
        addChild(hint)
        currentNodes.append(hint)
    }
    
    // MARK: - Part Installer (Compact)
    private func showPartInstaller(_ part: RobotPart) {
        let card = PartCardNode(part: part, cardSize: CGSize(width: 110, height: 120))
        card.position = CGPoint(x: 0, y: 0)
        card.onSelect = { [weak self] p in self?.onPartSelected?(p) }
        
        card.alpha = 0; card.setScale(0.85)
        card.run(.group([.fadeIn(withDuration: 0.15), .scale(to: 1.0, duration: 0.15)]))
        
        addChild(card)
        currentNodes.append(card)
    }
    
    // MARK: - Merge UI (Compact)
    private func showMergeUI(from: String, to: String) {
        let mergeCard = MergeCardNode(from: from, to: to)
        mergeCard.position = CGPoint(x: 0, y: 0)
        mergeCard.onMerge = { [weak self] in self?.onMerge?(from, to) }
        
        mergeCard.alpha = 0; mergeCard.setScale(0.85)
        mergeCard.run(.group([.fadeIn(withDuration: 0.15), .scale(to: 1.0, duration: 0.15)]))
        
        addChild(mergeCard)
        currentNodes.append(mergeCard)
    }
    
    // MARK: - Conflict UI (Compact)
    private func showConflictUI(_ partA: RobotPart, _ partB: RobotPart) {
        let alert = makeLabel("⚡ CONFLICT!", size: 16, color: C.red, bold: true)
        alert.position = CGPoint(x: 0, y: 45)
        alert.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.5, duration: 0.4),
            .fadeAlpha(to: 1.0, duration: 0.4)
        ])))
        addChild(alert)
        currentNodes.append(alert)

        let desc = makeLabel("포트A 충돌!", size: 12, color: C.orange)
        desc.position = CGPoint(x: 0, y: 25)
        addChild(desc)
        currentNodes.append(desc)

        let aLabel = makeLabel("\(partA.emoji) \(partA.name) → A", size: 11, color: C.green, bold: true)
        aLabel.position = CGPoint(x: 0, y: 5)
        addChild(aLabel)
        currentNodes.append(aLabel)

        let bLabel = makeLabel("\(partB.emoji) \(partB.name) → B", size: 11, color: C.orange, bold: true)
        bLabel.position = CGPoint(x: 0, y: -12)
        addChild(bLabel)
        currentNodes.append(bLabel)

        let btn = ButtonNode(text: "✅ 해결", width: 140, height: 34, color: C.green, fontSize: 12)
        btn.position = CGPoint(x: 0, y: -45)
        btn.action = { [weak self] in self?.onConflictResolved?() }
        addChild(btn)
        currentNodes.append(btn)
    }
    
    // MARK: - Tag UI (Compact)
    private func showTagUI(_ version: String) {
        let emoji = makeEmoji("🏷️", size: 36)
        emoji.position = CGPoint(x: 0, y: 20)
        addChild(emoji)
        currentNodes.append(emoji)

        let btn = ButtonNode(text: version, width: 120, height: 36, color: C.yellow, fontSize: 14)
        btn.position = CGPoint(x: 0, y: -25)
        btn.action = { [weak self] in self?.onTagged?(version) }
        
        btn.alpha = 0; btn.setScale(0.85)
        btn.run(.group([.fadeIn(withDuration: 0.15), .scale(to: 1.0, duration: 0.15)]))
        addChild(btn)
        currentNodes.append(btn)
    }
    
    // MARK: - Ship UI (Compact)
    private func showShipUI() {
        let emoji = makeEmoji("📦", size: 36)
        emoji.position = CGPoint(x: 0, y: 20)
        addChild(emoji)
        currentNodes.append(emoji)

        let btn = ButtonNode(text: "📦 출하!", width: 160, height: 40, color: C.green, fontSize: 13)
        btn.position = CGPoint(x: 0, y: -25)
        btn.action = { [weak self] in self?.onShipped?() }
        
        btn.alpha = 0; btn.setScale(0.85)
        btn.run(.group([.fadeIn(withDuration: 0.15), .scale(to: 1.0, duration: 0.15)]))
        addChild(btn)
        currentNodes.append(btn)
    }
    
    // MARK: - Cleanup UI (Compact)
    private func showCleanupUI(_ name: String) {
        let emoji = makeEmoji("🧹", size: 32)
        emoji.position = CGPoint(x: 0, y: 20)
        addChild(emoji)
        currentNodes.append(emoji)

        let btn = ButtonNode(text: "🧹 \(name) 정리", width: 180, height: 36, color: NSColor(white: 0.25, alpha: 1), fontSize: 12)
        btn.position = CGPoint(x: 0, y: -20)
        btn.action = { [weak self] in self?.onCleanup?(name) }
        addChild(btn)
        currentNodes.append(btn)
    }
    
    // MARK: - Emergency UI (Compact)
    private func showEmergencyUI(_ part: RobotPart) {
        let alert = makeLabel("🚨 긴급 수리", size: 15, color: C.red, bold: true)
        alert.position = CGPoint(x: 0, y: 50)
        alert.run(.repeatForever(.sequence([.fadeAlpha(to: 0.5, duration: 0.35), .fadeAlpha(to: 1.0, duration: 0.35)])))
        addChild(alert)
        currentNodes.append(alert)
        
        let card = PartCardNode(part: part)
        card.position = CGPoint(x: 0, y: -10)
        card.bg.strokeColor = C.red
        card.onSelect = { [weak self] p in self?.onEmergencyFix?(p) }
        addChild(card)
        currentNodes.append(card)
        
        // Red pulse bg
        let pulse = SKShapeNode(rectOf: CGSize(width: 110, height: 120), cornerRadius: 10)
        pulse.fillColor = C.red.withAlphaComponent(0.03)
        pulse.strokeColor = .clear
        pulse.position = CGPoint(x: 0, y: -10)
        pulse.zPosition = -1
        pulse.run(.repeatForever(.sequence([
            .run { pulse.fillColor = C.red.withAlphaComponent(0.08) },
            .wait(forDuration: 0.35),
            .run { pulse.fillColor = C.red.withAlphaComponent(0.02) },
            .wait(forDuration: 0.35)
        ])))
        addChild(pulse)
        currentNodes.append(pulse)
    }
}
