import SpriteKit

class RobotNode: SKNode {
    internal var slots: [PartSlot: SKNode] = [:]
    private var installedParts: [PartSlot: RobotPart] = [:]
    
    override init() {
        super.init()
        setupSlots()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupSlots() {
        let layout: [(PartSlot, CGPoint)] = [
            (.head, CGPoint(x: 0, y: 80)),
            (.torso, CGPoint(x: 0, y: 20)),
            (.leftArm, CGPoint(x: -60, y: 20)),
            (.rightArm, CGPoint(x: 60, y: 20)),
            (.legs, CGPoint(x: 0, y: -45)),
            (.backpack, CGPoint(x: 0, y: -100)),
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
        
        let size = slot == .torso ? CGSize(width: 55, height: 55) : CGSize(width: 48, height: 48)
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
        installedParts[part.slot] = part
        guard let slotNode = slots[part.slot] else { return }
        
        // Update visual
        if let bg = slotNode.childNode(withName: "slotBg") as? SKShapeNode {
            bg.fillColor = C.green.withAlphaComponent(0.1)
            bg.strokeColor = C.green.withAlphaComponent(0.5)
        }
        if let dash = slotNode.childNode(withName: "dash") as? SKShapeNode {
            dash.isHidden = true
        }
        if let label = slotNode.childNode(withName: "label") as? SKLabelNode {
            label.text = part.emoji
            label.fontSize = 24
            label.fontColor = .white
            
            // Bounce animation
            label.setScale(0.3)
            label.run(.sequence([
                .scale(to: 1.2, duration: 0.15),
                .scale(to: 1.0, duration: 0.1)
            ]))
        }
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
