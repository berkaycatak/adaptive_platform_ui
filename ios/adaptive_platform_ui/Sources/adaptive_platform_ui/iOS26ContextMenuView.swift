import Flutter
import UIKit

class iOS26ContextMenuView: NSObject, FlutterPlatformView, UIContextMenuInteractionDelegate {
    private let channel: FlutterMethodChannel
    private let container: UIView
    private let preview = UIImageView()
    private var labels: [String] = []
    private var symbols: [String] = []
    private var enabled: [Bool] = []
    private var isDestructive: [Bool] = []

    init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        self.channel = FlutterMethodChannel(name: "adaptive_platform_ui/ios26_context_menu_\(viewId)", binaryMessenger: messenger)
        self.container = UIView(frame: frame)

        var isDark = false
        if let dict = args as? [String: Any] {
            if let v = dict["isDark"] as? NSNumber { isDark = v.boolValue }
            labels = (dict["labels"] as? [String]) ?? []
            symbols = (dict["sfSymbols"] as? [String]) ?? []
            enabled = ((dict["enabled"] as? [NSNumber]) ?? []).map { $0.boolValue }
            isDestructive = ((dict["isDestructive"] as? [NSNumber]) ?? []).map { $0.boolValue }
        }

        super.init()

        container.backgroundColor = .clear
        container.overrideUserInterfaceStyle = isDark ? .dark : .light
        container.addInteraction(UIContextMenuInteraction(delegate: self))

        preview.frame = container.bounds
        preview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        preview.contentMode = .scaleToFill
        preview.isHidden = true
        container.addSubview(preview)

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { result(nil); return }
            switch call.method {
            case "setPreview":
                if let args = call.arguments as? [String: Any], let data = args["image"] as? FlutterStandardTypedData {
                    self.preview.image = UIImage(data: data.data, scale: UIScreen.main.scale)
                    result(nil)
                } else { result(FlutterError(code: "bad_args", message: "Missing image", details: nil)) }
            case "setBrightness":
                if let args = call.arguments as? [String: Any], let isDark = (args["isDark"] as? NSNumber)?.boolValue {
                    self.container.overrideUserInterfaceStyle = isDark ? .dark : .light
                    result(nil)
                } else { result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil)) }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func view() -> UIView { container }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        preview.isHidden = preview.image == nil
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }
            let actions: [UIAction] = self.labels.indices.map { i in
                let name = i < self.symbols.count ? self.symbols[i] : ""
                let image = name.isEmpty ? nil : (UIImage(systemName: name) ?? UIImage(named: name))
                var attrs: UIMenuElement.Attributes = []
                if i < self.enabled.count, !self.enabled[i] { attrs.insert(.disabled) }
                if i < self.isDestructive.count, self.isDestructive[i] { attrs.insert(.destructive) }
                return UIAction(title: self.labels[i], image: image, attributes: attrs) { [weak self] _ in
                    self?.channel.invokeMethod("itemSelected", arguments: ["index": i])
                }
            }
            return UIMenu(title: "", children: actions)
        }
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        targetedPreview()
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        targetedPreview()
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        guard let animator = animator else { preview.isHidden = true; return }
        animator.addCompletion { [weak self] in self?.preview.isHidden = true }
    }

    private func targetedPreview() -> UITargetedPreview? {
        if preview.isHidden { return nil }
        // Clear platter so rounded Flutter children do not get a white box behind them.
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        return UITargetedPreview(view: preview, parameters: params)
    }
}

/// Factory for creating iOS26ContextMenuView instances
class iOS26ContextMenuViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return iOS26ContextMenuView(frame: frame, viewId: viewId, args: args, messenger: messenger)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
