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

    private var isDark: Bool = false
    private var perActionTintTags: Set<Int> = []

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

        if let params = args as? [String: Any] {
            isDark = params["isDark"] as? Bool ?? false
        }

        super.init()

        // Apply Flutter's brightness override
        if #available(iOS 13.0, *) {
            containerView.overrideUserInterfaceStyle = isDark ? .dark : .light
        }

        setupGradient()
        setupNavigationBar()

        if let params = args as? [String: Any] {
            currentParams = params
            configureItems(params)
            // Apply global tint color after configuring items
            if let n = params["tint"] as? NSNumber {
                let color = Self.colorFromARGB(n.intValue)
                containerView.tintColor = color
                navigationBar.tintColor = color
                // Apply to items that don't have their own per-action tint
                for item in (navigationItem.leftBarButtonItems ?? []) + (navigationItem.rightBarButtonItems ?? []) {
                    if !perActionTintTags.contains(item.tag) {
                        item.tintColor = color
                    }
                }
            }
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
        configureItems(params, on: navigationItem)
    }

    private func configureItems(_ params: [String: Any], on navigationItem: UINavigationItem) {
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
                        image: UIImage(systemName: icon) ?? UIImage(named: icon),
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

                    // Apply prominent style (iOS 26+)
                    if action["prominent"] as? Bool == true {
                        if #available(iOS 26.0, *) {
                            btn.style = .prominent
                        }
                    }

                    // Apply per-action tint color
                    if let n = action["tint"] as? NSNumber {
                        btn.tintColor = Self.colorFromARGB(n.intValue)
                        perActionTintTags.insert(index)
                    }

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

    // MARK: - Fixed toolbar: swapping one page's items for another's

    /// Builds a navigation item for one page's content.
    private func makeItem(_ params: [String: Any]) -> UINavigationItem {
        perActionTintTags.removeAll()
        let item = UINavigationItem()
        // The back button is an ordinary leading item that reports to Flutter,
        // which owns the navigation stack; the system one must not appear.
        item.hidesBackButton = true
        configureItems(params, on: item)
        if let n = params["tint"] as? NSNumber {
            let color = Self.colorFromARGB(n.intValue)
            for barItem in (item.leftBarButtonItems ?? []) + (item.rightBarButtonItems ?? []) {
                if !perActionTintTags.contains(barItem.tag) {
                    barItem.tintColor = color
                }
            }
        }
        return item
    }

    private func applyBarTint(_ params: [String: Any]) {
        if let n = params["tint"] as? NSNumber {
            let color = Self.colorFromARGB(n.intValue)
            containerView.tintColor = color
            navigationBar.tintColor = color
        } else {
            containerView.tintColor = nil
            navigationBar.tintColor = nil
        }
    }

    /// Replaces the content of the bar with another page's, at once. The bar
    /// itself stays where it is.
    private func setItems(_ params: [String: Any]) {
        if itemTransition != nil { endItemTransition(completed: false) }
        applyBarTint(params)
        let target = makeItem(params)
        navigationBar.setItems([target], animated: false)
        navigationItem = target
        currentParams = params
    }

    // MARK: - Fixed toolbar: a swap that follows the page transition

    // A UINavigationBar outside a UINavigationController does not play the
    // system item transition, and even if it did, its fixed length could not
    // follow a back swipe or a custom route duration. So the swap is a
    // crossfade frozen at its first frame, and Flutter moves it: by the route
    // animation on push and pop, by the finger on a back swipe.

    /// Length of the frozen crossfade. Arbitrary: progress is mapped onto it.
    private static let itemTransitionDuration: CFTimeInterval = 1.0
    private static let itemTransitionKey = "adaptive_toolbar_item_transition"

    private struct ItemTransition {
        let from: UINavigationItem
        let fromParams: [String: Any]
        let to: UINavigationItem
        let pausedAt: CFTimeInterval
    }

    private var itemTransition: ItemTransition?
    private var currentParams: [String: Any] = [:]

    /// Starts the crossfade into [params] and freezes it at its first frame,
    /// so `updateItemTransition` can move it.
    private func beginItemTransition(_ params: [String: Any]) {
        if itemTransition != nil { endItemTransition(completed: true) }
        let from = navigationItem
        let to = makeItem(params)

        let layer = navigationBar.layer
        let pausedAt = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0
        layer.timeOffset = pausedAt

        let fade = CATransition()
        fade.type = .fade
        fade.duration = Self.itemTransitionDuration
        fade.timingFunction = CAMediaTimingFunction(name: .linear)
        fade.beginTime = pausedAt
        fade.fillMode = .both
        fade.isRemovedOnCompletion = false
        layer.add(fade, forKey: Self.itemTransitionKey)

        applyBarTint(params)
        navigationBar.setItems([to], animated: false)
        navigationItem = to

        itemTransition = ItemTransition(
            from: from, fromParams: currentParams, to: to, pausedAt: pausedAt)
        currentParams = params
    }

    private func updateItemTransition(_ progress: Double) {
        guard let transition = itemTransition else { return }
        // Stay just inside the ends: at exactly the full length the frozen
        // animation would be treated as finished and dropped.
        let clamped = max(0.0, min(0.999, progress))
        navigationBar.layer.timeOffset =
            transition.pausedAt + clamped * Self.itemTransitionDuration
    }

    /// Lets go of the frozen crossfade and settles on the page that won:
    /// the new one when [completed], the previous one when a back swipe was
    /// cancelled.
    private func endItemTransition(completed: Bool) {
        guard let transition = itemTransition else { return }
        itemTransition = nil

        let layer = navigationBar.layer
        layer.removeAnimation(forKey: Self.itemTransitionKey)
        if !completed {
            applyBarTint(transition.fromParams)
            navigationBar.setItems([transition.from], animated: false)
            navigationItem = transition.from
            currentParams = transition.fromParams
        }
        layer.speed = 1
        layer.timeOffset = 0
        layer.beginTime = 0
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
        case "setBrightness":
            if let args = call.arguments as? [String: Any],
               let dark = args["isDark"] as? Bool {
                isDark = dark
                if #available(iOS 13.0, *) {
                    containerView.overrideUserInterfaceStyle = dark ? .dark : .light
                }
            }
            result(nil)
        case "updateActions":
            if let args = call.arguments as? [String: Any] {
                perActionTintTags.removeAll()
                configureItems(args)
                // Re-apply global tint to items without per-action tint
                if let globalTint = navigationBar.tintColor {
                    for item in (navigationItem.leftBarButtonItems ?? []) + (navigationItem.rightBarButtonItems ?? []) {
                        if !perActionTintTags.contains(item.tag) {
                            item.tintColor = globalTint
                        }
                    }
                }
            }
            result(nil)
        case "setItems":
            if let args = call.arguments as? [String: Any] {
                setItems(args)
            }
            result(nil)
        case "beginItemTransition":
            if let args = call.arguments as? [String: Any] {
                beginItemTransition(args)
            }
            result(nil)
        case "updateItemTransition":
            if let args = call.arguments as? [String: Any],
               let progress = args["progress"] as? Double {
                updateItemTransition(progress)
            }
            result(nil)
        case "endItemTransition":
            if let args = call.arguments as? [String: Any] {
                endItemTransition(completed: args["completed"] as? Bool ?? false)
            }
            result(nil)
        case "setStyle":
            if let args = call.arguments as? [String: Any] {
                if let tintValue = args["tint"] {
                    if let n = tintValue as? NSNumber {
                        let color = Self.colorFromARGB(n.intValue)
                        containerView.tintColor = color
                        navigationBar.tintColor = color
                        for item in (navigationItem.leftBarButtonItems ?? []) + (navigationItem.rightBarButtonItems ?? []) {
                            if !perActionTintTags.contains(item.tag) {
                                item.tintColor = color
                            }
                        }
                    } else if tintValue is NSNull {
                        containerView.tintColor = nil
                        navigationBar.tintColor = nil
                        for item in (navigationItem.leftBarButtonItems ?? []) + (navigationItem.rightBarButtonItems ?? []) {
                            if !perActionTintTags.contains(item.tag) {
                                item.tintColor = nil
                            }
                        }
                    }
                }
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static func colorFromARGB(_ argb: Int) -> UIColor {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
