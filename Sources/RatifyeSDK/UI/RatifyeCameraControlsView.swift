import UIKit

protocol RatifyeCameraControlsViewDelegate: AnyObject {
    func cameraControlsDidTapSwitchCamera(_ controls: RatifyeCameraControlsView)
    func cameraControlsDidTapFlash(_ controls: RatifyeCameraControlsView)
    func cameraControlsDidTapGallery(_ controls: RatifyeCameraControlsView)
}

/// Flash, gallery, and camera-switch actions with SF Symbol icons.
final class RatifyeCameraControlsView: UIView {
    weak var delegate: RatifyeCameraControlsViewDelegate?

    private let flashButton = RatifyeCameraControlsView.makeIconButton(
        systemName: "bolt.slash.fill",
        accessibilityLabel: "Flash off"
    )
    private let galleryButton = RatifyeCameraControlsView.makeIconButton(
        systemName: "photo.on.rectangle.angled",
        accessibilityLabel: "Choose from gallery"
    )
    private let switchButton = RatifyeCameraControlsView.makeIconButton(
        systemName: "camera.rotate.fill",
        accessibilityLabel: "Switch camera"
    )

    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.35)
        layer.cornerRadius = 28
        clipsToBounds = true

        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        [flashButton, galleryButton, switchButton].forEach { stack.addArrangedSubview($0) }

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            flashButton.widthAnchor.constraint(equalToConstant: 44),
            flashButton.heightAnchor.constraint(equalToConstant: 44),
            galleryButton.widthAnchor.constraint(equalToConstant: 44),
            galleryButton.heightAnchor.constraint(equalToConstant: 44),
            switchButton.widthAnchor.constraint(equalToConstant: 44),
            switchButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        flashButton.addTarget(self, action: #selector(flashTapped), for: .touchUpInside)
        galleryButton.addTarget(self, action: #selector(galleryTapped), for: .touchUpInside)
        switchButton.addTarget(self, action: #selector(switchTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setFlashOn(_ isOn: Bool, available: Bool) {
        flashButton.isEnabled = available
        flashButton.alpha = available ? 1 : 0.4
        let name = isOn ? "bolt.fill" : "bolt.slash.fill"
        flashButton.setImage(UIImage(systemName: name), for: .normal)
        flashButton.accessibilityLabel = isOn ? "Flash on" : "Flash off"
    }

    private static func makeIconButton(systemName: String, accessibilityLabel: String) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.accessibilityLabel = accessibilityLabel
        return button
    }

    @objc private func flashTapped() { delegate?.cameraControlsDidTapFlash(self) }
    @objc private func galleryTapped() { delegate?.cameraControlsDidTapGallery(self) }
    @objc private func switchTapped() { delegate?.cameraControlsDidTapSwitchCamera(self) }
}
