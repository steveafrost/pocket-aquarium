import WidgetKit
import SwiftUI

/// WidgetBundle entry point.
/// NOTE: This must be in a separate Widget Extension target in Xcode.
/// When included in the main app target, remove @main to avoid conflict.
struct FishWidgetBundle: WidgetBundle {
    var body: some Widget {
        FishWidget()
    }
}
