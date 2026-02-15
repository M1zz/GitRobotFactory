import SpriteKit

class TerminalNode: SKNode {
    private var lines: [String] = []
    private let maxLines = 4  // Reduced for compact layout
    private let lineHeight: CGFloat = 15
    private var lineNodes: [SKLabelNode] = []
    let termWidth: CGFloat
    
    init(width: CGFloat) {
        self.termWidth = width
        super.init()

        // Background - compact height
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 75), cornerRadius: 8)
        bg.fillColor = NSColor(red: 0.03, green: 0.04, blue: 0.05, alpha: 1)
        bg.strokeColor = C.border
        bg.lineWidth = 1
        bg.position = .zero
        addChild(bg)

        // Traffic lights (smaller)
        let lights = SKNode()
        lights.position = CGPoint(x: -width/2 + 18, y: 25)
        for (i, color) in [C.red, C.yellow, C.green].enumerated() {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor = color
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat(i) * 10, y: 0)
            lights.addChild(dot)
        }
        addChild(lights)

        // Title
        let title = makeLabel("TERMINAL", size: 9, color: C.textDim, bold: true, mono: true)
        title.position = CGPoint(x: -width/2 + 58, y: 25)
        title.horizontalAlignmentMode = .left
        addChild(title)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    func addCommand(_ cmd: String) {
        let cmdLines = cmd.components(separatedBy: "\n")
        for line in cmdLines {
            if line.hasPrefix("#") {
                lines.append(line)
            } else {
                lines.append("$ \(line)")
            }
        }
        rebuild()
    }
    
    func reset() {
        lines = []
        rebuild()
    }
    
    private func rebuild() {
        for node in lineNodes { node.removeFromParent() }
        lineNodes = []

        let visible = Array(lines.suffix(maxLines))
        let startY: CGFloat = 12
        
        for (i, line) in visible.enumerated() {
            let y = startY - CGFloat(i) * lineHeight
            let node = SKLabelNode(text: line)
            node.fontName = "Menlo"
            node.fontSize = 10
            node.horizontalAlignmentMode = .left
            node.verticalAlignmentMode = .center
            node.position = CGPoint(x: -termWidth/2 + 12, y: y)
            
            if line.hasPrefix("#") {
                node.fontColor = NSColor(white: 0.3, alpha: 1)
            } else if line.hasPrefix("$") {
                node.fontColor = C.green
                let parts = line.dropFirst(2)
                node.text = "$ "
                
                let cmdLabel = SKLabelNode(text: String(parts))
                cmdLabel.fontName = "Menlo"
                cmdLabel.fontSize = 10
                cmdLabel.fontColor = NSColor(white: 0.85, alpha: 1)
                cmdLabel.horizontalAlignmentMode = .left
                cmdLabel.verticalAlignmentMode = .center
                cmdLabel.position = CGPoint(x: 14, y: 0)
                node.addChild(cmdLabel)
            }
            
            let isNewest = i == visible.count - 1
            node.alpha = isNewest ? 1.0 : 0.55
            
            if isNewest {
                node.alpha = 0
                node.run(.fadeIn(withDuration: 0.15))
            }
            
            addChild(node)
            lineNodes.append(node)
        }
    }
}
