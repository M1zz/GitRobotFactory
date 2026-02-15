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
    private let maxVisible = 10
    private let entryHeight: CGFloat = 50  // Increased for commit ID and time
    private let laneWidth: CGFloat = 22
    private var commitCounter = 0

    // Track active branches and their lanes
    private var branchLanes: [String: Int] = ["main": 0]
    private var nextLane = 1

    override init() {
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }

    func addEntry(branch: String, label: String, type: String = "commit") {
        // Generate commit ID (7-character hash-like)
        let commitId = generateCommitId()

        let entry = CommitEntry(
            branch: branch,
            label: label,
            type: type,
            commitId: commitId,
            timestamp: Date()
        )
        entries.append(entry)

        // Assign lane to new branch
        if branchLanes[branch] == nil {
            branchLanes[branch] = nextLane
            nextLane += 1
        }

        rebuild()
    }

    private func generateCommitId() -> String {
        commitCounter += 1
        // Generate a git-like short hash
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
        if seconds < 60 {
            return "\(seconds)초 전"
        } else if seconds < 3600 {
            return "\(seconds / 60)분 전"
        } else if seconds < 86400 {
            return "\(seconds / 3600)시간 전"
        } else {
            return "\(seconds / 86400)일 전"
        }
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
            let y = CGFloat(visible.count - 1 - i) * entryHeight
            let lane = branchLanes[entry.branch] ?? 0
            let x = CGFloat(lane) * laneWidth

            let row = SKNode()
            row.position = CGPoint(x: x, y: y)

            // Dot
            let dotSize: CGFloat = 8
            let dot = SKShapeNode(circleOfRadius: dotSize / 2)
            dot.fillColor = nodeColor(entry.type, branch: entry.branch)
            dot.strokeColor = nodeColor(entry.type, branch: entry.branch).blended(withFraction: 0.3, of: .white) ?? .white
            dot.lineWidth = 1.5
            dot.position = CGPoint(x: 0, y: 0)
            row.addChild(dot)

            // Connect to previous entry
            if i < visible.count - 1 {
                let nextEntry = visible[i + 1]
                let nextLane = branchLanes[nextEntry.branch] ?? 0
                let nextX = CGFloat(nextLane) * laneWidth
                let nextY = y - entryHeight

                if entry.type == "merge" {
                    // Merge: draw curved line from source branch to target
                    drawMergeLine(from: CGPoint(x: x, y: y - dotSize/2),
                                  to: CGPoint(x: nextX, y: nextY + dotSize/2),
                                  color: C.branchColor(entry.branch))
                } else if entry.type == "branch" {
                    // Branch: draw curved line splitting off
                    drawBranchLine(from: CGPoint(x: nextX, y: nextY + dotSize/2),
                                   to: CGPoint(x: x, y: y - dotSize/2),
                                   color: C.branchColor(entry.branch))
                } else if lane == nextLane {
                    // Same branch: straight line
                    let line = SKShapeNode(rectOf: CGSize(width: 2, height: entryHeight - dotSize))
                    line.fillColor = C.branchColor(entry.branch).withAlphaComponent(0.4)
                    line.strokeColor = .clear
                    line.position = CGPoint(x: 0, y: -entryHeight / 2)
                    row.addChild(line)
                } else {
                    // Different branch: curved connecting line
                    drawCurvedLine(from: CGPoint(x: x, y: y - dotSize/2),
                                   to: CGPoint(x: nextX, y: nextY + dotSize/2),
                                   color: C.branchColor(entry.branch))
                }
            }

            // Branch badge (top)
            let badgeLabel = SKLabelNode(text: entry.branch)
            badgeLabel.fontName = "Menlo"
            badgeLabel.fontSize = 10  // Increased from 8
            badgeLabel.fontColor = C.branchColor(entry.branch)
            badgeLabel.horizontalAlignmentMode = .left
            badgeLabel.verticalAlignmentMode = .center
            badgeLabel.position = CGPoint(x: 14, y: 12)
            row.addChild(badgeLabel)

            // Commit ID and time (middle)
            let timeStr = relativeTime(from: entry.timestamp)
            let metaText = "\(entry.commitId) • \(timeStr)"
            let metaLabel = SKLabelNode(text: metaText)
            metaLabel.fontName = "Menlo"
            metaLabel.fontSize = 8  // Increased from 6
            metaLabel.fontColor = NSColor(white: 0.45, alpha: 1)
            metaLabel.horizontalAlignmentMode = .left
            metaLabel.verticalAlignmentMode = .center
            metaLabel.position = CGPoint(x: 14, y: 2)
            row.addChild(metaLabel)

            // Commit message (bottom)
            let messageLabel = SKLabelNode(text: entry.label)
            messageLabel.fontName = "Menlo"
            messageLabel.fontSize = 9  // Increased from 7
            messageLabel.fontColor = NSColor(white: 0.6, alpha: 1)
            messageLabel.horizontalAlignmentMode = .left
            messageLabel.verticalAlignmentMode = .center
            messageLabel.preferredMaxLayoutWidth = 250
            messageLabel.numberOfLines = 1
            messageLabel.position = CGPoint(x: 14, y: -8)
            row.addChild(messageLabel)

            // Type indicator
            if entry.type == "merge" {
                let tag = SKLabelNode(text: "◀")
                tag.fontName = "Menlo-Bold"
                tag.fontSize = 11  // Increased from 9
                tag.fontColor = C.green
                tag.verticalAlignmentMode = .center
                tag.position = CGPoint(x: -12, y: 0)
                row.addChild(tag)
            } else if entry.type == "tag" {
                let tag = SKLabelNode(text: "🏷️")
                tag.fontSize = 12  // Increased from 10
                tag.verticalAlignmentMode = .center
                tag.position = CGPoint(x: -14, y: 0)
                row.addChild(tag)
            } else if entry.type == "conflict" {
                let tag = SKLabelNode(text: "⚡")
                tag.fontSize = 12  // Increased from 10
                tag.verticalAlignmentMode = .center
                tag.position = CGPoint(x: -14, y: 0)
                row.addChild(tag)
            } else if entry.type == "branch" {
                let tag = SKLabelNode(text: "▶")
                tag.fontName = "Menlo-Bold"
                tag.fontSize = 11  // Increased from 9
                tag.fontColor = C.blue
                tag.verticalAlignmentMode = .center
                tag.position = CGPoint(x: -12, y: 0)
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

    private func drawCurvedLine(from: CGPoint, to: CGPoint, color: NSColor) {
        let path = CGMutablePath()
        path.move(to: from)

        let controlX = (from.x + to.x) / 2
        path.addQuadCurve(to: to, control: CGPoint(x: controlX, y: from.y))

        let line = SKShapeNode(path: path)
        line.strokeColor = color.withAlphaComponent(0.4)
        line.lineWidth = 2
        line.zPosition = -1
        addChild(line)
    }

    private func drawBranchLine(from: CGPoint, to: CGPoint, color: NSColor) {
        let path = CGMutablePath()
        path.move(to: from)

        let controlX = (from.x + to.x) / 2
        let controlY = (from.y + to.y) / 2
        path.addQuadCurve(to: to, control: CGPoint(x: controlX, y: controlY))

        let line = SKShapeNode(path: path)
        line.strokeColor = color.withAlphaComponent(0.5)
        line.lineWidth = 2
        line.zPosition = -1
        addChild(line)
    }

    private func drawMergeLine(from: CGPoint, to: CGPoint, color: NSColor) {
        let path = CGMutablePath()
        path.move(to: from)

        let controlX = (from.x + to.x) / 2
        let controlY = (from.y + to.y) / 2
        path.addQuadCurve(to: to, control: CGPoint(x: controlX, y: controlY))

        let line = SKShapeNode(path: path)
        line.strokeColor = C.green.withAlphaComponent(0.6)
        line.lineWidth = 2
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
