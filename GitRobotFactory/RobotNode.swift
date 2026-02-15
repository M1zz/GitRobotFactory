import SpriteKit

class RobotNode: SKNode {
    internal var slots: [PartSlot: SKNode] = [:]
    private var installedParts: [PartSlot: [RobotPart]] = [:]  // Changed to array to accumulate parts
    
    override init() {
        super.init()
        setupSlots()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupSlots() {
        // Increased spacing for better visibility
        let layout: [(PartSlot, CGPoint)] = [
            (.head, CGPoint(x: 0, y: 110)),
            (.torso, CGPoint(x: 0, y: 30)),
            (.leftArm, CGPoint(x: -85, y: 30)),
            (.rightArm, CGPoint(x: 85, y: 30)),
            (.legs, CGPoint(x: 0, y: -60)),
            (.backpack, CGPoint(x: 0, y: -135)),
        ]
        
        for (slot, pos) in layout {
            let node = createSlotNode(slot: slot)
            node.position = pos
            node.name = "slot_\(slot.rawValue)"
            addChild(node)
            slots[slot] = node
        }
    }
    
    private func createSlotNode(slot: PartSlot) -> SKNode {
        let container = SKNode()

        // Increased slot sizes
        let size = slot == .torso ? CGSize(width: 70, height: 70) : CGSize(width: 62, height: 62)
        let bg = SKShapeNode(rectOf: size, cornerRadius: 8)
        bg.fillColor = NSColor(white: 0.06, alpha: 1)
        bg.strokeColor = C.border
        bg.lineWidth = 1
        bg.name = "slotBg"
        
        // Dashed border for empty
        let dash = SKShapeNode(rectOf: size, cornerRadius: 8)
        dash.fillColor = .clear
        dash.strokeColor = NSColor(white: 0.2, alpha: 1)
        dash.lineWidth = 1
        dash.name = "dash"
        
        let emoji = SKLabelNode(text: slot.label)
        emoji.fontSize = 10
        emoji.fontName = "Helvetica"
        emoji.fontColor = NSColor(white: 0.25, alpha: 1)
        emoji.verticalAlignmentMode = .center
        emoji.name = "label"
        
        container.addChild(bg)
        container.addChild(dash)
        container.addChild(emoji)
        return container
    }
    
    func installPart(_ part: RobotPart) {
        // Accumulate parts instead of replacing
        if installedParts[part.slot] == nil {
            installedParts[part.slot] = []
        }
        installedParts[part.slot]?.append(part)

        guard let slotNode = slots[part.slot] else { return }

        // Update visual
        if let bg = slotNode.childNode(withName: "slotBg") as? SKShapeNode {
            bg.fillColor = C.green.withAlphaComponent(0.1)
            bg.strokeColor = C.green.withAlphaComponent(0.5)
        }
        if let dash = slotNode.childNode(withName: "dash") as? SKShapeNode {
            dash.isHidden = true
        }

        // Remove old part labels
        slotNode.children.filter { $0.name?.hasPrefix("partEmoji_") ?? false }.forEach { $0.removeFromParent() }

        // Display all accumulated parts
        if let parts = installedParts[part.slot] {
            if parts.count == 1 {
                // Single part: show normally
                if let label = slotNode.childNode(withName: "label") as? SKLabelNode {
                    label.text = parts[0].emoji
                    label.fontSize = 24
                    label.fontColor = .white
                    label.setScale(0.3)
                    label.run(.sequence([
                        .scale(to: 1.2, duration: 0.15),
                        .scale(to: 1.0, duration: 0.1)
                    ]))
                }
            } else {
                // Multiple parts: stack them
                if let label = slotNode.childNode(withName: "label") as? SKLabelNode {
                    label.text = ""  // Hide original label
                }

                // Show parts as a horizontal stack
                let spacing: CGFloat = 16
                let totalWidth = CGFloat(parts.count - 1) * spacing
                let startX = -totalWidth / 2

                for (index, p) in parts.enumerated() {
                    let emoji = SKLabelNode(text: p.emoji)
                    emoji.fontSize = 20
                    emoji.fontColor = .white
                    emoji.verticalAlignmentMode = .center
                    emoji.position = CGPoint(x: startX + CGFloat(index) * spacing, y: 0)
                    emoji.name = "partEmoji_\(index)"
                    emoji.zPosition = CGFloat(index)

                    // Add subtle shadow/glow for depth
                    emoji.fontColor = NSColor.white.withAlphaComponent(0.9 + CGFloat(index) * 0.05)

                    slotNode.addChild(emoji)

                    // Animate only the newest part
                    if index == parts.count - 1 {
                        emoji.setScale(0.3)
                        emoji.run(.sequence([
                            .scale(to: 1.3, duration: 0.15),
                            .scale(to: 1.0, duration: 0.1)
                        ]))
                    }
                }
            }
        }
    }

    func getInstalledParts(for slot: PartSlot) -> [RobotPart] {
        return installedParts[slot] ?? []
    }
    
    func reset() {
        installedParts = [:]
        for (slot, node) in slots {
            if let bg = node.childNode(withName: "slotBg") as? SKShapeNode {
                bg.fillColor = NSColor(white: 0.06, alpha: 1)
                bg.strokeColor = C.border
            }
            if let dash = node.childNode(withName: "dash") as? SKShapeNode {
                dash.isHidden = false
            }
            if let label = node.childNode(withName: "label") as? SKLabelNode {
                label.text = slot.label
                label.fontSize = 10
                label.fontColor = NSColor(white: 0.25, alpha: 1)
            }
        }
    }
}
