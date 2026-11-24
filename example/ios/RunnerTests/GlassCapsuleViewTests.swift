import Flutter
import UIKit
import UIKit.UIGestureRecognizerSubclass
import XCTest

@testable import adaptive_platform_ui

/// A messenger that keeps the capsule's handler and the calls it makes, so a
/// test can talk to the capsule as Dart does.
private final class RecordingMessenger: NSObject, FlutterBinaryMessenger {
    var handlers: [String: FlutterBinaryMessageHandler] = [:]
    var calls: [FlutterMethodCall] = []

    func send(onChannel channel: String, message: Data?) {
        record(message)
    }

    func send(
        onChannel channel: String, message: Data?,
        binaryReply callback: FlutterBinaryReply? = nil
    ) {
        record(message)
    }

    func setMessageHandlerOnChannel(
        _ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler? = nil
    ) -> FlutterBinaryMessengerConnection {
        handlers[channel] = handler
        return 0
    }

    func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {}

    private func record(_ message: Data?) {
        guard let message = message else { return }
        calls.append(FlutterStandardMethodCodec.sharedInstance().decodeMethodCall(message))
    }

    /// Sends [method] to the capsule and returns its raw reply: nil when the
    /// method is not implemented, an encoded envelope otherwise.
    @discardableResult
    func invoke(_ method: String, _ arguments: Any?, on channel: String) -> Data? {
        let codec = FlutterStandardMethodCodec.sharedInstance()
        var reply: Data?
        handlers[channel]?(codec.encode(FlutterMethodCall(methodName: method, arguments: arguments))) {
            reply = $0
        }
        return reply
    }
}

/// A pan whose state and location a test sets.
private final class ScriptedPan: UIPanGestureRecognizer {
    var point: CGPoint = .zero
    // UIKit ignores a state set outside of touch handling, so keep our own.
    private var scriptedState: UIGestureRecognizer.State = .possible

    override var state: UIGestureRecognizer.State {
        get { scriptedState }
        set { scriptedState = newValue }
    }

    override func location(in view: UIView?) -> CGPoint { point }
}

@available(iOS 26.0, *)
final class GlassCapsuleViewTests: XCTestCase {
    private static let channel = "adaptive_platform_ui/ios26_glass_capsule_7"

    private var window: UIWindow!
    private var messenger: RecordingMessenger!
    private var capsule: iOS26GlassCapsuleView!

    private func makeCapsule(_ arguments: [String: Any]) {
        messenger = RecordingMessenger()
        capsule = iOS26GlassCapsuleView(
            frame: CGRect(x: 0, y: 0, width: 64, height: 320),
            viewIdentifier: 7,
            arguments: arguments,
            binaryMessenger: messenger
        )
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 400))
        window.addSubview(capsule.view())
        window.isHidden = false
        capsule.view().layoutIfNeeded()
    }

    private static func tabs(_ count: Int) -> [[String: Any]] {
        (0..<count).map { ["symbol": "circle", "selectedSymbol": "circle.fill", "label": "Tab \($0)"] }
    }

    private var buttons: [UIButton] {
        func collect(_ view: UIView) -> [UIButton] {
            (view as? UIButton).map { [$0] } ?? view.subviews.flatMap(collect)
        }
        return collect(capsule.view()).sorted { $0.tag < $1.tag }
    }

    private var labels: [String] {
        capsule.view().subviews.compactMap { ($0 as? UILabel)?.text }
    }

    private static func png(_ color: UIColor) -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 40, height: 30)).pngData { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 30))
        }
    }

    override func tearDown() {
        window?.isHidden = true
        window = nil
        capsule = nil
        messenger = nil
        super.tearDown()
    }

    func testUpdateFromDartAppliesTheNewParameters() {
        makeCapsule(["items": Self.tabs(5), "selectedIndex": 1, "showLabels": true])

        let reply = messenger.invoke(
            "update",
            ["selectedIndex": 3, "isDark": true, "tint": 0xFF34C759, "inset": 8],
            on: Self.channel)
        capsule.view().layoutIfNeeded()

        XCTAssertNil(reply.map { FlutterStandardMethodCodec.sharedInstance().decodeEnvelope($0) } ?? nil)
        XCTAssertNotNil(reply)
        XCTAssertEqual(capsule.view().overrideUserInterfaceStyle, .dark)
        XCTAssertEqual(
            capsule.selectionHighlight.center.y, capsule.tabCenterY(at: 3), accuracy: 0.5)
        XCTAssertNotNil(buttons[3].configuration?.attributedTitle)
    }

    func testAnUnknownMethodIsNotImplemented() {
        makeCapsule(["items": Self.tabs(2)])
        XCTAssertNil(messenger.invoke("explode", nil, on: Self.channel))
    }

    func testTappingATabReportsIt() {
        makeCapsule(["items": Self.tabs(5), "selectedIndex": 0])
        buttons[2].sendActions(for: .touchUpInside)
        XCTAssertEqual(messenger.calls.last?.method, "onItemTapped")
        XCTAssertEqual((messenger.calls.last?.arguments as? [String: Any])?["index"] as? Int, 2)
    }

    func testBadgesAndTheOverflowMenu() {
        makeCapsule([
            "items": [
                ["symbol": "bell", "badge": 4, "tint": 0xFFFF3B30],
                ["symbol": "tray", "badge": 120],
                ["title": "Editar"],
                [
                    "symbol": "ellipsis",
                    "menu": [
                        ["id": 1, "title": "Compartir", "symbol": "square.and.arrow.up"],
                        ["id": 2, "title": "Ayuda"],
                    ],
                ],
            ],
        ])

        XCTAssertEqual(Set(labels), ["4", "99+"])
        let overflow = buttons[3]
        XCTAssertTrue(overflow.showsMenuAsPrimaryAction)
        XCTAssertEqual(overflow.menu?.children.count, 2)
        XCTAssertNotNil(buttons[2].configuration?.attributedTitle)

        // The same items again keep the buttons; new ones rebuild them.
        let first = buttons[0]
        messenger.invoke("update", ["items": [["symbol": "bell", "badge": 4, "tint": 0xFFFF3B30], ["symbol": "tray", "badge": 120], ["title": "Editar"], ["symbol": "ellipsis", "menu": [["id": 1, "title": "Compartir", "symbol": "square.and.arrow.up"], ["id": 2, "title": "Ayuda"]]]]], on: Self.channel)
        XCTAssertTrue(buttons[0] === first)
        messenger.invoke("update", ["items": [["symbol": "bell"]]], on: Self.channel)
        XCTAssertEqual(buttons.count, 1)
        XCTAssertTrue(labels.isEmpty)
    }

    func testPicturesFromBytesAFileAndTheNetwork() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("capsule-avatar.png")
        try Self.png(.systemGreen).write(to: file)
        let network = FileManager.default.temporaryDirectory.appendingPathComponent("capsule-net.png")
        try Self.png(.systemPurple).write(to: network)
        let bytes = FlutterStandardTypedData(bytes: Self.png(.systemOrange))

        let items: [[String: Any]] = [
            ["image": bytes],
            ["file": file.path],
            ["network": network.absoluteString],
            ["asset": "assets/missing.png", "title": "Sin foto"],
        ]
        makeCapsule(["items": items])

        XCTAssertNotNil(buttons[0].configuration?.image)
        XCTAssertNotNil(buttons[1].configuration?.image)
        // A placeholder until the download arrives.
        XCTAssertEqual(buttons[2].configuration?.image, UIImage(systemName: "person.crop.circle"))
        XCTAssertNil(buttons[3].configuration?.image)

        let arrived = expectation(description: "network picture")
        func check() {
            if buttons[2].configuration?.image != UIImage(systemName: "person.crop.circle") {
                arrived.fulfill()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: check)
            }
        }
        check()
        wait(for: [arrived], timeout: 5)

        // Cached: the same bytes and URL again are not decoded or fetched.
        messenger.invoke("update", ["items": items, "selectedIndex": 0], on: Self.channel)
        XCTAssertNotNil(buttons[0].configuration?.image)
        XCTAssertNotEqual(buttons[2].configuration?.image, UIImage(systemName: "person.crop.circle"))
    }

    func testDraggingTheLensWithTheGesture() {
        makeCapsule(["items": Self.tabs(5), "selectedIndex": 1, "showLabels": true])
        let lensPan = capsule.view().subviews.lazy
            .compactMap { $0 as? UIVisualEffectView }
            .flatMap { $0.contentView.subviews.compactMap { $0 as? UIVisualEffectView } }
            .flatMap { $0.contentView.gestureRecognizers ?? [] }
            .first { $0 is UIPanGestureRecognizer }
        XCTAssertNotNil(lensPan)
        // Only taken from the selected tab.
        XCTAssertFalse(capsule.gestureRecognizerShouldBegin(lensPan!))
        XCTAssertFalse(capsule.gestureRecognizerShouldBegin(ScriptedPan()))

        let pan = ScriptedPan()
        let drag = NSSelectorFromString("lensDragged:")
        // A pan that has not begun does nothing.
        capsule.perform(drag, with: pan)
        XCTAssertTrue(capsule.lensView.isHidden)
        pan.state = .began
        capsule.perform(drag, with: pan)
        pan.point = CGPoint(x: 32, y: capsule.tabCenterY(at: 4))
        pan.state = .changed
        capsule.perform(drag, with: pan)
        pan.state = .ended
        capsule.perform(drag, with: pan)

        XCTAssertEqual(messenger.calls.last?.method, "onItemTapped")
        XCTAssertEqual((messenger.calls.last?.arguments as? [String: Any])?["index"] as? Int, 4)

        // Dart did not select it (it opened something else): the highlight
        // goes back to the selected tab.
        RunLoop.main.run(until: Date().addingTimeInterval(0.6))
        capsule.view().layoutIfNeeded()
        XCTAssertEqual(
            capsule.selectionHighlight.center.y, capsule.tabCenterY(at: 1), accuracy: 0.5)
    }

    func testACancelledDragSelectsNothing() {
        makeCapsule(["items": Self.tabs(5), "selectedIndex": 1])
        capsule.beginLensDrag()
        capsule.moveLensDrag(toY: capsule.tabCenterY(at: 3))
        capsule.endLensDrag(committed: false)
        XCTAssertFalse(messenger.calls.contains { $0.method == "onItemTapped" })
    }

    // MARK: Growing while the lens is held (iPhone Duo)

    private var lensDragCalls: [Bool] {
        messenger.calls
            .filter { $0.method == "onLensDrag" }
            .compactMap { ($0.arguments as? [String: Any])?["active"] as? Bool }
    }

    func testHoldingTheLensTellsDartAndShowsTheLabels() {
        makeCapsule(["items": Self.tabs(5), "selectedIndex": 1, "expandOnLensDrag": true])
        XCTAssertTrue(buttons.allSatisfy { $0.configuration?.attributedTitle == nil })

        capsule.beginLensDrag()
        XCTAssertEqual(lensDragCalls, [true])
        XCTAssertTrue(buttons.allSatisfy { $0.configuration?.attributedTitle != nil })

        capsule.endLensDrag(committed: false)
        XCTAssertEqual(lensDragCalls, [true, false])
        XCTAssertTrue(buttons.allSatisfy { $0.configuration?.attributedTitle == nil })
    }

    func testLettingGoOnAnotherTabReportsTheTabLast() {
        makeCapsule(["items": Self.tabs(5), "selectedIndex": 1, "expandOnLensDrag": true])
        capsule.beginLensDrag()
        capsule.moveLensDrag(toY: capsule.tabCenterY(at: 3))
        capsule.endLensDrag(committed: true)

        XCTAssertEqual(lensDragCalls, [true, false])
        XCTAssertEqual(messenger.calls.last?.method, "onItemTapped")
    }

    func testWithoutExpandOnLensDragNothingChanges() {
        makeCapsule(["items": Self.tabs(5), "selectedIndex": 1])
        capsule.beginLensDrag()
        XCTAssertTrue(lensDragCalls.isEmpty)
        XCTAssertTrue(buttons.allSatisfy { $0.configuration?.attributedTitle == nil })
        capsule.endLensDrag(committed: false)
        XCTAssertTrue(lensDragCalls.isEmpty)
    }

    func testAnUpdateWhileTheLensIsHeldKeepsItWhereItIs() {
        makeCapsule(["items": Self.tabs(5), "selectedIndex": 1, "expandOnLensDrag": true])
        capsule.beginLensDrag()
        capsule.moveLensDrag(toY: capsule.tabCenterY(at: 3))

        messenger.invoke("update", ["items": Self.tabs(5), "selectedIndex": 1], on: Self.channel)
        capsule.view().layoutIfNeeded()

        XCTAssertEqual(
            capsule.selectionHighlight.center.y, capsule.tabCenterY(at: 3), accuracy: 0.5)
        // Still showing the labels: the lens is still held.
        XCTAssertTrue(buttons.allSatisfy { $0.configuration?.attributedTitle != nil })
    }

    func testLensAndHighlightFollowTheCapsuleAsItGrows() {
        makeCapsule(["items": Self.tabs(5), "selectedIndex": 1, "expandOnLensDrag": true])
        capsule.beginLensDrag()
        capsule.moveLensDrag(toY: capsule.tabCenterY(at: 3))

        // Flutter gives the view the larger frame, around the same place.
        capsule.view().frame = CGRect(x: -4, y: -15, width: 72, height: 350)
        capsule.view().layoutIfNeeded()

        let width = capsule.view().bounds.width
        XCTAssertEqual(capsule.selectionHighlight.bounds.width, width - 6, accuracy: 0.5)
        XCTAssertEqual(capsule.selectionHighlight.center.x, width / 2, accuracy: 0.5)
        XCTAssertGreaterThan(capsule.lensView.bounds.width, width)
        XCTAssertEqual(capsule.lensView.center.x, width / 2, accuracy: 0.5)
        // Over the same tab, which moved as the capsule grew.
        XCTAssertEqual(
            capsule.selectionHighlight.center.y, capsule.tabCenterY(at: 3), accuracy: 0.5)
        XCTAssertEqual(capsule.lensView.center.y, capsule.tabCenterY(at: 3), accuracy: 0.5)
    }

    func testTheHighlightStaysOnTheTabLetGoOverWhileTheCapsuleShrinks() {
        makeCapsule(["items": Self.tabs(5), "selectedIndex": 1, "expandOnLensDrag": true])
        capsule.view().frame = CGRect(x: -4, y: -15, width: 72, height: 350)
        capsule.view().layoutIfNeeded()
        capsule.beginLensDrag()
        capsule.moveLensDrag(toY: capsule.tabCenterY(at: 3))
        capsule.endLensDrag(committed: true)

        // Flutter takes the view back to its size before Dart selects tab 3.
        capsule.view().frame = CGRect(x: 0, y: 0, width: 64, height: 320)
        capsule.view().layoutIfNeeded()
        XCTAssertEqual(
            capsule.selectionHighlight.center.y, capsule.tabCenterY(at: 3), accuracy: 0.5)

        messenger.invoke("update", ["items": Self.tabs(5), "selectedIndex": 3], on: Self.channel)
        capsule.view().layoutIfNeeded()
        XCTAssertEqual(
            capsule.selectionHighlight.center.y, capsule.tabCenterY(at: 3), accuracy: 0.5)
    }
}
