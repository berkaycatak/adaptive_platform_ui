import UIKit
import Flutter

/// Factory for creating iOS 26 native UIToolbar platform views
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

/// Native iOS 26 UIToolbar platform view
class iOS26ToolbarPlatformView: NSObject, FlutterPlatformView {
    private var _containerView: UIView
    private var _toolbar: UIToolbar
    private var _viewId: Int64
    private var _channel: FlutterMethodChannel

    // Cache current state
    private var _currentTitle: String?
    private var _currentLeading: String?
    private var _currentActions: [[String: Any]]?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _containerView = UIView(frame: frame)
        _toolbar = UIToolbar()
        _viewId = viewId
        _channel = FlutterMethodChannel(
            name: "adaptive_platform_ui/ios26_toolbar_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        // Add toolbar to container
        _containerView.addSubview(_toolbar)

        // Setup constraints for toolbar with SafeArea
        _toolbar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            _toolbar.topAnchor.constraint(equalTo: _containerView.safeAreaLayoutGuide.topAnchor),
            _toolbar.leadingAnchor.constraint(equalTo: _containerView.leadingAnchor),
            _toolbar.trailingAnchor.constraint(equalTo: _containerView.trailingAnchor),
            _toolbar.bottomAnchor.constraint(equalTo: _containerView.bottomAnchor)
        ])

        // iOS 26+ Liquid Glass appearance with blur effect
        if #available(iOS 13.0, *) {
            let appearance = UIToolbarAppearance()

            // Use transparent background with blur (Liquid Glass effect)
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)

            // Apply system material blur effect for iOS 26+
            if #available(iOS 26.0, *) {
                appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
            } else {
                // Fallback for older iOS versions
                appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
            }

            _toolbar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                _toolbar.scrollEdgeAppearance = appearance
                _toolbar.compactAppearance = appearance
            }
        }

        // Enable blur and translucency
        _toolbar.isTranslucent = true

        // Parse arguments
        if let params = args as? [String: Any] {
            configureToolbar(params)
        }

        // Setup method channel
        _channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handleMethodCall(call, result: result)
        }
    }

    func view() -> UIView {
        return _containerView
    }

    private func configureToolbar(_ params: [String: Any]) {
        // Update cached state with new values
        if params.keys.contains("title") {
            if let title = params["title"] as? String {
                _currentTitle = title.isEmpty ? nil : title
            }
        }

        // Handle leading - check for clearLeading flag
        if params.keys.contains("clearLeading") {
            _currentLeading = nil
        } else if params.keys.contains("leading") {
            if let leading = params["leading"] as? String {
                // Keep empty string for back button, only set nil if truly absent
                _currentLeading = leading
            }
        }

        if params.keys.contains("actions") {
            if let actions = params["actions"] as? [[String: Any]] {
                _currentActions = actions.isEmpty ? nil : actions
            }
        }

        // Rebuild toolbar with current state
        var items: [UIBarButtonItem] = []

        // Leading button (if exists)
        if let leadingTitle = _currentLeading, !leadingTitle.isEmpty {
            let leadingButton = UIBarButtonItem(
                title: leadingTitle,
                style: .plain,
                target: self,
                action: #selector(leadingTapped)
            )
            items.append(leadingButton)
        } else if _currentLeading != nil && _currentLeading!.isEmpty {
            // Empty string = show back chevron icon
            let leadingButton = UIBarButtonItem(
                image: UIImage(systemName: "chevron.left"),
                style: .plain,
                target: self,
                action: #selector(leadingTapped)
            )
            items.append(leadingButton)
        }

        // Flexible space before title
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))

        // Title (center) - always add if exists
        if let title = _currentTitle, !title.isEmpty {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            titleLabel.textAlignment = .center
            titleLabel.sizeToFit()

            let titleItem = UIBarButtonItem(customView: titleLabel)
            items.append(titleItem)
        }

        // Flexible space after title
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))

        // Trailing buttons (actions)
        if let actions = _currentActions {
            for (index, action) in actions.enumerated() {
                if let actionTitle = action["title"] as? String {
                    let actionButton = UIBarButtonItem(
                        title: actionTitle,
                        style: .plain,
                        target: self,
                        action: #selector(actionTapped(_:))
                    )
                    actionButton.tag = index
                    items.append(actionButton)
                } else if let actionIcon = action["icon"] as? String {
                    let iconButton = UIBarButtonItem(
                        image: UIImage(systemName: actionIcon),
                        style: .plain,
                        target: self,
                        action: #selector(actionTapped(_:))
                    )
                    iconButton.tag = index
                    items.append(iconButton)
                }
            }
        }

        _toolbar.items = items
    }

    @objc private func leadingTapped() {
        _channel.invokeMethod("onLeadingTapped", arguments: nil)
    }

    @objc private func actionTapped(_ sender: UIBarButtonItem) {
        // Use the tag to get the action index
        let actionIndex = sender.tag
        _channel.invokeMethod("onActionTapped", arguments: ["index": actionIndex])
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateToolbar":
            if let params = call.arguments as? [String: Any] {
                configureToolbar(params)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
