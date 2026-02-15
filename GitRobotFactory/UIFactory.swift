import SpriteKit

// MARK: - Colors
struct C {
    static let bg        = NSColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 1)
    static let panelBg   = NSColor(red: 0.06, green: 0.07, blue: 0.09, alpha: 1)
    static let border    = NSColor(white: 0.12, alpha: 1)
    static let text      = NSColor(white: 0.9, alpha: 1)
    static let textDim   = NSColor(white: 0.5, alpha: 1)
    static let textFaint = NSColor(white: 0.28, alpha: 1)
    static let green     = NSColor(red: 0.2, green: 0.65, blue: 0.3, alpha: 1)
    static let greenDk   = NSColor(red: 0.15, green: 0.5, blue: 0.22, alpha: 1)
    static let blue      = NSColor(red: 0.25, green: 0.55, blue: 0.95, alpha: 1)
    static let purple    = NSColor(red: 0.6, green: 0.5, blue: 0.95, alpha: 1)
    static let yellow    = NSColor(red: 0.9, green: 0.72, blue: 0.28, alpha: 1)
    static let red       = NSColor(red: 0.95, green: 0.35, blue: 0.3, alpha: 1)
    static let orange    = NSColor(red: 1.0, green: 0.58, blue: 0.22, alpha: 1)
    
    static func branchColor(_ name: String) -> NSColor {
        if name == "main" { return green }
        if name == "develop" { return blue }
        if name.hasPrefix("feature/") { return purple }
        if name.hasPrefix("release/") { return yellow }
        if name.hasPrefix("hotfix/") { return red }
        return textDim
    }
}

// MARK: - Button Node (Compact)
class ButtonNode: SKNode {
    let bg: SKShapeNode
    let label: SKLabelNode
    var action: (() -> Void)?
    private var isHovered = false
    private let baseColor: NSColor
    
    init(text: String, width: CGFloat = 140, height: CGFloat = 36, color: NSColor = C.green, fontSize: CGFloat = 13) {
        self.baseColor = color
        bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 7)
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
        run(.scale(to: 1.03, duration: 0.08))
        bg.fillColor = baseColor.blended(withFraction: 0.15, of: .white) ?? baseColor
    }
    
    override func mouseExited(with event: NSEvent) {
        isHovered = false
        run(.scale(to: 1.0, duration: 0.08))
        bg.fillColor = baseColor
    }
    
    override func mouseUp(with event: NSEvent) {
        action?()
    }
}

// MARK: - Panel Node
class PanelNode: SKShapeNode {
    init(size: CGSize, corner: CGFloat = 10) {
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
func makeLabel(_ text: String, size: CGFloat = 12, color: NSColor = C.text, bold: Bool = false, mono: Bool = false) -> SKLabelNode {
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

func makeLeftLabel(_ text: String, size: CGFloat = 12, color: NSColor = C.text, bold: Bool = false, mono: Bool = false) -> SKLabelNode {
    let n = makeLabel(text, size: size, color: color, bold: bold, mono: mono)
    n.horizontalAlignmentMode = .left
    return n
}

// MARK: - Badge Node (Compact)
func makeBadge(_ text: String, color: NSColor, fontSize: CGFloat = 10) -> SKNode {
    let container = SKNode()
    let label = makeLabel(text, size: fontSize, color: .white, bold: true, mono: true)

    let w = CGFloat(text.count) * fontSize * 0.65 + 12
    let bg = SKShapeNode(rectOf: CGSize(width: w, height: 20), cornerRadius: 8)
    bg.fillColor = color
    bg.strokeColor = .clear
    
    container.addChild(bg)
    container.addChild(label)
    return container
}

// MARK: - Emoji Node
func makeEmoji(_ emoji: String, size: CGFloat = 40) -> SKLabelNode {
    let n = SKLabelNode(text: emoji)
    n.fontSize = size
    n.verticalAlignmentMode = .center
    return n
}

// MARK: - Part Card Node (Compact)
class PartCardNode: SKNode {
    let part: RobotPart
    let bg: SKShapeNode
    var onSelect: ((RobotPart) -> Void)?

    init(part: RobotPart, cardSize: CGSize = CGSize(width: 95, height: 105)) {
        self.part = part
        bg = SKShapeNode(rectOf: cardSize, cornerRadius: 8)
        bg.fillColor = NSColor(white: 0.07, alpha: 1)
        bg.strokeColor = C.border
        bg.lineWidth = 1

        super.init()
        isUserInteractionEnabled = false

        addChild(bg)

        let emoji = makeEmoji(part.emoji, size: 32)
        emoji.position = CGPoint(x: 0, y: 16)
        addChild(emoji)

        let nameLabel = makeLabel(part.name, size: 11, color: C.text, bold: true)
        nameLabel.position = CGPoint(x: 0, y: -12)
        addChild(nameLabel)

        let slotLabel = makeLabel(part.slot.label, size: 9, color: C.textDim)
        slotLabel.position = CGPoint(x: 0, y: -26)
        addChild(slotLabel)

        if let port = part.portId {
            let portLabel = makeLabel("P:\(port)", size: 8, color: C.orange, bold: true, mono: true)
            portLabel.position = CGPoint(x: 0, y: -40)
            addChild(portLabel)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Merge Card Node (Compact)
class MergeCardNode: SKNode {
    let fromBranch: String
    let toBranch: String
    var onMerge: (() -> Void)?
    let bg: SKShapeNode
    
    init(from: String, to: String) {
        self.fromBranch = from
        self.toBranch = to
        bg = SKShapeNode(rectOf: CGSize(width: 240, height: 60), cornerRadius: 10)
        bg.fillColor = NSColor(white: 0.05, alpha: 1)
        bg.strokeColor = C.green.withAlphaComponent(0.25)
        bg.lineWidth = 1
        
        super.init()
        isUserInteractionEnabled = true
        addChild(bg)
        
        let fromBadge = makeBadge(from, color: C.branchColor(from), fontSize: 9)
        fromBadge.position = CGPoint(x: -65, y: 0)
        addChild(fromBadge)
        
        let arrow = makeLabel("→", size: 18, color: C.green, bold: true)
        arrow.position = CGPoint(x: 0, y: 0)
        addChild(arrow)
        
        let toBadge = makeBadge(to, color: C.branchColor(to), fontSize: 9)
        toBadge.position = CGPoint(x: 65, y: 0)
        addChild(toBadge)
        
        let hint = makeLabel("클릭하여 머지", size: 10, color: C.textFaint)
        hint.position = CGPoint(x: 0, y: -22)
        addChild(hint)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func mouseEntered(with event: NSEvent) {
        run(.scale(to: 1.03, duration: 0.08))
        bg.strokeColor = C.green
    }
    override func mouseExited(with event: NSEvent) {
        run(.scale(to: 1.0, duration: 0.08))
        bg.strokeColor = C.green.withAlphaComponent(0.25)
    }
    override func mouseUp(with event: NSEvent) { onMerge?() }
}
