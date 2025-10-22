import Flutter
import UIKit

class iOS26TabBarPlatformView: NSObject, FlutterPlatformView, UITabBarDelegate {
    private let channel: FlutterMethodChannel
    private let container: UIView
    private var tabBar: UITabBar?
    private var minimizeBehavior: Int = 3 // automatic
    private var currentLabels: [String] = []
    private var currentSymbols: [String] = []
    private var currentSearchFlags: [Bool] = []
    private var currentBadgeCounts: [Int?] = []

    init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        self.channel = FlutterMethodChannel(
            name: "adaptive_platform_ui/ios26_tab_bar_\(viewId)",
            binaryMessenger: messenger
        )
        self.container = UIView(frame: frame)

        var labels: [String] = []
        var symbols: [String] = []
        var searchFlags: [Bool] = []
        var badgeCounts: [Int?] = []
        var spacerFlags: [Bool] = []
        var selectedIndex: Int = 0
        var isDark: Bool = false
        var tint: UIColor? = nil
        var bg: UIColor? = nil
        var minimize: Int = 3 // automatic

        if let dict = args as? [String: Any] {
            labels = (dict["labels"] as? [String]) ?? []
            symbols = (dict["sfSymbols"] as? [String]) ?? []
            searchFlags = (dict["searchFlags"] as? [Bool]) ?? []
            spacerFlags = (dict["spacerFlags"] as? [Bool]) ?? []
            if let badgeData = dict["badgeCounts"] as? [NSNumber?] {
                badgeCounts = badgeData.map { $0?.intValue }
            }
            if let v = dict["selectedIndex"] as? NSNumber { selectedIndex = v.intValue }
            if let v = dict["isDark"] as? NSNumber { isDark = v.boolValue }
            if let n = dict["tint"] as? NSNumber { tint = Self.colorFromARGB(n.intValue) }
            if let n = dict["backgroundColor"] as? NSNumber { bg = Self.colorFromARGB(n.intValue) }
            if let m = dict["minimizeBehavior"] as? NSNumber { minimize = m.intValue }
        }

        super.init()

        container.backgroundColor = .clear
        if #available(iOS 13.0, *) {
            container.overrideUserInterfaceStyle = isDark ? .dark : .light
        }

        // iOS 26+ appearance configuration - completely transparent for Flutter blur
        let appearance: UITabBarAppearance? = {
            if #available(iOS 13.0, *) {
                let ap = UITabBarAppearance()

                // Completely transparent - Flutter handles blur
                ap.configureWithTransparentBackground()
                ap.backgroundColor = .clear
                ap.backgroundImage = nil
                ap.shadowColor = .clear
                ap.shadowImage = nil

                // Remove all effects
                if #available(iOS 26.0, *) {
                    ap.backgroundEffect = nil
                }

                return ap
            }
            return nil
        }()

        // Create single tab bar
        let bar = UITabBar(frame: .zero)
        tabBar = bar
        bar.delegate = self
        bar.translatesAutoresizingMaskIntoConstraints = false

        if let bg = bg { bar.barTintColor = bg }
        if #available(iOS 10.0, *), let tint = tint { bar.tintColor = tint }
        if let ap = appearance {
            if #available(iOS 13.0, *) {
                bar.standardAppearance = ap
                if #available(iOS 15.0, *) {
                    bar.scrollEdgeAppearance = ap
                }
            }
        }

        // Build tab bar items
        func buildItems(_ range: Range<Int>) -> [UITabBarItem] {
            var items: [UITabBarItem] = []
            for i in range {
                let title = (i < labels.count) ? labels[i] : nil
                let isSearch = (i < searchFlags.count) && searchFlags[i]
                let badgeCount = (i < badgeCounts.count) ? badgeCounts[i] : nil

                let item: UITabBarItem

                // Use UITabBarSystemItem.search for search tabs (iOS 26+ Liquid Glass)
                if isSearch {
                    if #available(iOS 26.0, *) {
                        item = UITabBarItem(tabBarSystemItem: .search, tag: i)
                        if let title = title {
                            item.title = title
                        }
                    } else {
                        // Fallback for older iOS versions
                        let searchImage = UIImage(systemName: "magnifyingglass")
                        item = UITabBarItem(title: title, image: searchImage, selectedImage: searchImage)
                    }
                } else {
                    var image: UIImage? = nil
                    if i < symbols.count && !symbols[i].isEmpty {
                        image = UIImage(systemName: symbols[i])
                    }
                    // Create item with title
                    item = UITabBarItem(title: title ?? "Tab \(i+1)", image: image, selectedImage: image)
                    item.tag = i
                }

                // Set badge value if provided
                if let count = badgeCount, count > 0 {
                    item.badgeValue = count > 99 ? "99+" : String(count)
                } else {
                    item.badgeValue = nil
                }

                items.append(item)
            }
            return items
        }

        let count = max(labels.count, symbols.count)
        bar.items = buildItems(0..<count)

        // Note: spacerFlags are received but not yet implemented for UITabBar
        // UITabBar doesn't natively support flexible spacing between items like UIToolbar does
        // This would require custom UITabBar subclass or different approach
        // TODO: Implement grouped tab bar layout if needed

        if selectedIndex >= 0, let items = bar.items, selectedIndex < items.count {
            bar.selectedItem = items[selectedIndex]
        }

        container.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bar.topAnchor.constraint(equalTo: container.topAnchor),
            bar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        self.minimizeBehavior = minimize
        self.currentLabels = labels
        self.currentSymbols = symbols
        self.currentSearchFlags = searchFlags
        self.currentBadgeCounts = badgeCounts

        // Apply minimize behavior if available
        self.applyMinimizeBehavior()

        // Setup method call handler
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { result(nil); return }
            self.handleMethodCall(call, result: result)
        }
    }

    private func applyMinimizeBehavior() {
        // Note: UITabBarController.tabBarMinimizeBehavior is the official iOS 26+ API
        // However, since we're using a standalone UITabBar in a platform view,
        // we need to implement custom minimize behavior
        //
        // The minimize behavior should be controlled at the Flutter level
        // by adjusting the tab bar's height/visibility based on scroll events
        //
        // This method stores the behavior preference for future use
        // The actual minimization animation should be handled by Flutter
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getIntrinsicSize":
            if let bar = self.tabBar {
                let size = bar.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                result(["width": Double(size.width), "height": Double(size.height)])
            } else {
                result(["width": Double(self.container.bounds.width), "height": 50.0])
            }

        case "setItems":
            guard let args = call.arguments as? [String: Any],
                  let labels = args["labels"] as? [String],
                  let symbols = args["sfSymbols"] as? [String] else {
                result(FlutterError(code: "bad_args", message: "Missing items", details: nil))
                return
            }

            let searchFlags = (args["searchFlags"] as? [Bool]) ?? []
            let selectedIndex = (args["selectedIndex"] as? NSNumber)?.intValue ?? 0
            var badgeCounts: [Int?] = []
            if let badgeData = args["badgeCounts"] as? [NSNumber?] {
                badgeCounts = badgeData.map { $0?.intValue }
            }
            
            self.currentLabels = labels
            self.currentSymbols = symbols
            self.currentSearchFlags = searchFlags
            self.currentBadgeCounts = badgeCounts

            let count = max(labels.count, symbols.count)
            func buildItems(_ range: Range<Int>) -> [UITabBarItem] {
                var items: [UITabBarItem] = []
                for i in range {
                    let title = (i < labels.count) ? labels[i] : nil
                    let isSearch = (i < searchFlags.count) && searchFlags[i]
                    let badgeCount = (i < badgeCounts.count) ? badgeCounts[i] : nil

                    let item: UITabBarItem

                    // Use UITabBarSystemItem.search for search tabs (iOS 26+ Liquid Glass)
                    if isSearch {
                        if #available(iOS 26.0, *) {
                            item = UITabBarItem(tabBarSystemItem: .search, tag: i)
                            if let title = title {
                                item.title = title
                            }
                        } else {
                            // Fallback for older iOS versions
                            let searchImage = UIImage(systemName: "magnifyingglass")
                            item = UITabBarItem(title: title, image: searchImage, selectedImage: searchImage)
                        }
                    } else {
                        var image: UIImage? = nil
                        if i < symbols.count && !symbols[i].isEmpty {
                            image = UIImage(systemName: symbols[i])
                        }
                        // Create item with title
                        item = UITabBarItem(title: title ?? "Tab \(i+1)", image: image, selectedImage: image)
                        item.tag = i
                    }

                    // Set badge value if provided
                    if let count = badgeCount, count > 0 {
                        item.badgeValue = count > 99 ? "99+" : String(count)
                    } else {
                        item.badgeValue = nil
                    }

                    items.append(item)
                }
                return items
            }

            if let bar = self.tabBar {
                bar.items = buildItems(0..<count)
                if let items = bar.items, selectedIndex >= 0, selectedIndex < items.count {
                    bar.selectedItem = items[selectedIndex]
                }
            }
            result(nil)

        case "setSelectedIndex":
            guard let args = call.arguments as? [String: Any],
                  let idx = (args["index"] as? NSNumber)?.intValue else {
                result(FlutterError(code: "bad_args", message: "Invalid index", details: nil))
                return
            }

            if let bar = self.tabBar, let items = bar.items, idx >= 0, idx < items.count {
                bar.selectedItem = items[idx]
            }
            result(nil)

        case "setStyle":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "bad_args", message: "Missing style", details: nil))
                return
            }

            if let n = args["tint"] as? NSNumber {
                let c = Self.colorFromARGB(n.intValue)
                self.tabBar?.tintColor = c
            }
            if let n = args["backgroundColor"] as? NSNumber {
                let c = Self.colorFromARGB(n.intValue)
                self.tabBar?.barTintColor = c
            }
            result(nil)

        case "setBrightness":
            guard let args = call.arguments as? [String: Any],
                  let isDark = (args["isDark"] as? NSNumber)?.boolValue else {
                result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil))
                return
            }

            if #available(iOS 13.0, *) {
                self.container.overrideUserInterfaceStyle = isDark ? .dark : .light
            }
            result(nil)

        case "setMinimizeBehavior":
            guard let args = call.arguments as? [String: Any],
                  let behavior = (args["behavior"] as? NSNumber)?.intValue else {
                result(FlutterError(code: "bad_args", message: "Missing behavior", details: nil))
                return
            }

            self.minimizeBehavior = behavior
            self.applyMinimizeBehavior()
            result(nil)

        case "setBadgeCounts":
            guard let args = call.arguments as? [String: Any],
                  let badgeData = args["badgeCounts"] as? [NSNumber?] else {
                result(FlutterError(code: "bad_args", message: "Missing badge counts", details: nil))
                return
            }

            let badgeCounts = badgeData.map { $0?.intValue }
            self.currentBadgeCounts = badgeCounts

            // Update existing tab bar items with new badge values
            if let bar = self.tabBar, let items = bar.items {
                for (index, item) in items.enumerated() {
                    if index < badgeCounts.count {
                        let count = badgeCounts[index]
                        if let count = count, count > 0 {
                            item.badgeValue = count > 99 ? "99+" : String(count)
                        } else {
                            item.badgeValue = nil
                        }
                    }
                }
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func view() -> UIView { container }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let bar = self.tabBar, bar === tabBar, let items = bar.items, let idx = items.firstIndex(of: item) {
            channel.invokeMethod("valueChanged", arguments: ["index": idx])
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

class iOS26TabBarViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return iOS26TabBarPlatformView(
            frame: frame,
            viewId: viewId,
            args: args,
            messenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
