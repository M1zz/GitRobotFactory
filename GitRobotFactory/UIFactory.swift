import SpriteKit

// MARK: - Colors
struct C {
    static let bg        = NSColor(red: 0.05, green: 0.066, blue: 0.09, alpha: 1)
    static let panelBg   = NSColor(red: 0.07, green: 0.085, blue: 0.11, alpha: 1)
    static let border    = NSColor(white: 0.15, alpha: 1)
    static let text      = NSColor(white: 0.9, alpha: 1)
    static let textDim   = NSColor(white: 0.55, alpha: 1)
    static let textFaint = NSColor(white: 0.3, alpha: 1)
    static let green     = NSColor(red: 0.18, green: 0.63, blue: 0.26, alpha: 1)
    static let greenDk   = NSColor(red: 0.14, green: 0.53, blue: 0.21, alpha: 1)
    static let blue      = NSColor(red: 0.22, green: 0.55, blue: 0.99, alpha: 1)
    static let purple    = NSColor(red: 0.65, green: 0.55, blue: 0.98, alpha: 1)
    static let yellow    = NSColor(red: 0.89, green: 0.7, blue: 0.25, alpha: 1)
    static let red       = NSColor(red: 0.97, green: 0.32, blue: 0.29, alpha: 1)
    static let orange    = NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1)
    
    static func branchColor(_ name: String) -> NSColor {
        if name == "main" { return green }
        if name == "develop" { return blue }
        if name.hasPrefix("feature/") { return purple }
        if name.hasPrefix("release/") { return yellow }
        if name.hasPrefix("hotfix/") { return red }
        return textDim
    }
}

// MARK: - Button Node
class ButtonNode: SKNode {
    let bg: SKShapeNode
    let label: SKLabelNode
    var action: (() -> Void)?
    private var isHovered = false
    private let baseColor: NSColor
    
    init(text: String, width: CGFloat = 200, height: CGFloat = 44, color: NSColor = C.green, fontSize: CGFloat = 17) {  // Default increased
        self.baseColor = color
        bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        bg.fillColor = color
        bg.strokeColor = .clear

        label = SKLabelNode(text: text)
        label.fontName = "Menlo-Bold"
        label.fontSize = fontSize
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        
        super.init()
        isUserInteractionEnabled = true
        addChild(bg)
        addChild(label)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        run(.scale(to: 1.05, duration: 0.1))
        bg.fillColor = baseColor.blended(withFraction: 0.2, of: .white) ?? baseColor
    }
    
    override func mouseExited(with event: NSEvent) {
        isHovered = false
        run(.scale(to: 1.0, duration: 0.1))
        bg.fillColor = baseColor
    }
    
    override func mouseUp(with event: NSEvent) {
        action?()
    }
}

// MARK: - Panel Node
class PanelNode: SKShapeNode {
    init(size: CGSize, corner: CGFloat = 12) {
        super.init()
        self.path = CGPath(roundedRect: CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2),
                                                size: size),
                           cornerWidth: corner, cornerHeight: corner, transform: nil)
        fillColor = C.panelBg
        strokeColor = C.border
        lineWidth = 1
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Label Helpers
func makeLabel(_ text: String, size: CGFloat = 14, color: NSColor = C.text, bold: Bool = false, mono: Bool = false) -> SKLabelNode {
    let n = SKLabelNode(text: text)
    if mono {
        n.fontName = bold ? "Menlo-Bold" : "Menlo"
    } else {
        n.fontName = bold ? "Helvetica-Bold" : "Helvetica"
    }
    n.fontSize = size
    n.fontColor = color
    n.verticalAlignmentMode = .center
    n.horizontalAlignmentMode = .center
    return n
}

func makeLeftLabel(_ text: String, size: CGFloat = 14, color: NSColor = C.text, bold: Bool = false, mono: Bool = false) -> SKLabelNode {
    let n = makeLabel(text, size: size, color: color, bold: bold, mono: mono)
    n.horizontalAlignmentMode = .left
    return n
}

// MARK: - Badge Node
func makeBadge(_ text: String, color: NSColor, fontSize: CGFloat = 12) -> SKNode {  // Default increased
    let container = SKNode()
    let label = makeLabel(text, size: fontSize, color: .white, bold: true, mono: true)

    let w = CGFloat(text.count) * fontSize * 0.7 + 16
    let bg = SKShapeNode(rectOf: CGSize(width: w, height: 24), cornerRadius: 10)  // Increased height
    bg.fillColor = color
    bg.strokeColor = .clear
    
    container.addChild(bg)
    container.addChild(label)
    return container
}

// MARK: - Emoji Node (large)
func makeEmoji(_ emoji: String, size: CGFloat = 48) -> SKLabelNode {
    let n = SKLabelNode(text: emoji)
    n.fontSize = size
    n.verticalAlignmentMode = .center
    return n
}

// MARK: - Part Card Node (clickable)
class PartCardNode: SKNode {
    let part: RobotPart
    let bg: SKShapeNode
    var onSelect: ((RobotPart) -> Void)?

    init(part: RobotPart, cardSize: CGSize = CGSize(width: 140, height: 155)) {  // Reduced slightly to fit in center panel
        self.part = part
        bg = SKShapeNode(rectOf: cardSize, cornerRadius: 12)
        bg.fillColor = NSColor(white: 0.08, alpha: 1)
        bg.strokeColor = C.border
        bg.lineWidth = 1.5

        super.init()
        // Don't enable user interaction - let GameScene handle drag & drop
        isUserInteractionEnabled = false

        addChild(bg)

        let emoji = makeEmoji(part.emoji, size: 50)  // Increased
        emoji.position = CGPoint(x: 0, y: 22)
        addChild(emoji)

        let nameLabel = makeLabel(part.name, size: 16, color: C.text, bold: true)  // Increased
        nameLabel.position = CGPoint(x: 0, y: -15)
        addChild(nameLabel)

        let slotLabel = makeLabel(part.slot.label, size: 13, color: C.textDim)  // Increased
        slotLabel.position = CGPoint(x: 0, y: -35)
        addChild(slotLabel)

        if let port = part.portId {
            let portLabel = makeLabel("포트: \(port)", size: 11, color: C.orange, bold: true, mono: true)
            portLabel.position = CGPoint(x: 0, y: -50)
            addChild(portLabel)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // Mouse events are now handled by GameScene for drag & drop
    // Visual feedback will be provided through GameScene's drag logic
}

// MARK: - Conveyor Merge Node (clickable)
class MergeCardNode: SKNode {
    let fromBranch: String
    let toBranch: String
    var onMerge: (() -> Void)?
    let bg: SKShapeNode
    
    init(from: String, to: String) {
        self.fromBranch = from
        self.toBranch = to
        bg = SKShapeNode(rectOf: CGSize(width: 300, height: 80), cornerRadius: 14)
        bg.fillColor = NSColor(white: 0.06, alpha: 1)
        bg.strokeColor = C.green.withAlphaComponent(0.3)
        bg.lineWidth = 1.5
        
        super.init()
        isUserInteractionEnabled = true
        addChild(bg)
        
        let fromBadge = makeBadge(from, color: C.branchColor(from))
        fromBadge.position = CGPoint(x: -80, y: 0)
        addChild(fromBadge)
        
        let arrow = makeLabel("→", size: 24, color: C.green, bold: true)
        arrow.position = CGPoint(x: 0, y: 0)
        addChild(arrow)
        
        let mergeEmoji = makeEmoji("🔗", size: 20)
        mergeEmoji.position = CGPoint(x: 20, y: 0)
        addChild(mergeEmoji)
        
        let toBadge = makeBadge(to, color: C.branchColor(to))
        toBadge.position = CGPoint(x: 80, y: 0)
        addChild(toBadge)
        
        let hint = makeLabel("클릭하여 머지", size: 13, color: C.textFaint)
        hint.position = CGPoint(x: 0, y: -30)
        addChild(hint)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func mouseEntered(with event: NSEvent) {
        run(.scale(to: 1.04, duration: 0.1))
        bg.strokeColor = C.green
    }
    override func mouseExited(with event: NSEvent) {
        run(.scale(to: 1.0, duration: 0.1))
        bg.strokeColor = C.green.withAlphaComponent(0.3)
    }
    override func mouseUp(with event: NSEvent) { onMerge?() }
}
