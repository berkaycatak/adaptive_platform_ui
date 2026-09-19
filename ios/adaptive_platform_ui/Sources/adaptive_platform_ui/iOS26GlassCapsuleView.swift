import UIKit
import Flutter

// A vertical Liquid Glass capsule holding a column of icon buttons. It is the
// building block of the iPhone Duo trailing bar, where the system shows each
// group of toolbar items, and the tab bar, as one glass capsule.

// MARK: - Factory
class iOS26GlassCapsuleFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return iOS26GlassCapsuleView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

// MARK: - Container
private class GlassCapsuleContainer: UIView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}

// MARK: - Platform View
class iOS26GlassCapsuleView: NSObject, FlutterPlatformView {
    private let container = GlassCapsuleContainer()
    private let effectView = UIVisualEffectView()
    private let selectionView = UIView()
    private let stack = UIStackView()
    private var channel: FlutterMethodChannel

    private var items: [[String: Any]] = []
    private var buttons: [UIButton] = []
    private var badges: [Int: UILabel] = [:]
    private var selectedIndex: Int?
    private var tint: UIColor?
    private var inset: CGFloat = 0
    private var stackTop: NSLayoutConstraint?
    private var stackBottom: NSLayoutConstraint?
    private var imageCache: [String: UIImage] = [:]

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        channel = FlutterMethodChannel(
            name: "adaptive_platform_ui/ios26_glass_capsule_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        container.frame = frame
        container.backgroundColor = .clear

        if #available(iOS 26.0, *) {
            let glass = UIGlassEffect()
            glass.isInteractive = true
            effectView.effect = glass
        } else {
            effectView.effect = UIBlurEffect(style: .systemThinMaterial)
        }
        effectView.clipsToBounds = true
        effectView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(effectView)

        selectionView.backgroundColor = UIColor.label.withAlphaComponent(0.1)
        selectionView.isUserInteractionEnabled = false
        selectionView.isHidden = true
        effectView.contentView.addSubview(selectionView)

        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        effectView.contentView.addSubview(stack)

        let top = stack.topAnchor.constraint(equalTo: effectView.contentView.topAnchor)
        let bottom = stack.bottomAnchor.constraint(equalTo: effectView.contentView.bottomAnchor)
        stackTop = top
        stackBottom = bottom
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: container.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            effectView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.leadingAnchor.constraint(equalTo: effectView.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: effectView.contentView.trailingAnchor),
            top,
            bottom,
        ])

        container.onLayout = { [weak self] in self?.layoutChrome(animated: false) }

        if let params = args as? [String: Any] {
            apply(params)
        }

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return result(nil) }
            switch call.method {
            case "update":
                if let params = call.arguments as? [String: Any] {
                    self.apply(params)
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func view() -> UIView { container }

    // MARK: Content

    private func apply(_ params: [String: Any]) {
        if let dark = params["isDark"] as? Bool {
            container.overrideUserInterfaceStyle = dark ? .dark : .light
        }
        if let n = params["tint"] as? NSNumber {
            tint = Self.colorFromARGB(n.intValue)
        } else if params.keys.contains("items") {
            tint = nil
        }
        if let value = params["inset"] as? NSNumber {
            inset = CGFloat(truncating: value)
            stackTop?.constant = inset
            stackBottom?.constant = -inset
        }

        let newSelected = (params["selectedIndex"] as? NSNumber)?.intValue
        let selectionChanged = newSelected != selectedIndex
        selectedIndex = newSelected

        if let newItems = params["items"] as? [[String: Any]] {
            let same = (newItems as NSArray).isEqual(to: items)
            items = newItems
            if !same || buttons.count != newItems.count {
                rebuildButtons()
            }
        }
        refreshAppearance()
        container.setNeedsLayout()
        layoutChrome(animated: selectionChanged && !buttons.isEmpty)
    }

    private func rebuildButtons() {
        NSLayoutConstraint.deactivate(selectionConstraints)
        selectionConstraints = []
        selectionAnchor = nil
        buttons.forEach { $0.removeFromSuperview() }
        buttons = []
        badges.values.forEach { $0.removeFromSuperview() }
        badges = [:]

        for (index, item) in items.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            if let entries = item["menu"] as? [[String: Any]] {
                // The overflow control: a menu of the items that did not fit.
                button.showsMenuAsPrimaryAction = true
                button.menu = UIMenu(children: entries.map { entry in
                    let id = (entry["id"] as? NSNumber)?.intValue ?? -1
                    let symbol = entry["symbol"] as? String
                    return UIAction(
                        title: entry["title"] as? String ?? "",
                        image: symbol.flatMap { UIImage(systemName: $0) ?? UIImage(named: $0) }
                    ) { [weak self] _ in
                        self?.channel.invokeMethod("onMenuItemTapped", arguments: ["id": id])
                    }
                })
            } else {
                button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
            }
            if let label = item["label"] as? String {
                button.accessibilityLabel = label
            }
            stack.addArrangedSubview(button)
            buttons.append(button)

            if let count = (item["badge"] as? NSNumber)?.intValue, count > 0 {
                let badge = UILabel()
                badge.text = count > 99 ? "99+" : "\(count)"
                badge.font = .systemFont(ofSize: 11, weight: .semibold)
                badge.textColor = .white
                badge.textAlignment = .center
                badge.backgroundColor = .systemRed
                badge.clipsToBounds = true
                badge.isUserInteractionEnabled = false
                badge.layer.cornerRadius = 9
                badge.translatesAutoresizingMaskIntoConstraints = false
                // Above the glass, so the capsule's rounded clipping does not
                // cut it, and tied to its button so it follows every layout.
                container.addSubview(badge)
                let width = badge.widthAnchor.constraint(
                    equalToConstant: max(18, badge.intrinsicContentSize.width + 8))
                NSLayoutConstraint.activate([
                    badge.heightAnchor.constraint(equalToConstant: 18),
                    width,
                    badge.centerXAnchor.constraint(equalTo: button.centerXAnchor, constant: 11),
                    badge.centerYAnchor.constraint(equalTo: button.centerYAnchor, constant: -12),
                ])
                badges[index] = badge
            }
        }
    }

    private func refreshAppearance() {
        for (index, button) in buttons.enumerated() {
            let item = items[index]
            let selected = index == selectedIndex
            let itemTint = (item["tint"] as? NSNumber).map { Self.colorFromARGB($0.intValue) }

            var config = UIButton.Configuration.plain()
            config.contentInsets = .zero
            config.preferredSymbolConfigurationForImage =
                UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)

            if let image = image(for: item, selected: selected, index: index) {
                config.image = image
            } else if let title = item["title"] as? String {
                var text = AttributedString(title)
                text.font = .systemFont(ofSize: 12, weight: .medium)
                config.attributedTitle = text
            }
            let color: UIColor
            if selectedIndex != nil {
                // A tab: tinted while selected, label colour otherwise.
                color = selected ? (itemTint ?? tint ?? .systemBlue) : .label
            } else {
                color = itemTint ?? tint ?? .label
            }
            config.baseForegroundColor = color
            button.configuration = config
            button.tintColor = color
        }
    }

    /// An SF Symbol (or asset catalog image) is tinted; a picture from the
    /// Flutter assets, a file or the network keeps its colours, as an avatar.
    private func image(for item: [String: Any], selected: Bool, index: Int) -> UIImage? {
        let symbol = (selected ? item["selectedSymbol"] as? String : nil) ?? item["symbol"] as? String
        if let symbol = symbol, !symbol.isEmpty {
            return UIImage(systemName: symbol) ?? UIImage(named: symbol)
        }
        if let asset = item["asset"] as? String, !asset.isEmpty {
            let key = FlutterDartProject.lookupKey(forAsset: asset)
            if let path = Bundle.main.path(forResource: key, ofType: nil),
               let image = UIImage(contentsOfFile: path) {
                return Self.avatar(image)
            }
        }
        if let file = item["file"] as? String, !file.isEmpty,
           let image = UIImage(contentsOfFile: file) {
            return Self.avatar(image)
        }
        if let network = item["network"] as? String, !network.isEmpty {
            if let cached = imageCache[network] { return cached }
            fetch(network)
            return UIImage(systemName: "person.crop.circle")
        }
        return nil
    }

    private func fetch(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            let avatar = Self.avatar(image)
            DispatchQueue.main.async {
                self?.imageCache[urlString] = avatar
                self?.refreshAppearance()
            }
        }.resume()
    }

    private static func avatar(_ image: UIImage, side: CGFloat = 26) -> UIImage {
        let size = CGSize(width: side, height: side)
        let rendered = UIGraphicsImageRenderer(size: size).image { _ in
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).addClip()
            let scale = max(side / image.size.width, side / image.size.height)
            let w = image.size.width * scale
            let h = image.size.height * scale
            image.draw(in: CGRect(x: (side - w) / 2, y: (side - h) / 2, width: w, height: h))
        }
        return rendered.withRenderingMode(.alwaysOriginal)
    }

    // MARK: Layout

    private var selectionConstraints: [NSLayoutConstraint] = []
    private weak var selectionAnchor: UIButton?

    private func layoutChrome(animated: Bool) {
        let width = container.bounds.width
        if width > 0 {
            effectView.layer.cornerRadius = width / 2
            effectView.layer.cornerCurve = .continuous
            selectionView.layer.cornerRadius = (width - 6) / 2
            selectionView.layer.cornerCurve = .continuous
        }

        guard let selected = selectedIndex, selected < buttons.count else {
            selectionView.isHidden = true
            return
        }
        let button = buttons[selected]
        guard selectionAnchor !== button else { return }
        let wasVisible = !selectionView.isHidden && selectionAnchor != nil
        selectionAnchor = button

        // The highlight follows the selected button through constraints, so
        // it is right on every layout pass, not only the one it was set in.
        NSLayoutConstraint.deactivate(selectionConstraints)
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        selectionConstraints = [
            selectionView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            selectionView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            selectionView.widthAnchor.constraint(equalTo: button.widthAnchor, constant: -6),
            selectionView.heightAnchor.constraint(equalTo: button.heightAnchor),
        ]
        NSLayoutConstraint.activate(selectionConstraints)
        selectionView.isHidden = false

        if animated && wasVisible {
            UIView.animate(
                withDuration: 0.35, delay: 0,
                usingSpringWithDamping: 0.8, initialSpringVelocity: 0,
                options: [.beginFromCurrentState],
                animations: { self.effectView.contentView.layoutIfNeeded() })
        }
    }

    @objc private func tapped(_ sender: UIButton) {
        channel.invokeMethod("onItemTapped", arguments: ["index": sender.tag])
    }

    private static func colorFromARGB(_ argb: Int) -> UIColor {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
