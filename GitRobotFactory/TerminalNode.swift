import SpriteKit

class TerminalNode: SKNode {
    private var lines: [String] = []
    private let maxLines = 6
    private let lineHeight: CGFloat = 18
    private var lineNodes: [SKLabelNode] = []
    let termWidth: CGFloat
    
    init(width: CGFloat) {
        self.termWidth = width
        super.init()
        
        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 130), cornerRadius: 10)
        bg.fillColor = NSColor(red: 0.04, green: 0.05, blue: 0.06, alpha: 1)
        bg.strokeColor = C.border
        bg.lineWidth = 1
        bg.position = .zero
        addChild(bg)
        
        // Traffic lights
        let lights = SKNode()
        lights.position = CGPoint(x: -width/2 + 24, y: 50)
        for (i, color) in [C.red, C.yellow, C.green].enumerated() {
            let dot = SKShapeNode(circleOfRadius: 4)
            dot.fillColor = color
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat(i) * 14, y: 0)
            lights.addChild(dot)
        }
        addChild(lights)
        
        // Title
        let title = makeLabel("TERMINAL", size: 10, color: C.textDim, bold: true, mono: true)
        title.position = CGPoint(x: -width/2 + 80, y: 50)
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
        // Remove old lines
        for node in lineNodes { node.removeFromParent() }
        lineNodes = []
        
        let visible = Array(lines.suffix(maxLines))
        let startY: CGFloat = 30
        
        for (i, line) in visible.enumerated() {
            let y = startY - CGFloat(i) * lineHeight
            let node = SKLabelNode(text: line)
            node.fontName = "Menlo"
            node.fontSize = 11.5
            node.horizontalAlignmentMode = .left
            node.verticalAlignmentMode = .center
            node.position = CGPoint(x: -termWidth/2 + 16, y: y)
            
            if line.hasPrefix("#") {
                node.fontColor = NSColor(white: 0.35, alpha: 1)
            } else if line.hasPrefix("$") {
                node.fontColor = C.green
                // Highlight the command part
                let parts = line.dropFirst(2)
                node.text = "$ "
                
                let cmdLabel = SKLabelNode(text: String(parts))
                cmdLabel.fontName = "Menlo"
                cmdLabel.fontSize = 11.5
                cmdLabel.fontColor = NSColor(white: 0.9, alpha: 1)
                cmdLabel.horizontalAlignmentMode = .left
                cmdLabel.verticalAlignmentMode = .center
                cmdLabel.position = CGPoint(x: 16, y: 0)
                node.addChild(cmdLabel)
            }
            
            // Newest line is brighter
            let isNewest = i == visible.count - 1
            node.alpha = isNewest ? 1.0 : 0.6
            
            if isNewest {
                node.alpha = 0
                node.run(.fadeIn(withDuration: 0.2))
            }
            
            addChild(node)
            lineNodes.append(node)
        }
    }
}
