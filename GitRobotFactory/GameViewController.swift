import Cocoa
import SpriteKit

class GameViewController: NSViewController {
    private var skView: SKView!
    private var appearanceObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.width, .height]
        view.addSubview(skView)

        let scene = TitleScene(size: CGSize(width: 1200, height: 800))
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true

        appearanceObservation = view.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async { self?.reloadCurrentScene() }
        }
    }

    private func reloadCurrentScene() {
        guard let currentScene = skView.scene else { return }
        let size = currentScene.size

        let newScene: SKScene
        if let game = currentScene as? GameScene {
            let fresh = GameScene(size: size)
            fresh.scaleMode = .aspectFill
            fresh.missionId = game.missionId
            newScene = fresh
        } else if currentScene is ChapterScene {
            let fresh = ChapterScene(size: size)
            fresh.scaleMode = .aspectFill
            newScene = fresh
        } else if currentScene is CompleteScene {
            let fresh = CompleteScene(size: size)
            fresh.scaleMode = .aspectFill
            newScene = fresh
        } else {
            let fresh = TitleScene(size: size)
            fresh.scaleMode = .aspectFill
            newScene = fresh
        }

        skView.presentScene(newScene)
    }
}
