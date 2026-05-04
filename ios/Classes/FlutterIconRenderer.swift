import Flutter
import UIKit
import CoreText

/// Utility class to render Flutter IconData as native UIImages
class FlutterIconRenderer {
    // Cache mapping Flutter family names to actual iOS PostScript names
    private static var registeredFontPostScriptNames: [String: String] = [:]

    /// Renders a Flutter IconData character into a UIImage
    static func imageFromIconData(codePoint: Int, fontFamily: String, size: CGFloat, color: UIColor = .black) -> UIImage? {
        let text = String(UnicodeScalar(codePoint) ?? UnicodeScalar(0)) as NSString
        let font = getIconFont(familyName: fontFamily, size: size)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let textSize = text.size(withAttributes: attributes)
        if textSize.width == 0 || textSize.height == 0 { return nil }
        
        UIGraphicsBeginImageContextWithOptions(textSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        text.draw(at: .zero, withAttributes: attributes)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private static func getIconFont(familyName: String, size: CGFloat) -> UIFont {
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

    private static func loadAndRegisterFlutterFont(familyName: String) -> String? {
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
}
