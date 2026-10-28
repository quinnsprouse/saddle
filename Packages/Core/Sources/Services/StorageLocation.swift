public import Foundation

public enum StorageLocation {
    public static let overrideVariable = "APP_DATA_DIRECTORY"

    public static func directory(environment: [String: String]) -> URL {
        if let override = environment[overrideVariable], !override.isEmpty {
            return URL(filePath: override, directoryHint: .isDirectory)
        }
        return URL.applicationSupportDirectory
    }
}
