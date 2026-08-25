import Flutter
import UIKit

private final class LayoutAwareTabBarContainerView: UIView {
    var onWidthChanged: ((CGFloat) -> Void)?
    private var lastReportedWidth: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()

        guard window != nil else { return }

        let width = bounds.width
        guard width > 0 else { return }
        guard abs(width - lastReportedWidth) > 0.5 else { return }

        lastReportedWidth = width
        onWidthChanged?(width)
    }
}

class iOS26TabBarPlatformView: NSObject, FlutterPlatformView, UITabBarDelegate {
    private let channel: FlutterMethodChannel
    private let container: LayoutAwareTabBarContainerView
    private var tabBar: UITabBar?
    private var minimizeBehavior: Int = 3 // automatic
    private var currentLabels: [String] = []
    private var currentSymbols: [String] = []
    private var currentSelectedSymbols: [String] = []
    private var currentAssetIcons: [String] = []
    private var currentSelectedAssetIcons: [String] = []
    private var currentFileIcons: [String] = []
    private var currentSelectedFileIcons: [String] = []
    private var currentNetworkIcons: [String] = []
    private var currentSelectedNetworkIcons: [String] = []
    private var currentSearchFlags: [Bool] = []
    private var currentSpacerFlags: [Bool] = []
    /// The item the highlight belongs to, so a tap on a detached bubble can hand
    /// it straight back rather than leaving the bubble looking selected.
    private weak var lastTabSelection: UITabBarItem?
    private var currentBadgeCounts: [Int?] = []
    private let imageCache = NSCache<NSString, UIImage>()

    init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        self.channel = FlutterMethodChannel(
            name: "adaptive_platform_ui/ios26_tab_bar_\(viewId)",
            binaryMessenger: messenger
        )
        self.container = LayoutAwareTabBarContainerView(frame: frame)

        var labels: [String] = []
        var symbols: [String] = []
        var selectedSymbols: [String] = []
        var assetIcons: [String] = []
        var selectedAssetIcons: [String] = []
        var fileIcons: [String] = []
        var selectedFileIcons: [String] = []
        var networkIcons: [String] = []
        var selectedNetworkIcons: [String] = []
        var searchFlags: [Bool] = []
        var badgeCounts: [Int?] = []
        var spacerFlags: [Bool] = []
        var selectedIndex: Int = 0
        var isDark: Bool = false
        var isRtl: Bool = false
        var tint: UIColor? = nil
        var bg: UIColor? = nil
        var minimize: Int = 3 // automatic

        var unselectedTint: UIColor? = nil

        if let dict = args as? [String: Any] {
            NSLog("📦 TabBar init dict keys: \(dict.keys)")
            labels = (dict["labels"] as? [String]) ?? []
            symbols = (dict["sfSymbols"] as? [String]) ?? []
            selectedSymbols = (dict["selectedSfSymbols"] as? [String]) ?? []
            assetIcons = (dict["assetIcons"] as? [String]) ?? []
            selectedAssetIcons = (dict["selectedAssetIcons"] as? [String]) ?? []
            fileIcons = (dict["fileIcons"] as? [String]) ?? []
            selectedFileIcons = (dict["selectedFileIcons"] as? [String]) ?? []
            networkIcons = (dict["networkIcons"] as? [String]) ?? []
            selectedNetworkIcons = (dict["selectedNetworkIcons"] as? [String]) ?? []
            searchFlags = (dict["searchFlags"] as? [Bool]) ?? []
            spacerFlags = (dict["spacerFlags"] as? [Bool]) ?? []
            if let badgeData = dict["badgeCounts"] as? [NSNumber?] {
                badgeCounts = badgeData.map { $0?.intValue }
            }
            if let v = dict["selectedIndex"] as? NSNumber { selectedIndex = v.intValue }
            if let v = dict["isDark"] as? NSNumber { isDark = v.boolValue }
            if let v = dict["isRtl"] as? NSNumber { isRtl = v.boolValue }
            if let n = dict["tint"] as? NSNumber { tint = Self.colorFromARGB(n.intValue) }
            if let n = dict["unselectedItemTint"] as? NSNumber {
                unselectedTint = Self.colorFromARGB(n.intValue)
                NSLog("🎨 Parsed unselectedItemTint from dict: \(unselectedTint!)")
            }
            if let n = dict["backgroundColor"] as? NSNumber { bg = Self.colorFromARGB(n.intValue) }
            if let m = dict["minimizeBehavior"] as? NSNumber { minimize = m.intValue }
        }

        super.init()

        container.backgroundColor = .clear
        if #available(iOS 13.0, *) {
            container.overrideUserInterfaceStyle = isDark ? .dark : .light
        }


        // Create single tab bar
        let bar = UITabBar(frame: .zero)
        tabBar = bar
        bar.delegate = self
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
        container.semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight

        // iOS 26+ special handling - Skip appearance, use direct properties only
        if #available(iOS 26.0, *) {
            // For iOS 26, we skip UITabBarAppearance as it interferes with custom colors
            bar.isTranslucent = true
            bar.backgroundImage = UIImage()
            bar.shadowImage = UIImage()
            bar.backgroundColor = .clear
            NSLog("📱 iOS 26+ detected - using direct properties only")
        }
        // iOS 13-25 - Use appearance
        else if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()

            // Make transparent
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear

            // Set colors directly on the appearance layouts
            let unselColor = unselectedTint ?? UIColor.systemGray
            let selColor = tint ?? UIColor.systemBlue

            // Normal (unselected) items
            appearance.stackedLayoutAppearance.normal.iconColor = unselColor
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselColor]
            appearance.inlineLayoutAppearance.normal.iconColor = unselColor
            appearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselColor]
            appearance.compactInlineLayoutAppearance.normal.iconColor = unselColor
            appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselColor]

            // Selected items
            appearance.stackedLayoutAppearance.selected.iconColor = selColor
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selColor]
            appearance.inlineLayoutAppearance.selected.iconColor = selColor
            appearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selColor]
            appearance.compactInlineLayoutAppearance.selected.iconColor = selColor
            appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selColor]

            bar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                bar.scrollEdgeAppearance = appearance
            }

            NSLog("🎨 iOS 13-25: Applied appearance - normal: \(unselColor), selected: \(selColor)")
        } else {
            // iOS 10-12 fallback
            bar.isTranslucent = true
            bar.backgroundImage = UIImage()
            bar.shadowImage = UIImage()
            bar.backgroundColor = .clear
        }

        // Also set direct properties as fallback
        if #available(iOS 10.0, *) {
            if let unselTint = unselectedTint {
                bar.unselectedItemTintColor = unselTint
                NSLog("✅ Direct unselectedItemTintColor: \(unselTint)")
            }
            if let tint = tint {
                bar.tintColor = tint
                NSLog("✅ Direct tintColor: \(tint)")
            }
        }

        if let bg = bg { bar.barTintColor = bg }

        self.minimizeBehavior = minimize
        self.currentLabels = labels
        self.currentSymbols = symbols
        self.currentSelectedSymbols = selectedSymbols
        self.currentAssetIcons = assetIcons
        self.currentSelectedAssetIcons = selectedAssetIcons
        self.currentFileIcons = fileIcons
        self.currentSelectedFileIcons = selectedFileIcons
        self.currentNetworkIcons = networkIcons
        self.currentSelectedNetworkIcons = selectedNetworkIcons
        self.currentSearchFlags = searchFlags
        self.currentSpacerFlags = spacerFlags
        self.currentBadgeCounts = badgeCounts

        // State first: rebuildItems reads it, and configureRuntimeImages needs
        // the file/network arrays populated to resolve icons on this first pass.
        rebuildItems(selecting: selectedIndex)


        container.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bar.topAnchor.constraint(equalTo: container.topAnchor),
            bar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        // Apply minimize behavior if available
        self.applyMinimizeBehavior()

        container.onWidthChanged = { [weak self] _ in
            self?.handleContainerWidthChange()
        }

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

    private func handleContainerWidthChange() {
        guard let bar = self.tabBar else { return }

        // A standalone UITabBar hosted in a platform view can lay out once
        // before it has its final width. Rebuild against the real container
        // width so item labels and spacing are computed from the final bounds.
        if #available(iOS 26.0, *) {
            rebuildItems()
        }

        bar.setNeedsLayout()
        bar.layoutIfNeeded()
        container.setNeedsLayout()
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

            let selectedSymbols = (args["selectedSfSymbols"] as? [String]) ?? []
            let assetIcons = (args["assetIcons"] as? [String]) ?? []
            let selectedAssetIcons = (args["selectedAssetIcons"] as? [String]) ?? []
            let fileIcons = (args["fileIcons"] as? [String]) ?? []
            let selectedFileIcons = (args["selectedFileIcons"] as? [String]) ?? []
            let networkIcons = (args["networkIcons"] as? [String]) ?? []
            let selectedNetworkIcons = (args["selectedNetworkIcons"] as? [String]) ?? []
            let searchFlags = (args["searchFlags"] as? [Bool]) ?? []
            let spacerFlags = (args["spacerFlags"] as? [Bool]) ?? self.currentSpacerFlags
            let selectedIndex = (args["selectedIndex"] as? NSNumber)?.intValue ?? 0
            var badgeCounts: [Int?] = []
            if let badgeData = args["badgeCounts"] as? [NSNumber?] {
                badgeCounts = badgeData.map { $0?.intValue }
            }
            
            self.currentLabels = labels
            self.currentSymbols = symbols
            self.currentSelectedSymbols = selectedSymbols
            self.currentAssetIcons = assetIcons
            self.currentSelectedAssetIcons = selectedAssetIcons
            self.currentFileIcons = fileIcons
            self.currentSelectedFileIcons = selectedFileIcons
            self.currentNetworkIcons = networkIcons
            self.currentSelectedNetworkIcons = selectedNetworkIcons
            self.currentSearchFlags = searchFlags
            self.currentSpacerFlags = spacerFlags
            self.currentBadgeCounts = badgeCounts

            self.rebuildItems(selecting: selectedIndex)

            result(nil)

        case "setSelectedIndex":
            guard let args = call.arguments as? [String: Any],
                  let idx = (args["index"] as? NSNumber)?.intValue else {
                result(FlutterError(code: "bad_args", message: "Invalid index", details: nil))
                return
            }

            if let bar = self.tabBar, let items = bar.items, idx >= 0, idx < items.count {
                bar.selectedItem = items[idx]
                self.lastTabSelection = items[idx]
            }
            result(nil)

        case "setStyle":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "bad_args", message: "Missing style", details: nil))
                return
            }

            var tintColor: UIColor? = nil
            var unselectedColor: UIColor? = nil

            if let n = args["tint"] as? NSNumber {
                let c = Self.colorFromARGB(n.intValue)
                self.tabBar?.tintColor = c
                tintColor = c
            }
            if let n = args["unselectedItemTint"] as? NSNumber {
                let c = Self.colorFromARGB(n.intValue)
                if #available(iOS 10.0, *) {
                    self.tabBar?.unselectedItemTintColor = c
                    NSLog("✅ setStyle: unselectedItemTintColor set to \(c)")

                    // iOS 26+: Rebuild items with current state so untinted
                    // and tinted icon variants are regenerated consistently.
                    if #available(iOS 26.0, *) {
                        self.rebuildItems()
                    }
                }
                unselectedColor = c
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

        case "setDirectionality":
            guard let args = call.arguments as? [String: Any],
                  let isRtl = (args["isRtl"] as? NSNumber)?.boolValue else {
                result(FlutterError(code: "bad_args", message: "Missing isRtl", details: nil))
                return
            }

            let attribute: UISemanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            self.tabBar?.semanticContentAttribute = attribute
            self.container.semanticContentAttribute = attribute
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

        case "setHidden":
            guard let args = call.arguments as? [String: Any],
                  let hidden = (args["hidden"] as? NSNumber)?.boolValue else {
                result(FlutterError(code: "bad_args", message: "Missing hidden", details: nil))
                return
            }

            self.container.isHidden = hidden
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

    /// Index at which the trailing detached group starts, or `itemCount` when
    /// there is none.
    ///
    /// `addSpacerAfter` marks the end of the main tab group, so everything after
    /// the last flagged destination belongs beside the pill rather than in it.
    /// Only the last flag counts: iOS 26 gives us exactly one detached slot, so
    /// several spacers cannot produce several groups.
    private func detachedRangeStart(itemCount: Int) -> Int {
        guard let last = currentSpacerFlags.lastIndex(of: true) else { return itemCount }
        return min(last + 1, itemCount)
    }

    /// Builds one tab bar item from the current state.
    ///
    /// Detached items are built from `UITabBarSystemItem.search` and then have
    /// their own icon, title and badge applied over it. That system item is the
    /// only thing iOS 26 lifts out of the main tab pill and draws as a separate
    /// circular glass button, and it keeps that treatment when its content is
    /// replaced — which is what turns a plain action item into a bubble.
    private func makeItem(at i: Int, unselectedTint: UIColor?, detachedFrom: Int) -> UITabBarItem {
        let title = (i < currentLabels.count) ? currentLabels[i] : nil
        let isSearch = (i < currentSearchFlags.count) && currentSearchFlags[i]
        let isDetached = i >= detachedFrom
        let badgeCount = (i < currentBadgeCounts.count) ? currentBadgeCounts[i] : nil

        let item: UITabBarItem

        // Use UITabBarSystemItem.search for search tabs (iOS 26+ Liquid Glass)
        if isSearch {
            if #available(iOS 26.0, *) {
                item = UITabBarItem(tabBarSystemItem: .search, tag: i)
                if let title = title { item.title = title }
            } else {
                // Fallback for older iOS versions
                let searchImage = UIImage(systemName: "magnifyingglass")
                item = UITabBarItem(title: title, image: searchImage, selectedImage: searchImage)
            }
        } else {
            var image: UIImage? = nil
            var selectedImage: UIImage? = nil

            if #available(iOS 26.0, *), isDetached {
                item = UITabBarItem(tabBarSystemItem: .search, tag: i)
                if let title = title { item.title = title }
            } else {
                item = UITabBarItem(title: title ?? "Tab \(i+1)", image: nil, selectedImage: nil)
                item.tag = i
            }

            if !configureRuntimeImages(for: item, index: i) {
                if i < currentAssetIcons.count && !currentAssetIcons[i].isEmpty {
                    let key = FlutterDartProject.lookupKey(forAsset: currentAssetIcons[i])
                    let rawImageOriginal = UIImage(named: key)
                    let rawImage = rawImageOriginal != nil ? self.resizeImage(image: rawImageOriginal!) : nil

                    var selRawImage = rawImage
                    if i < currentSelectedAssetIcons.count && !currentSelectedAssetIcons[i].isEmpty {
                        let selKey = FlutterDartProject.lookupKey(forAsset: currentSelectedAssetIcons[i])
                        let selRawOriginal = UIImage(named: selKey)
                        if selRawOriginal != nil {
                            selRawImage = self.resizeImage(image: selRawOriginal!)
                        }
                    }

                    if #available(iOS 26.0, *) {
                        if let unselTint = unselectedTint {
                            image = rawImage?.withTintColor(unselTint, renderingMode: .alwaysOriginal)
                        } else {
                            image = rawImage?.withRenderingMode(.alwaysTemplate)
                        }
                        selectedImage = selRawImage?.withRenderingMode(.alwaysTemplate)
                    } else {
                        image = rawImage
                        selectedImage = selRawImage
                    }
                } else if i < currentSymbols.count && !currentSymbols[i].isEmpty {
                    // Selected state may use a distinct SF Symbol (e.g. filled variant).
                    let selSymbol = (i < currentSelectedSymbols.count && !currentSelectedSymbols[i].isEmpty)
                        ? currentSelectedSymbols[i]
                        : currentSymbols[i]
                    // iOS 26+: Use different rendering modes for selected/unselected
                    if #available(iOS 26.0, *) {
                        // Unselected: Only apply custom color if unselectedTint is provided
                        if let unselTint = unselectedTint {
                            if let originalImage = UIImage(systemName: currentSymbols[i]) ?? UIImage(named: currentSymbols[i]) {
                                image = originalImage.withTintColor(unselTint, renderingMode: .alwaysOriginal)
                            }
                        } else {
                            // No custom color - use template mode to respect theme
                            image = (UIImage(systemName: currentSymbols[i]) ?? UIImage(named: currentSymbols[i]))?.withRenderingMode(.alwaysTemplate)
                        }

                        // Selected: Use template rendering so tintColor applies
                        selectedImage = (UIImage(systemName: selSymbol) ?? UIImage(named: selSymbol))?.withRenderingMode(.alwaysTemplate)
                    } else {
                        // iOS <26: Use default behavior
                        image = UIImage(systemName: currentSymbols[i]) ?? UIImage(named: currentSymbols[i])
                        selectedImage = UIImage(systemName: selSymbol) ?? UIImage(named: selSymbol)
                    }
                }

                item.image = image
                item.selectedImage = selectedImage
            }
        }

        // Set badge value if provided
        if let count = badgeCount, count > 0 {
            item.badgeValue = count > 99 ? "99+" : String(count)
        } else {
            item.badgeValue = nil
        }

        return item
    }

    /// Rebuilds every tab item from the current state.
    ///
    /// Pass `selecting` to apply an index from Dart; omit it to keep whatever is
    /// selected now, which is what the width-change and tint-change rebuilds want.
    private func rebuildItems(selecting selectedIndex: Int? = nil) {
        guard let bar = self.tabBar else { return }

        let target = selectedIndex ?? (bar.items?.firstIndex { $0 === bar.selectedItem } ?? 0)

        let itemCount = max(
            max(currentLabels.count, currentSymbols.count),
            max(max(currentAssetIcons.count, currentFileIcons.count), currentNetworkIcons.count)
        )
        let detachedFrom = detachedRangeStart(itemCount: itemCount)
        let unselectedTint = bar.unselectedItemTintColor

        if detachedFrom < itemCount, currentSearchFlags.prefix(detachedFrom).contains(true) {
            NSLog("⚠️ adaptive_platform_ui: addSpacerAfter and isSearch are both set. iOS 26 detaches only the first search-role item, so the search tab wins and the spacer group stays inline.")
        }

        var items: [UITabBarItem] = []
        for i in 0..<itemCount {
            items.append(makeItem(at: i, unselectedTint: unselectedTint, detachedFrom: detachedFrom))
        }

        bar.items = items
        if target >= 0, target < items.count {
            bar.selectedItem = items[target]
            lastTabSelection = items[target]
        }
    }


    func view() -> UIView { container }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let bar = self.tabBar, bar === tabBar,
              let items = bar.items, let idx = items.firstIndex(of: item) else { return }

        if idx >= detachedRangeStart(itemCount: items.count) {
            // A detached item is a bubble beside the pill, not a tab. UITabBar
            // has already moved the highlight onto it by the time we get here,
            // so put it back in the same runloop turn - a frame later, via Dart,
            // is late enough to be seen as a flicker. If the app does adopt the
            // index, its setSelectedIndex lands normally right after.
            if let previous = lastTabSelection, items.contains(previous) {
                bar.selectedItem = previous
            }
        } else {
            lastTabSelection = item
        }

        channel.invokeMethod("valueChanged", arguments: ["index": idx])
    }

    private static func colorFromARGB(_ argb: Int) -> UIColor {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    private func runtimeFilePath(for index: Int, selected: Bool) -> String {
        let paths = selected ? currentSelectedFileIcons : currentFileIcons
        if index < paths.count, !paths[index].isEmpty {
            return paths[index]
        }
        if selected, index < currentFileIcons.count {
            return currentFileIcons[index]
        }
        return ""
    }

    private func runtimeNetworkURL(for index: Int, selected: Bool) -> String {
        let urls = selected ? currentSelectedNetworkIcons : currentNetworkIcons
        if index < urls.count, !urls[index].isEmpty {
            return urls[index]
        }
        if selected, index < currentNetworkIcons.count {
            return currentNetworkIcons[index]
        }
        return ""
    }

    private func hasRuntimeImage(for index: Int) -> Bool {
        return !runtimeFilePath(for: index, selected: false).isEmpty ||
            !runtimeNetworkURL(for: index, selected: false).isEmpty ||
            !runtimeFilePath(for: index, selected: true).isEmpty ||
            !runtimeNetworkURL(for: index, selected: true).isEmpty
    }

    private func placeholderAvatarImage() -> UIImage? {
        return UIImage(systemName: "person.crop.circle")
    }

    private func loadRuntimeImage(filePath: String, networkURL: String) -> UIImage? {
        if !filePath.isEmpty, let image = UIImage(contentsOfFile: filePath) {
            return avatarImage(from: image)
        }

        if !networkURL.isEmpty, let cached = imageCache.object(forKey: networkURL as NSString) {
            return avatarImage(from: cached)
        }

        return nil
    }

    private func fetchNetworkImageIfNeeded(
        urlString: String,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard !urlString.isEmpty else {
            completion(nil)
            return
        }

        if let cached = imageCache.object(forKey: urlString as NSString) {
            completion(avatarImage(from: cached))
            return
        }

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            self.imageCache.setObject(image, forKey: urlString as NSString)
            let avatar = self.avatarImage(from: image)
            DispatchQueue.main.async {
                completion(avatar)
            }
        }.resume()
    }

    private func configureRuntimeImages(for item: UITabBarItem, index: Int) -> Bool {
        guard hasRuntimeImage(for: index) else { return false }

        let unselectedFile = runtimeFilePath(for: index, selected: false)
        let selectedFile = runtimeFilePath(for: index, selected: true)
        let unselectedNetwork = runtimeNetworkURL(for: index, selected: false)
        let selectedNetwork = runtimeNetworkURL(for: index, selected: true)

        let unselectedImage = loadRuntimeImage(filePath: unselectedFile, networkURL: unselectedNetwork)
        let selectedImage = loadRuntimeImage(filePath: selectedFile, networkURL: selectedNetwork)

        item.image = (unselectedImage ?? placeholderAvatarImage())?.withRenderingMode(.alwaysOriginal)
        item.selectedImage = (selectedImage ?? unselectedImage ?? placeholderAvatarImage())?.withRenderingMode(.alwaysOriginal)

        if unselectedImage == nil && !unselectedNetwork.isEmpty {
            fetchNetworkImageIfNeeded(urlString: unselectedNetwork) { [weak item] avatar in
                guard let item = item, let avatar = avatar else { return }
                item.image = avatar.withRenderingMode(.alwaysOriginal)
                if selectedImage == nil && selectedNetwork.isEmpty && selectedFile.isEmpty {
                    item.selectedImage = avatar.withRenderingMode(.alwaysOriginal)
                }
            }
        }

        if selectedImage == nil && !selectedNetwork.isEmpty {
            fetchNetworkImageIfNeeded(urlString: selectedNetwork) { [weak item] avatar in
                guard let item = item, let avatar = avatar else { return }
                item.selectedImage = avatar.withRenderingMode(.alwaysOriginal)
            }
        }

        return true
    }

    private func resizeImage(image: UIImage, targetSize: CGSize = CGSize(width: 26, height: 26)) -> UIImage {
        let size = image.size
        if size.width <= targetSize.width && size.height <= targetSize.height {
            return image
        }
        
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        if #available(iOS 10.0, *) {
            let format = UIGraphicsImageRendererFormat()
            format.scale = UIScreen.main.scale
            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
            return renderer.image { context in
                image.draw(in: rect)
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage ?? image
        }
    }

    private func avatarImage(from image: UIImage, targetSize: CGSize = CGSize(width: 26, height: 26)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: targetSize)).addClip()

            let aspectFillScale = max(targetSize.width / image.size.width, targetSize.height / image.size.height)
            let scaledSize = CGSize(width: image.size.width * aspectFillScale, height: image.size.height * aspectFillScale)
            let origin = CGPoint(
                x: (targetSize.width - scaledSize.width) / 2.0,
                y: (targetSize.height - scaledSize.height) / 2.0
            )

            image.draw(in: CGRect(origin: origin, size: scaledSize))
        }
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
