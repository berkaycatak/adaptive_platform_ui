import UIKit
import Flutter

// MARK: - Factory
class iOS26ToolbarFactory: NSObject, FlutterPlatformViewFactory {
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
        return iOS26ToolbarPlatformView(
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

// MARK: - Container View with Gradient
class ToolbarContainerView: UIView {
    var gradientLayer: CAGradientLayer?
    var onTraitChange: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        // Extend gradient below the container bounds for smooth fade
        gradientLayer?.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height + 30)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            onTraitChange?()
        }
    }
}

// MARK: - Platform View
class iOS26ToolbarPlatformView: NSObject, FlutterPlatformView {
    private var containerView: ToolbarContainerView
    private var navigationBar: UINavigationBar
    private var navigationItem: UINavigationItem
    private var channel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        containerView = ToolbarContainerView(frame: frame)
        navigationBar = UINavigationBar()
        navigationItem = UINavigationItem()
        channel = FlutterMethodChannel(
            name: "adaptive_platform_ui/ios26_toolbar_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        setupGradient()
        setupNavigationBar()

        if let params = args as? [String: Any] {
            configureItems(params)
        }

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call, result: result)
        }
    }

    func view() -> UIView {
        return containerView
    }

    private func setupGradient() {
        containerView.clipsToBounds = false

        // Add gradient layer for better text readability
        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        containerView.layer.insertSublayer(gradientLayer, at: 0)
        containerView.gradientLayer = gradientLayer
        containerView.onTraitChange = { [weak self] in
            self?.updateGradientColors()
        }
        updateGradientColors()
    }

    private func setupNavigationBar() {
        containerView.backgroundColor = .clear

        // Make navigation bar transparent to show gradient behind
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.items = [navigationItem]

        // Configure transparent appearance
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            if #available(iOS 15.0, *) {
                navigationBar.compactAppearance = appearance
            }
        }

        containerView.addSubview(navigationBar)

        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            navigationBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    private func updateGradientColors() {
        let isDarkMode = containerView.traitCollection.userInterfaceStyle == .dark
        let baseColor = isDarkMode ? UIColor.black : UIColor.white

        // Subtle gradient for text readability
        containerView.gradientLayer?.colors = [
            baseColor.withAlphaComponent(0.85).cgColor,  // 0% - slightly transparent top
            baseColor.withAlphaComponent(0.6).cgColor,   // 40% - fade
            baseColor.withAlphaComponent(0.2).cgColor,   // 70% - more fade
            baseColor.withAlphaComponent(0.0).cgColor    // 100% - transparent
        ]
        containerView.gradientLayer?.locations = [0.0, 0.4, 0.7, 1.0]
    }

    private func configureItems(_ params: [String: Any]) {
        // Title
        if let title = params["title"] as? String {
            navigationItem.title = title
        }

        // Leading/Back button
        var leadingItems: [UIBarButtonItem] = []

        if let leading = params["leading"] as? String {
            let leadingButton: UIBarButtonItem
            if leading.isEmpty {
                leadingButton = UIBarButtonItem(
                    image: UIImage(systemName: "chevron.left"),
                    style: .plain,
                    target: self,
                    action: #selector(leadingTapped)
                )
            } else {
                leadingButton = UIBarButtonItem(
                    title: leading,
                    style: .plain,
                    target: self,
                    action: #selector(leadingTapped)
                )
            }
            leadingItems.append(leadingButton)
        }

        // Process actions
        var leftGroup: [UIBarButtonItem] = []
        var rightGroup: [UIBarButtonItem] = []

        if let actions = params["actions"] as? [[String: Any]] {
            // First pass: check if any flexible spacer exists
            let hasFlexible = actions.contains { ($0["spacerAfter"] as? Int) == 2 }

            // Second pass: build buttons
            var foundFlexible = false

            for (index, action) in actions.enumerated() {
                var button: UIBarButtonItem?

                if let icon = action["icon"] as? String {
                    button = UIBarButtonItem(
                        image: UIImage(systemName: icon),
                        style: .plain,
                        target: self,
                        action: #selector(actionTapped(_:))
                    )
                } else if let title = action["title"] as? String {
                    button = UIBarButtonItem(
                        title: title,
                        style: .plain,
                        target: self,
                        action: #selector(actionTapped(_:))
                    )
                }

                if let btn = button {
                    btn.tag = index

                    // If no flexible spacer exists, all go to right
                    // If flexible exists, split by it
                    if !hasFlexible {
                        rightGroup.append(btn)
                    } else if !foundFlexible {
                        leftGroup.append(btn)
                    } else {
                        rightGroup.append(btn)
                    }

                    // Check for spacers
                    if let spacerAfter = action["spacerAfter"] as? Int {
                        if spacerAfter == 1 {
                            // Fixed space
                            if #available(iOS 16.0, *) {
                                if !hasFlexible {
                                    rightGroup.append(.fixedSpace(12))
                                } else if !foundFlexible {
                                    leftGroup.append(.fixedSpace(12))
                                } else {
                                    rightGroup.append(.fixedSpace(12))
                                }
                            }
                        } else if spacerAfter == 2 {
                            // Flexible spacer - mark split point
                            foundFlexible = true
                        }
                    }
                }
            }
        }

        // Assign to navigation item
        navigationItem.leftBarButtonItems = leadingItems + leftGroup
        navigationItem.rightBarButtonItems = rightGroup.reversed()
    }

    @objc private func leadingTapped() {
        channel.invokeMethod("onLeadingTapped", arguments: nil)
    }

    @objc private func actionTapped(_ sender: UIBarButtonItem) {
        channel.invokeMethod("onActionTapped", arguments: ["index": sender.tag])
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateTitle":
            if let args = call.arguments as? [String: Any], let title = args["title"] as? String {
                navigationItem.title = title
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
