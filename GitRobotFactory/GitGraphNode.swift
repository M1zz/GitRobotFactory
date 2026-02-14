import SpriteKit

class GitGraphNode: SKNode {
    private var entries: [(branch: String, label: String, type: String)] = []
    private let maxVisible = 12
    private let entryHeight: CGFloat = 28
    
    override init() {
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    func addEntry(branch: String, label: String, type: String = "commit") {
        entries.append((branch, label, type))
        rebuild()
    }
    
    func reset() {
        entries = []
        rebuild()
    }
    
    private func rebuild() {
        removeAllChildren()
        
        let visible = entries.suffix(maxVisible)
        
        for (i, entry) in visible.enumerated() {
            let y = CGFloat(visible.count - 1 - i) * entryHeight
            let row = SKNode()
            row.position = CGPoint(x: 0, y: y)
            
            // Dot
            let dotSize: CGFloat = 8
            let dot = SKShapeNode(circleOfRadius: dotSize / 2)
            dot.fillColor = nodeColor(entry.type, branch: entry.branch)
            dot.strokeColor = nodeColor(entry.type, branch: entry.branch).blended(withFraction: 0.3, of: .white) ?? .white
            dot.lineWidth = 1
            dot.position = CGPoint(x: 0, y: 0)
            row.addChild(dot)
            
            // Line to next
            if i < visible.count - 1 {
                let line = SKShapeNode(rectOf: CGSize(width: 1.5, height: entryHeight - dotSize))
                line.fillColor = C.branchColor(entry.branch).withAlphaComponent(0.3)
                line.strokeColor = .clear
                line.position = CGPoint(x: 0, y: -entryHeight / 2)
                row.addChild(line)
            }
            
            // Branch badge
            let badgeLabel = SKLabelNode(text: entry.branch)
            badgeLabel.fontName = "Menlo"
            badgeLabel.fontSize = 8
            badgeLabel.fontColor = .white
            badgeLabel.horizontalAlignmentMode = .left
            badgeLabel.verticalAlignmentMode = .center
            badgeLabel.position = CGPoint(x: 12, y: 0)
            row.addChild(badgeLabel)
            
            // Type indicator
            if entry.type == "merge" {
                let tag = SKLabelNode(text: "M")
                tag.fontName = "Menlo-Bold"
                tag.fontSize = 7
                tag.fontColor = C.green
                tag.verticalAlignmentMode = .center
                tag.position = CGPoint(x: -12, y: 0)
                row.addChild(tag)
            } else if entry.type == "tag" {
                let tag = SKLabelNode(text: "🏷️")
                tag.fontSize = 10
                tag.verticalAlignmentMode = .center
                tag.position = CGPoint(x: -14, y: 0)
                row.addChild(tag)
            } else if entry.type == "conflict" {
                let tag = SKLabelNode(text: "⚡")
                tag.fontSize = 10
                tag.verticalAlignmentMode = .center
                tag.position = CGPoint(x: -14, y: 0)
                row.addChild(tag)
            }
            
            // Fade in newest
            if i == visible.count - 1 && entries.count > 0 {
                row.alpha = 0
                row.run(.fadeIn(withDuration: 0.3))
            }
            
            addChild(row)
        }
    }
    
    private func nodeColor(_ type: String, branch: String) -> NSColor {
        switch type {
        case "merge": return C.green
        case "tag": return C.yellow
        case "conflict": return C.orange
        case "branch": return C.branchColor(branch)
        default: return C.branchColor(branch)
        }
    }
}
