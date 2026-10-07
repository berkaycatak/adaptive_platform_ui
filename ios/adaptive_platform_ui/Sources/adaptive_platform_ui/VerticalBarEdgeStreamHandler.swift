import Flutter
import UIKit

/// Streams where UIKit places its vertical bar for this window
/// (`UITraitCollection.verticalBarEdge`, iOS 27.1) to Dart, as a physical
/// side: "left", "right", "none", or "unsupported" before iOS 27.1.
///
/// Read through KVC so the plugin still builds against SDKs older than 27.1.
final class VerticalBarEdgeStreamHandler: NSObject, FlutterStreamHandler {
    private let registrar: FlutterPluginRegistrar
    private var sink: FlutterEventSink?
    private var observer: EdgeObserverView?
    private var lastSent: String?
    /// Bumped on every listen/cancel so retry closures from an earlier
    /// subscription stop instead of racing the current one.
    private var generation = 0

    private static let quickAttempts = 20
    private static let quickInterval: TimeInterval = 0.05
    private static let slowInterval: TimeInterval = 0.5

    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
    }

    func onListen(
        withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        generation += 1
        observer?.removeFromSuperview()
        observer = nil
        lastSent = nil
        sink = events
        attach(attempt: 0, generation: generation)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        generation += 1
        observer?.removeFromSuperview()
        observer = nil
        sink = nil
        lastSent = nil
        return nil
    }

    /// The Flutter view can still be outside a window when Dart starts
    /// listening (scene-based apps), so retry. After the quick attempts run
    /// out, report "unsupported" once so Dart can fall back, but keep polling
    /// slowly in case the view joins a window later.
    private func attach(attempt: Int, generation: Int) {
        guard generation == self.generation, sink != nil, observer == nil else { return }
        guard let host = registrar.viewController?.view, host.window != nil else {
            if attempt == Self.quickAttempts {
                send("unsupported")
            }
            let delay = attempt < Self.quickAttempts ? Self.quickInterval : Self.slowInterval
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.attach(attempt: attempt + 1, generation: generation)
            }
            return
        }
        let view = EdgeObserverView(frame: host.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.isUserInteractionEnabled = false
        view.accessibilityElementsHidden = true
        view.onChange = { [weak self] v in self?.send(Self.edge(of: v)) }
        host.insertSubview(view, at: 0)
        observer = view
        send(Self.edge(of: view))
    }

    private func send(_ edge: String) {
        guard edge != lastSent else { return }
        lastSent = edge
        sink?(edge)
    }

    static func edge(of view: UIView) -> String {
        let key = "verticalBarEdge"
        let traits = view.traitCollection
        guard traits.responds(to: NSSelectorFromString(key)),
            let raw = (traits.value(forKey: key) as? NSNumber)?.intValue
        else { return "unsupported" }
        let rtl = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        switch raw {
        case 1: return rtl ? "right" : "left"  // UIVerticalBarEdgeLeading
        case 2: return rtl ? "left" : "right"  // UIVerticalBarEdgeTrailing
        default: return "none"                 // UIVerticalBarEdgeUnspecified
        }
    }
}

/// Draws nothing and takes no touches; reports layout, trait and safe-area
/// changes of the Flutter view (pane switch, divider drag, rotation). Moving
/// between Split View panes does not change the view's size, as both panes are
/// the same width, but it does change the safe-area insets, so those are the
/// signal for pane moves.
private final class EdgeObserverView: UIView {
    var onChange: ((UIView) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onChange?(self)
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        onChange?(self)
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        onChange?(self)
    }
}
