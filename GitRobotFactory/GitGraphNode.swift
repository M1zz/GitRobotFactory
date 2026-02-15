import SpriteKit

class GitGraphNode: SKNode {
    private struct CommitEntry {
        let branch: String
        let label: String
        let type: String
        let commitId: String
        let timestamp: Date
    }

    private var entries: [CommitEntry] = []
    private let maxVisible = 8  // Reduced for compact layout
    private let entryHeight: CGFloat = 38  // Compact height
    private let laneWidth: CGFloat = 18
    private var commitCounter = 0

    private var branchLanes: [String: Int] = ["main": 0]
    private var nextLane = 1

    override init() {
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }

    func addEntry(branch: String, label: String, type: String = "commit") {
        let commitId = generateCommitId()
        let entry = CommitEntry(
            branch: branch,
            label: label,
            type: type,
            commitId: commitId,
            timestamp: Date()
        )
        entries.append(entry)

        if branchLanes[branch] == nil {
            branchLanes[branch] = nextLane
            nextLane += 1
        }

        rebuild()
    }

    private func generateCommitId() -> String {
        commitCounter += 1
        let chars = "0123456789abcdef"
        var id = ""
        var seed = commitCounter * 12345
        for _ in 0..<7 {
            seed = (seed * 1103515245 + 12345) & 0x7fffffff
            let index = chars.index(chars.startIndex, offsetBy: seed % 16)
            id.append(chars[index])
        }
        return id
    }

    private func relativeTime(from date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "\(seconds)s" }
        else if seconds < 3600 { return "\(seconds / 60)m" }
        else if seconds < 86400 { return "\(seconds / 3600)h" }
        else { return "\(seconds / 86400)d" }
    }

    func reset() {
        entries = []
        branchLanes = ["main": 0]
        nextLane = 1
        commitCounter = 0
        rebuild()
    }
    
    private func rebuild() {
        removeAllChildren()

        let visible = Array(entries.suffix(maxVisible))

        for (i, entry) in visible.enumerated() {
            let y = -CGFloat(i) * entryHeight
            let lane = branchLanes[entry.branch] ?? 0
            let x = CGFloat(lane) * laneWidth

            let row = SKNode()
            row.position = CGPoint(x: x, y: y)

            // Dot (smaller)
            let dotSize: CGFloat = 6
            let dot = SKShapeNode(circleOfRadius: dotSize / 2)
            dot.fillColor = nodeColor(entry.type, branch: entry.branch)
            dot.strokeColor = nodeColor(entry.type, branch: entry.branch).blended(withFraction: 0.25, of: .white) ?? .white
            dot.lineWidth = 1
            dot.position = CGPoint(x: 0, y: 0)
            row.addChild(dot)

            // Connect to next entry
            if i < visible.count - 1 {
                let nextEntry = visible[i + 1]
                let nextLane = branchLanes[nextEntry.branch] ?? 0
                let nextX = CGFloat(nextLane) * laneWidth
                let nextY = y - entryHeight

                if lane == nextLane {
                    // Same branch: straight line
                    let line = SKShapeNode(rectOf: CGSize(width: 1.5, height: entryHeight - dotSize))
                    line.fillColor = C.branchColor(entry.branch).withAlphaComponent(0.35)
                    line.strokeColor = .clear
                    line.position = CGPoint(x: 0, y: -entryHeight / 2)
                    row.addChild(line)
                } else {
                    // Different branch: curved
                    drawCurvedLine(from: CGPoint(x: x, y: y - dotSize/2),
                                   to: CGPoint(x: nextX, y: nextY + dotSize/2),
                                   color: C.branchColor(entry.branch))
                }
            }

            // Branch name (compact)
            let branchLabel = SKLabelNode(text: entry.branch)
            branchLabel.fontName = "Menlo"
            branchLabel.fontSize = 8
            branchLabel.fontColor = C.branchColor(entry.branch)
            branchLabel.horizontalAlignmentMode = .left
            branchLabel.verticalAlignmentMode = .center
            branchLabel.position = CGPoint(x: 10, y: 8)
            row.addChild(branchLabel)

            // Commit ID + time
            let metaText = "\(entry.commitId.prefix(5)) \(relativeTime(from: entry.timestamp))"
            let metaLabel = SKLabelNode(text: metaText)
            metaLabel.fontName = "Menlo"
            metaLabel.fontSize = 7
            metaLabel.fontColor = NSColor(white: 0.4, alpha: 1)
            metaLabel.horizontalAlignmentMode = .left
            metaLabel.verticalAlignmentMode = .center
            metaLabel.position = CGPoint(x: 10, y: -3)
            row.addChild(metaLabel)

            // Commit message (truncated)
            let maxLen = 22
            let displayLabel = entry.label.count > maxLen ? String(entry.label.prefix(maxLen)) + "…" : entry.label
            let messageLabel = SKLabelNode(text: displayLabel)
            messageLabel.fontName = "Menlo"
            messageLabel.fontSize = 8
            messageLabel.fontColor = NSColor(white: 0.55, alpha: 1)
            messageLabel.horizontalAlignmentMode = .left
            messageLabel.verticalAlignmentMode = .center
            messageLabel.position = CGPoint(x: 10, y: -12)
            row.addChild(messageLabel)

            // Type indicator
            if entry.type == "merge" {
                let tag = SKLabelNode(text: "◀")
                tag.fontName = "Menlo-Bold"
                tag.fontSize = 9
                tag.fontColor = C.green
                tag.verticalAlignmentMode = .center
                tag.position = CGPoint(x: -10, y: 0)
                row.addChild(tag)
            } else if entry.type == "tag" {
                let tag = SKLabelNode(text: "🏷")
                tag.fontSize = 10
                tag.verticalAlignmentMode = .center
                tag.position = CGPoint(x: -10, y: 0)
                row.addChild(tag)
            } else if entry.type == "conflict" {
                let tag = SKLabelNode(text: "⚡")
                tag.fontSize = 10
                tag.verticalAlignmentMode = .center
                tag.position = CGPoint(x: -10, y: 0)
                row.addChild(tag)
            } else if entry.type == "branch" {
                let tag = SKLabelNode(text: "▶")
                tag.fontName = "Menlo-Bold"
                tag.fontSize = 9
                tag.fontColor = C.blue
                tag.verticalAlignmentMode = .center
                tag.position = CGPoint(x: -10, y: 0)
                row.addChild(tag)
            }

            // Fade in newest
            if i == visible.count - 1 && entries.count > 0 {
                row.alpha = 0
                row.run(.fadeIn(withDuration: 0.2))
            }

            addChild(row)
        }
    }

    private func drawCurvedLine(from: CGPoint, to: CGPoint, color: NSColor) {
        let path = CGMutablePath()
        path.move(to: from)
        let controlX = (from.x + to.x) / 2
        path.addQuadCurve(to: to, control: CGPoint(x: controlX, y: from.y))

        let line = SKShapeNode(path: path)
        line.strokeColor = color.withAlphaComponent(0.35)
        line.lineWidth = 1.5
        line.zPosition = -1
        addChild(line)
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
