import Foundation

extension Bundle {
    static nonisolated let clipMiniResources: Bundle = {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("ClipMini_ClipMini.bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return Bundle.module
    }()
}
