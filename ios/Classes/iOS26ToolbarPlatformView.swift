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
                } else if let iconCodePoint = action["iconCodePoint"] as? Int {
                    let fontFamily = action["iconFontFamily"] as? String ?? ""
                    let image = imageFromIconData(codePoint: iconCodePoint, fontFamily: fontFamily)
                    button = UIBarButtonItem(
                        image: image?.withRenderingMode(.alwaysTemplate),
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

    // Cache mapping Flutter family names to actual iOS PostScript names
    private var registeredFontPostScriptNames: [String: String] = [:]

    private func getFont(familyName: String, size: CGFloat) -> UIFont {
        // 1. If we already dynamically registered it, use the PostScript name
        if let postScriptName = registeredFontPostScriptNames[familyName],
           let font = UIFont(name: postScriptName, size: size) {
            return font
        }
        
        // 2. Try to dynamically load and register the font from Flutter's FontManifest.json
        if let postScriptName = loadAndRegisterFlutterFont(familyName: familyName),
           let font = UIFont(name: postScriptName, size: size) {
            return font
        }
        
        // 3. Try directly (in case it's a system font or already in Info.plist)
        if let font = UIFont(name: familyName, size: size) {
            return font
        }
        
        // 4. Try common fallbacks
        if familyName == "MaterialIcons" {
            if let font = UIFont(name: "MaterialIcons-Regular", size: size) {
                return font
            }
        }
        if familyName.hasSuffix("CupertinoIcons") {
            if let font = UIFont(name: "CupertinoIcons", size: size) {
                return font
            }
        }
        
        // 5. Robust search through all available fonts
        let baseFamilyName = familyName.components(separatedBy: "/").last ?? familyName
        let cleanBase = baseFamilyName.replacingOccurrences(of: " ", with: "").lowercased()
        
        let allFamilies = UIFont.familyNames
        for family in allFamilies {
            let cleanFamily = family.replacingOccurrences(of: " ", with: "").lowercased()
            if cleanFamily.contains(cleanBase) || cleanBase.contains(cleanFamily) {
                let fonts = UIFont.fontNames(forFamilyName: family)
                if let firstFont = fonts.first, let font = UIFont(name: firstFont, size: size) {
                    return font
                }
            }
        }
        
        for family in allFamilies {
            for fontName in UIFont.fontNames(forFamilyName: family) {
                let cleanFont = fontName.replacingOccurrences(of: " ", with: "").lowercased()
                if cleanFont.contains(cleanBase) {
                    if let font = UIFont(name: fontName, size: size) {
                        return font
                    }
                }
            }
        }

        return UIFont.systemFont(ofSize: size)
    }

    private func loadAndRegisterFlutterFont(familyName: String) -> String? {
        let bundle = Bundle.main
        let manifestKey = FlutterDartProject.lookupKey(forAsset: "FontManifest.json")
        guard let manifestPath = bundle.path(forResource: manifestKey, ofType: nil) ??
                                 bundle.path(forResource: "Frameworks/App.framework/flutter_assets/FontManifest.json", ofType: nil),
              let data = try? Data(contentsOf: URL(fileURLWithPath: manifestPath)),
              let manifest = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
            return nil
        }

        var fontAssetPath: String?
        for entry in manifest {
            if let family = entry["family"] as? String {
                if family == familyName || family.hasSuffix(familyName) {
                    if let fonts = entry["fonts"] as? [[String: Any]],
                       let firstFont = fonts.first,
                       let asset = firstFont["asset"] as? String {
                        fontAssetPath = asset
                        break
                    }
                }
            }
        }

        guard let asset = fontAssetPath else { return nil }

        let fontKey = FlutterDartProject.lookupKey(forAsset: asset)
        guard let fontPath = bundle.path(forResource: fontKey, ofType: nil) else { return nil }

        guard let dataProvider = CGDataProvider(url: URL(fileURLWithPath: fontPath) as CFURL),
              let cgFont = CGFont(dataProvider) else { return nil }

        var error: Unmanaged<CFError>?
        CTFontManagerRegisterGraphicsFont(cgFont, &error)

        if let postScriptName = cgFont.postScriptName as String? {
            registeredFontPostScriptNames[familyName] = postScriptName
            return postScriptName
        }

        return nil
    }

    private func imageFromIconData(codePoint: Int, fontFamily: String) -> UIImage? {
        let text = String(UnicodeScalar(codePoint) ?? UnicodeScalar(0)) as NSString
        let font = getFont(familyName: fontFamily, size: 24)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        let size = text.size(withAttributes: attributes)
        if size.width == 0 || size.height == 0 { return nil }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        text.draw(at: .zero, withAttributes: attributes)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
