import SpriteKit

// MARK: - Colors
struct C {
    private static var isDark: Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    // MARK: Base
    static var bg: NSColor {
        isDark ? NSColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 1)
               : NSColor(red: 0.91, green: 0.92, blue: 0.95, alpha: 1)
    }
    static var panelBg: NSColor {
        isDark ? NSColor(red: 0.06, green: 0.07, blue: 0.09, alpha: 1)
               : NSColor(white: 1.0, alpha: 1)
    }
    static var border: NSColor {
        isDark ? NSColor(white: 0.12, alpha: 1) : NSColor(white: 0.65, alpha: 1)
    }
    static var text: NSColor {
        isDark ? NSColor(white: 0.9, alpha: 1) : NSColor(white: 0.08, alpha: 1)
    }
    static var textDim: NSColor {
        isDark ? NSColor(white: 0.5, alpha: 1) : NSColor(white: 0.30, alpha: 1)
    }
    static var textFaint: NSColor {
        isDark ? NSColor(white: 0.28, alpha: 1) : NSColor(white: 0.48, alpha: 1)
    }

    // MARK: Accents
    static var green: NSColor {
        isDark ? NSColor(red: 0.2, green: 0.65, blue: 0.3, alpha: 1)
               : NSColor(red: 0.1, green: 0.52, blue: 0.22, alpha: 1)
    }
    static var greenDk: NSColor {
        isDark ? NSColor(red: 0.15, green: 0.5, blue: 0.22, alpha: 1)
               : NSColor(red: 0.08, green: 0.42, blue: 0.16, alpha: 1)
    }
    static var blue: NSColor {
        isDark ? NSColor(red: 0.25, green: 0.55, blue: 0.95, alpha: 1)
               : NSColor(red: 0.15, green: 0.4, blue: 0.85, alpha: 1)
    }
    static var purple: NSColor {
        isDark ? NSColor(red: 0.6, green: 0.5, blue: 0.95, alpha: 1)
               : NSColor(red: 0.48, green: 0.32, blue: 0.88, alpha: 1)
    }
    static var yellow: NSColor {
        isDark ? NSColor(red: 0.9, green: 0.72, blue: 0.28, alpha: 1)
               : NSColor(red: 0.72, green: 0.52, blue: 0.08, alpha: 1)
    }
    static var red: NSColor {
        isDark ? NSColor(red: 0.95, green: 0.35, blue: 0.3, alpha: 1)
               : NSColor(red: 0.82, green: 0.18, blue: 0.12, alpha: 1)
    }
    static var orange: NSColor {
        isDark ? NSColor(red: 1.0, green: 0.58, blue: 0.22, alpha: 1)
               : NSColor(red: 0.85, green: 0.42, blue: 0.08, alpha: 1)
    }

    // MARK: Semantic
    static var topBarBg: NSColor {
        isDark ? NSColor(white: 0.05, alpha: 1) : NSColor(white: 0.84, alpha: 1)
    }
    static var cardBg: NSColor {
        isDark ? NSColor(white: 0.07, alpha: 1) : NSColor(white: 1.0, alpha: 1)
    }
    static var cardBgAlt: NSColor {
        isDark ? NSColor(white: 0.05, alpha: 1) : NSColor(white: 0.96, alpha: 1)
    }
    static var buttonSecondary: NSColor {
        isDark ? NSColor(white: 0.12, alpha: 1) : NSColor(white: 0.78, alpha: 1)
    }
    static var buttonCancel: NSColor {
        isDark ? NSColor(white: 0.3, alpha: 1) : NSColor(white: 0.60, alpha: 1)
    }
    static var buttonClear: NSColor {
        isDark ? NSColor(white: 0.25, alpha: 1) : NSColor(white: 0.65, alpha: 1)
    }
    static var starDim: NSColor {
        isDark ? NSColor(white: 0.18, alpha: 1) : NSColor(white: 0.70, alpha: 1)
    }
    static var successBg: NSColor {
        isDark ? NSColor(red: 0.04, green: 0.12, blue: 0.06, alpha: 1)
               : NSColor(red: 0.85, green: 0.96, blue: 0.87, alpha: 1)
    }
    static var gridLine: NSColor {
        isDark ? NSColor(white: 1, alpha: 0.02) : NSColor(white: 0, alpha: 0.06)
    }
    static var progressBg: NSColor {
        isDark ? NSColor(white: 0.1, alpha: 1) : NSColor(white: 0.75, alpha: 1)
    }
    static var panelOverlay: NSColor {
        isDark ? NSColor(white: 0.03, alpha: 0.6) : NSColor(white: 1.0, alpha: 0.85)
    }
    static var dialogBg: NSColor {
        isDark ? NSColor(red: 0.08, green: 0.1, blue: 0.14, alpha: 1)
               : NSColor(white: 0.99, alpha: 1)
    }
    static var notificationBg: NSColor {
        isDark ? NSColor(red: 0.1, green: 0.15, blue: 0.2, alpha: 0.95)
               : NSColor(red: 0.88, green: 0.93, blue: 0.99, alpha: 0.98)
    }
    static var branchDialogBg: NSColor {
        isDark ? NSColor(red: 0.15, green: 0.2, blue: 0.3, alpha: 0.95)
               : NSColor(red: 0.88, green: 0.91, blue: 0.98, alpha: 0.98)
    }
    static var explanationBg: NSColor {
        isDark ? NSColor(red: 0.1, green: 0.1, blue: 0.05, alpha: 0.98)
               : NSColor(red: 0.98, green: 0.97, blue: 0.93, alpha: 0.98)
    }
    static var completionBg: NSColor {
        isDark ? NSColor(red: 0.05, green: 0.08, blue: 0.05, alpha: 0.98)
               : NSColor(red: 0.93, green: 0.97, blue: 0.93, alpha: 0.98)
    }
    static var commitInputBg: NSColor {
        isDark ? NSColor(white: 0.05, alpha: 1) : NSColor(white: 0.93, alpha: 1)
    }
    static var terminalBg: NSColor { NSColor(red: 0.03, green: 0.04, blue: 0.05, alpha: 1) }
    static var terminalComment: NSColor { NSColor(white: 0.3, alpha: 1) }
    static var terminalCmdText: NSColor { NSColor(white: 0.85, alpha: 1) }
    static var gitGraphMeta: NSColor {
        isDark ? NSColor(white: 0.4, alpha: 1) : NSColor(white: 0.32, alpha: 1)
    }
    static var gitGraphMsg: NSColor {
        isDark ? NSColor(white: 0.55, alpha: 1) : NSColor(white: 0.28, alpha: 1)
    }
    static var robotSlotBg: NSColor {
        isDark ? NSColor(white: 0.05, alpha: 1) : NSColor(white: 0.96, alpha: 1)
    }
    static var robotSlotDash: NSColor {
        isDark ? NSColor(white: 0.18, alpha: 1) : NSColor(white: 0.58, alpha: 1)
    }
    static var robotSlotLabel: NSColor {
        isDark ? NSColor(white: 0.22, alpha: 1) : NSColor(white: 0.40, alpha: 1)
    }

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
        // Use dark text on light backgrounds, white on dark/colorful backgrounds
        let isDarkColor = color.brightnessComponent < 0.6
        label.fontColor = isDarkColor ? .white : NSColor(white: 0.15, alpha: 1)
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
        lineWidth = 1.5
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
        bg.fillColor = C.cardBg
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
        bg.fillColor = C.cardBgAlt
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
