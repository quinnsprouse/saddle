import ProjectDescription

public enum BuildSettings {
    public static let strict: SettingsDictionary = [
        "SWIFT_VERSION": "6.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES",
        "GCC_TREAT_WARNINGS_AS_ERRORS": "YES",
        "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
        "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
        "SWIFT_STRICT_MEMORY_SAFETY": "YES",
        "SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY": "YES",
        "SWIFT_UPCOMING_FEATURE_INTERNAL_IMPORTS_BY_DEFAULT": "YES",
        "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
        "OTHER_SWIFT_FLAGS": [
            "$(inherited)",
            "-Xfrontend", "-warn-long-function-bodies=150",
            "-Xfrontend", "-warn-long-expression-type-checking=150",
        ],
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
        "DEAD_CODE_STRIPPING": "YES",
        "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
        "SWIFT_EMIT_LOC_STRINGS": "YES",
        "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
        "CODE_SIGN_STYLE": "Automatic",
    ]

    public static let testing: SettingsDictionary = [
        "SWIFT_DEFAULT_ACTOR_ISOLATION": "nonisolated"
    ]

    public static let project: Settings = .settings(
        base: strict,
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release", settings: ["SWIFT_COMPILATION_MODE": "wholemodule"]),
        ]
    )
}
