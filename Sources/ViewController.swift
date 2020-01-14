import TextRenderer
import UIKit

class ViewController: UIViewController {
    @IBOutlet private var label: UILabel!
    @IBOutlet private var metalView: MetalView!
    private var textRenderer: TextRenderer?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.textRenderer = TextRenderer(metalLayer: self.metalView.metalLayer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.textRenderer!.render(self.label.text!, fontName: self.label.font.fontName)
    }
}
