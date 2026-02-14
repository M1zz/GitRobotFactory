import Cocoa
import SpriteKit

class GameViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.width, .height]
        view.addSubview(skView)
        
        let scene = TitleScene(size: CGSize(width: 1200, height: 800))
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true
    }
}
