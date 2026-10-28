import Foundation
import Services
import Testing

struct StorageLocationTests {
    @Test func theOverrideVariableRedirectsStorage() {
        let directory = StorageLocation.directory(environment: [StorageLocation.overrideVariable: "/tmp/journey"])
        #expect(directory.path(percentEncoded: false) == "/tmp/journey/")
    }

    @Test func withoutAnOverrideStorageIsApplicationSupport() {
        #expect(StorageLocation.directory(environment: [:]) == URL.applicationSupportDirectory)
    }
}
