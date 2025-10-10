import Flutter
import UIKit

/// Factory for creating iOS 26 native segmented control platform views
class iOS26SegmentedControlViewFactory: NSObject, FlutterPlatformViewFactory {
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
        return iOS26SegmentedControlView(
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

/// Native iOS 26 segmented control implementation
class iOS26SegmentedControlView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var segmentedControl: UISegmentedControl!
    private var channel: FlutterMethodChannel
    private var controlId: Int
    private var isDark: Bool = false

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView(frame: frame)

        if let config = args as? [String: Any] {
            controlId = config["id"] as? Int ?? 0
            isDark = config["isDark"] as? Bool ?? false
        } else {
            controlId = 0
        }

        channel = FlutterMethodChannel(
            name: "adaptive_platform_ui/ios26_segmented_control_\(controlId)",
            binaryMessenger: messenger
        )

        super.init()

        createNativeSegmentedControl(with: args)

        channel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call, result: result)
        }
    }

    func view() -> UIView {
        return _view
    }

    private func createNativeSegmentedControl(with args: Any?) {
        segmentedControl = UISegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.isUserInteractionEnabled = true
        _view.isUserInteractionEnabled = true

        if let config = args as? [String: Any] {
            if let segments = config["segments"] as? [[String: Any]] {
                for (index, segment) in segments.enumerated() {
                    if let value = segment["value"] as? String {
                        segmentedControl.insertSegment(withTitle: value, at: index, animated: false)
                    }
                }
            }

            if let selectedIndex = config["selectedIndex"] as? Int, selectedIndex >= 0 {
                segmentedControl.selectedSegmentIndex = selectedIndex
            }
        }

        _view.addSubview(segmentedControl)
        NSLayoutConstraint.activate([
            segmentedControl.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            segmentedControl.topAnchor.constraint(equalTo: _view.topAnchor),
            segmentedControl.bottomAnchor.constraint(equalTo: _view.bottomAnchor),
        ])

        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }

    @objc private func segmentChanged() {
        channel.invokeMethod("valueChanged", arguments: ["index": segmentedControl.selectedSegmentIndex])

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setSelectedIndex":
            if let args = call.arguments as? [String: Any],
               let index = args["index"] as? Int {
                if index >= 0 && index < segmentedControl.numberOfSegments {
                    segmentedControl.selectedSegmentIndex = index
                } else if index == -1 {
                    segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
                }
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
