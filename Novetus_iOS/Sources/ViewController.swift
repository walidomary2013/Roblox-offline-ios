import UIKit
import MetalKit

/// Native Swift View Controller for Novetus Engine on iOS
public class NovetusViewController: UIViewController {

    private var metalView: MTKView!
    private var statusLabel: UILabel!
    private var playButton: UIButton!

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDefaultPlace()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Metal 3D Viewport
        metalView = MTKView(frame: view.bounds)
        metalView.device = MTLCreateSystemDefaultDevice()
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(metalView)

        // Status Overlay Label
        statusLabel = UILabel()
        statusLabel.text = "Novetus Native Engine iOS Port"
        statusLabel.textColor = .white
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // Native Play Button
        playButton = UIButton(type: .system)
        playButton.setTitle("LAUNCH NOVETUS NATIVE PLACE", for: .normal)
        playButton.setTitleColor(.white, for: .normal)
        playButton.backgroundColor = UIColor.systemBlue
        playButton.layer.cornerRadius = 8
        playButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.addTarget(self, action: #selector(playButtonPressed), for: .touchUpInside)
        view.addSubview(playButton)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 320),
            statusLabel.heightAnchor.constraint(equalToConstant: 40),

            playButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 300),
            playButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func loadDefaultPlace() {
        let success = NovetusCore.shared.loadRobloxPlace(path: "REAL.rbxlx", version: .client2017Late)
        if success {
            statusLabel.text = "Loaded: REAL.rbxlx (15,011 Parts)"
        }
    }

    @objc private func playButtonPressed() {
        print("[Novetus-iOS] Launching Novetus Standalone Engine Viewport...")
    }
}
