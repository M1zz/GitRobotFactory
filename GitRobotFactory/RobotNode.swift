import SpriteKit

class RobotNode: SKNode {
    internal var slots: [PartSlot: SKNode] = [:]
    private var installedParts: [PartSlot: [RobotPart]] = [:]
    
    override init() {
        super.init()
        setupSlots()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupSlots() {
        // Compact layout - optimized vertical spacing
        let layout: [(PartSlot, CGPoint)] = [
            (.head, CGPoint(x: 0, y: 75)),
            (.torso, CGPoint(x: 0, y: 15)),
            (.leftArm, CGPoint(x: -65, y: 15)),
            (.rightArm, CGPoint(x: 65, y: 15)),
            (.legs, CGPoint(x: 0, y: -45)),
            (.backpack, CGPoint(x: 0, y: -95)),
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

        // Compact slot sizes
        let size = slot == .torso ? CGSize(width: 56, height: 56) : CGSize(width: 48, height: 48)
        let bg = SKShapeNode(rectOf: size, cornerRadius: 7)
        bg.fillColor = NSColor(white: 0.05, alpha: 1)
        bg.strokeColor = C.border
        bg.lineWidth = 1
        bg.name = "slotBg"
        
        // Dashed border for empty
        let dash = SKShapeNode(rectOf: size, cornerRadius: 7)
        dash.fillColor = .clear
        dash.strokeColor = NSColor(white: 0.18, alpha: 1)
        dash.lineWidth = 1
        dash.name = "dash"
        
        let label = SKLabelNode(text: slot.label)
        label.fontSize = 9
        label.fontName = "Helvetica"
        label.fontColor = NSColor(white: 0.22, alpha: 1)
        label.verticalAlignmentMode = .center
        label.name = "label"
        
        container.addChild(bg)
        container.addChild(dash)
        container.addChild(label)
        return container
    }
    
    func installPart(_ part: RobotPart) {
        // Accumulate parts
        if installedParts[part.slot] == nil {
            installedParts[part.slot] = []
        }
        installedParts[part.slot]?.append(part)

        guard let slotNode = slots[part.slot] else { return }

        // Update visual
        if let bg = slotNode.childNode(withName: "slotBg") as? SKShapeNode {
            bg.fillColor = C.green.withAlphaComponent(0.08)
            bg.strokeColor = C.green.withAlphaComponent(0.4)
        }
        if let dash = slotNode.childNode(withName: "dash") as? SKShapeNode {
            dash.isHidden = true
        }

        // Remove old part labels
        slotNode.children.filter { $0.name?.hasPrefix("partEmoji_") ?? false }.forEach { $0.removeFromParent() }

        // Display accumulated parts
        if let parts = installedParts[part.slot] {
            if parts.count == 1 {
                // Single part
                if let label = slotNode.childNode(withName: "label") as? SKLabelNode {
                    label.text = parts[0].emoji
                    label.fontSize = 20
                    label.fontColor = .white
                    label.setScale(0.3)
                    label.run(.sequence([
                        .scale(to: 1.1, duration: 0.12),
                        .scale(to: 1.0, duration: 0.08)
                    ]))
                }
            } else {
                // Multiple parts - stack
                if let label = slotNode.childNode(withName: "label") as? SKLabelNode {
                    label.text = ""
                }

                let spacing: CGFloat = 14
                let totalWidth = CGFloat(parts.count - 1) * spacing
                let startX = -totalWidth / 2

                for (index, p) in parts.enumerated() {
                    let emoji = SKLabelNode(text: p.emoji)
                    emoji.fontSize = 16
                    emoji.fontColor = .white
                    emoji.verticalAlignmentMode = .center
                    emoji.position = CGPoint(x: startX + CGFloat(index) * spacing, y: 0)
                    emoji.name = "partEmoji_\(index)"
                    emoji.zPosition = CGFloat(index)
                    emoji.fontColor = NSColor.white.withAlphaComponent(0.85 + CGFloat(index) * 0.05)

                    slotNode.addChild(emoji)

                    if index == parts.count - 1 {
                        emoji.setScale(0.3)
                        emoji.run(.sequence([
                            .scale(to: 1.15, duration: 0.1),
                            .scale(to: 1.0, duration: 0.08)
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
                bg.fillColor = NSColor(white: 0.05, alpha: 1)
                bg.strokeColor = C.border
            }
            if let dash = node.childNode(withName: "dash") as? SKShapeNode {
                dash.isHidden = false
            }
            if let label = node.childNode(withName: "label") as? SKLabelNode {
                label.text = slot.label
                label.fontSize = 9
                label.fontColor = NSColor(white: 0.22, alpha: 1)
            }
        }
    }
}
