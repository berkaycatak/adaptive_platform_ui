import Flutter
import UIKit
import XCTest
@testable import adaptive_platform_ui

@available(iOS 26.0, *)
@MainActor
class RunnerTests: XCTestCase {
    private let channelName = "adaptive_platform_ui/ios26_tab_bar_42"

    private func makeView(_ messenger: RecordingMessenger) -> iOS26TabBarPlatformView {
        iOS26TabBarPlatformView(
            frame: CGRect(x: 0, y: 700, width: 390, height: 83),
            viewId: 42,
            args: [
                "labels": ["Home", "Trade", "Wallet"],
                "sfSymbols": ["house", "arrow.left.arrow.right", "wallet.bifold"],
                "selectedIndex": 1, "isDark": false,
                "tint": 0xFF0A95F0, "minimizeBehavior": 0,
            ],
            messenger: messenger
        )
    }

    private func mount(_ view: UIView) -> (UIWindow, UIViewController, UITabBarController) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let parent = UIViewController()
        window.rootViewController = parent
        window.isHidden = false
        parent.view.addSubview(view)
        window.layoutIfNeeded()
        let controller = parent.children.compactMap { $0 as? UITabBarController }.first!
        return (window, parent, controller)
    }

    private func send(_ messenger: RecordingMessenger, _ method: String, _ args: [String: Any]) -> Any? {
        messenger.receive(channelName, method: method, arguments: args)
    }

    func testControllerAttachesReattachesAndDisposesWithoutLeakingIntoFlutterParent() {
        let messenger = RecordingMessenger()
        var platformView: iOS26TabBarPlatformView? = makeView(messenger)
        let host = platformView!.view()
        let (window, parent, controller) = mount(host)
        defer { window.isHidden = true }
        XCTAssertTrue(controller.view.superview === host)
        XCTAssertEqual(controller.viewControllers?.count, 3)
        XCTAssertEqual(controller.selectedIndex, 1)
        XCTAssertEqual(controller.view.backgroundColor, .clear)
        XCTAssertEqual(controller.selectedViewController?.view.backgroundColor, .clear)

        host.removeFromSuperview()
        XCTAssertNil(controller.parent)
        XCTAssertNil(controller.view.superview)
        XCTAssertTrue(parent.children.isEmpty)

        parent.view.addSubview(host)
        XCTAssertTrue(controller.parent === parent)
        XCTAssertEqual(parent.children.count, 1)
        XCTAssertEqual(controller.selectedIndex, 1)

        platformView = nil
        XCTAssertNil(controller.parent)
        XCTAssertNil(controller.view.superview)
        XCTAssertTrue(parent.children.isEmpty)
        XCTAssertNil(messenger.handlers[channelName])
    }

    func testItemAndSelectionUpdatesPreserveControllerAndDoNotEchoProgrammaticChanges() {
        let messenger = RecordingMessenger()
        let platformView = makeView(messenger)
        let (window, _, controller) = mount(platformView.view())
        defer { window.isHidden = true }
        let children = controller.viewControllers!
        _ = send(messenger, "setSelectedIndex", ["index": 2])
        XCTAssertEqual(controller.selectedIndex, 2)
        _ = send(messenger, "setSelectedIndex", ["index": -1])
        _ = send(messenger, "setSelectedIndex", ["index": 99])
        XCTAssertEqual(controller.selectedIndex, 2)

        _ = send(messenger, "setItems", [
            "labels": ["Read", "Trade", "Wallet"],
            "sfSymbols": ["book", "arrow.left.arrow.right", "wallet.bifold"],
            "selectedIndex": 2, "badgeCounts": [0, 3, 120],
        ])
        XCTAssertTrue(controller.viewControllers![0] === children[0])
        XCTAssertEqual(controller.selectedIndex, 2)
        XCTAssertEqual(controller.tabBar.items?.first?.title, "Read")
        XCTAssertEqual(controller.tabBar.items?[2].badgeValue, "99+")
        XCTAssertNotNil(controller.tabBar.items?.first?.image)

        _ = send(messenger, "setStyle", ["tint": 0xFF0A95F0, "unselectedItemTint": 0xFF777777])
        XCTAssertEqual(controller.selectedIndex, 2)
        XCTAssertTrue(controller.viewControllers![2] === children[2])
        XCTAssertEqual(controller.tabBar.items?[2].badgeValue, "99+")
        _ = send(messenger, "setBadgeCounts", ["badgeCounts": [2, 0, 0]])
        XCTAssertEqual(controller.tabBar.items?[0].badgeValue, "2")
        XCTAssertNil(controller.tabBar.items?[2].badgeValue)
        XCTAssertTrue(messenger.outgoing.isEmpty)

        // UIKit reports taps (including reselects) through this delegate; each
        // must reach Flutter exactly once without programmatic selection echo.
        for _ in 0..<2 {
            controller.delegate?.tabBarController?(controller, didSelect: children[2])
        }
        XCTAssertEqual(messenger.outgoing.count, 2)
        XCTAssertEqual(messenger.outgoing.last?.method, "valueChanged")
        XCTAssertEqual((messenger.outgoing.last?.arguments as? [String: Int])?["index"], 2)

        _ = send(messenger, "setItems", ["labels": ["Only"], "sfSymbols": ["house"], "selectedIndex": 0])
        XCTAssertEqual(controller.viewControllers?.count, 1)
        XCTAssertEqual(controller.selectedIndex, 0)
        _ = send(messenger, "setItems", ["labels": [String](), "sfSymbols": [String]()])
        XCTAssertEqual(controller.viewControllers?.count, 0)
    }

    func testTraitsVisibilityAndResizeReachControllerWithoutReplacingTabs() {
        let messenger = RecordingMessenger()
        let platformView = makeView(messenger)
        let host = platformView.view()
        let (window, _, controller) = mount(host)
        defer { window.isHidden = true }
        let child = controller.selectedViewController
        XCTAssertEqual(controller.overrideUserInterfaceStyle, .light)
        XCTAssertEqual(controller.tabBarMinimizeBehavior, .never)
        _ = send(messenger, "setBrightness", ["isDark": true])
        XCTAssertEqual(controller.overrideUserInterfaceStyle, .dark)
        _ = send(messenger, "setDirectionality", ["isRtl": true])
        XCTAssertEqual(controller.view.semanticContentAttribute, .forceRightToLeft)
        XCTAssertEqual(controller.tabBar.semanticContentAttribute, .forceRightToLeft)
        _ = send(messenger, "setMinimizeBehavior", ["behavior": 1])
        XCTAssertEqual(controller.tabBarMinimizeBehavior, .onScrollDown)
        _ = send(messenger, "setHidden", ["hidden": true])
        XCTAssertTrue(host.isHidden)
        XCTAssertNotNil(controller.parent)
        _ = send(messenger, "setHidden", ["hidden": false])
        XCTAssertFalse(host.isHidden)

        host.frame.size.width = 320
        host.layoutIfNeeded()
        XCTAssertEqual(controller.view.bounds.width, 320, accuracy: 0.5)
        XCTAssertTrue(controller.selectedViewController === child)
        XCTAssertEqual(controller.selectedIndex, 1)
        let size = send(messenger, "getIntrinsicSize", [:]) as? [String: Double]
        XCTAssertGreaterThan(size?["height"] ?? 0, 0)
        XCTAssertLessThan(size?["height"] ?? .infinity, 150)
    }
}

private final class RecordingMessenger: NSObject, FlutterBinaryMessenger {
    var handlers: [String: FlutterBinaryMessageHandler] = [:]
    var outgoing: [FlutterMethodCall] = []
    private let codec = FlutterStandardMethodCodec.sharedInstance()

    func send(onChannel channel: String, message: Data?) {
        if let message = message { outgoing.append(codec.decodeMethodCall(message)) }
    }

    func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) {
        send(onChannel: channel, message: message)
        callback?(codec.encodeSuccessEnvelope(nil))
    }

    func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler?) -> FlutterBinaryMessengerConnection {
        handlers[channel] = handler
        return 1
    }

    func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {
        handlers.removeAll()
    }

    func receive(_ channel: String, method: String, arguments: Any?) -> Any? {
        var response: Any?
        let call = codec.encode(FlutterMethodCall(methodName: method, arguments: arguments))
        handlers[channel]?(call) { data in
            if let data = data { response = self.codec.decodeEnvelope(data) }
        }
        return response
    }
}
