import Foundation
import PolicyKit

let root = FileManager.default.currentDirectoryPath + "/"

func repositoryPath(_ path: String) -> String {
    var relative = path.hasPrefix(root) ? String(path.dropFirst(root.count)) : path
    while relative.hasPrefix("./") {
        relative.removeFirst(2)
    }
    return relative
}

var configurationPath = "policy.json"
var files: [String] = []
var arguments = CommandLine.arguments.dropFirst()
while let argument = arguments.popFirst() {
    guard argument == "--config" else {
        files.append(repositoryPath(argument))
        continue
    }
    guard let value = arguments.popFirst() else {
        print("policy: --config needs a path to policy.json")
        exit(2)
    }
    configurationPath = value
}

do {
    let configuration = try Configuration.load(from: URL(filePath: configurationPath))
    var violations: [Violation] = []
    for path in files {
        let source = try String(contentsOfFile: path, encoding: .utf8)
        violations += Policy.check(source: source, path: path, configuration: configuration)
    }
    for violation in violations {
        print(violation)
    }
    guard violations.isEmpty else {
        print("policy: \(violations.count) violations in \(Set(violations.map(\.path)).count) files")
        exit(1)
    }
    print("policy: \(files.count) files clean")
} catch {
    print("policy: \(error)")
    exit(2)
}
