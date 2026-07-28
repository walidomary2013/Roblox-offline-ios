import Foundation
import UIKit

/// Native Swift Port of Novetus Core Engine for iOS
/// Manages Roblox place loading, client versions, and game runtime states natively.

@objc public enum NovetusClientVersion: Int {
    case client2007March = 0
    case client2008August = 1
    case client2011May = 2
    case client2017Late = 3
}

@objc public class NovetusCore: NSObject {
    @objc public static let shared = NovetusCore()

    @objc public var selectedVersion: NovetusClientVersion = .client2017Late
    @objc public var activePlacePath: String = ""

    private override init() {
        super.init()
        print("[NovetusCore-iOS] Native Swift Novetus Core Engine Initialized.")
    }

    @objc public func loadRobloxPlace(path: String, version: NovetusClientVersion) -> Bool {
        self.activePlacePath = path
        self.selectedVersion = version

        print("[NovetusCore-iOS] Loading Place File: \(path)")
        print("[NovetusCore-iOS] Engine Version: \(version.rawValue)")

        // Invoke Objective-C++ C++ Engine Bridge
        let bridge = NovetusEngineBridge()
        return bridge.loadPlaceFile(path)
    }
}
