import Foundation

enum AppResources {
    private static func requiredModuleResource(_ name: String, suffix: String) -> URL {
        guard let url = Bundle.module.url(forResource: name, withExtension: suffix) else {
            fatalError("Required bundled resource missing: \(name).\(suffix)")
        }
        return url
    }

    static func url(_ name: String, extension suffix: String) -> URL {
        Bundle.main.url(forResource: name, withExtension: suffix)
            ?? requiredModuleResource(name, suffix: suffix)
    }
}
