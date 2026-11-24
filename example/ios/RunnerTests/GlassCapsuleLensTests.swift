import Flutter
import UIKit
import XCTest

@testable import adaptive_platform_ui

/// A messenger that drops everything: the capsule only needs one to build its
/// channel.
private final class SilentMessenger: NSObject, FlutterBinaryMessenger {
    func send(onChannel channel: String, message: Data?) {}

    func send(
        onChannel channel: String, message: Data?,
        binaryReply callback: FlutterBinaryReply? = nil
    ) {}

    func setMessageHandlerOnChannel(
        _ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler? = nil
    ) -> FlutterBinaryMessengerConnection { 0 }

    func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {}
}

@available(iOS 26.0, *)
final class GlassCapsuleLensTests: XCTestCase {
    private var window: UIWindow!
    private var capsule: iOS26GlassCapsuleView!

    override func setUp() {
        super.setUp()
        let frame = CGRect(x: 0, y: 0, width: 64, height: 320)
        capsule = iOS26GlassCapsuleView(
            frame: frame,
            viewIdentifier: 1,
            arguments: [
                "items": (0..<5).map { ["symbol": "circle", "label": "Tab \($0)"] },
                "selectedIndex": 1,
                "showLabels": true,
            ],
            binaryMessenger: SilentMessenger()
        )
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 400))
        window.addSubview(capsule.view())
        window.isHidden = false
        capsule.view().layoutIfNeeded()
    }

    override func tearDown() {
        window.isHidden = true
        window = nil
        capsule = nil
        super.tearDown()
    }

    func testCapsuleAndLensShareOneGlassContainer() {
        let container = capsule.glassContainerView
        XCTAssertTrue(container.effect is UIGlassContainerEffect)
        XCTAssertTrue(capsule.lensView.superview === container.contentView)
        let capsuleGlass = container.contentView.subviews.compactMap { $0 as? UIVisualEffectView }
            .first { $0 !== capsule.lensView }
        XCTAssertTrue(capsuleGlass?.effect is UIGlassEffect)
        // The lens is drawn over the capsule, so it refracts the tabs.
        let order = container.contentView.subviews
        XCTAssertGreaterThan(
            order.firstIndex(of: capsule.lensView)!, order.firstIndex(of: capsuleGlass!)!)
    }

    func testLensIsNotThereAtRest() {
        XCTAssertNil(capsule.lensView.effect)
        XCTAssertTrue(capsule.lensView.isHidden)
    }

    func testLensMaterializesAsInteractiveGlassAndFollowsTheFinger() {
        capsule.beginLensDrag()

        let glass = capsule.lensView.effect as? UIGlassEffect
        XCTAssertNotNil(glass)
        XCTAssertEqual(glass?.isInteractive, true)
        XCTAssertFalse(capsule.lensView.isHidden)
        // Wider than the capsule: it lifts off it, as on the tab bar.
        XCTAssertGreaterThan(capsule.lensView.bounds.width, capsule.view().bounds.width)

        let target = capsule.tabCenterY(at: 3)
        capsule.moveLensDrag(toY: target)
        XCTAssertEqual(capsule.lensView.center.y, target, accuracy: 0.5)
    }

    func testHighlightStaysUnderTheLensSoItShowsOnAPlainBackground() {
        capsule.beginLensDrag()
        let target = capsule.tabCenterY(at: 3)
        capsule.moveLensDrag(toY: target)
        XCTAssertEqual(capsule.selectionHighlight.alpha, 1)
        XCTAssertFalse(capsule.selectionHighlight.isHidden)
        XCTAssertEqual(capsule.selectionHighlight.center.y, target, accuracy: 0.5)
    }

    func testLensDoesNotLeaveTheTabs() {
        capsule.beginLensDrag()
        capsule.moveLensDrag(toY: 10_000)
        XCTAssertEqual(capsule.lensView.center.y, capsule.tabCenterY(at: 4), accuracy: 0.5)
        capsule.moveLensDrag(toY: -10_000)
        XCTAssertEqual(capsule.lensView.center.y, capsule.tabCenterY(at: 0), accuracy: 0.5)
    }

    func testLensDissolvesWhenLetGo() {
        capsule.beginLensDrag()
        capsule.moveLensDrag(toY: capsule.tabCenterY(at: 3))
        capsule.endLensDrag(committed: true)
        XCTAssertNil(capsule.lensView.effect)
    }
}
