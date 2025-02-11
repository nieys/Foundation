// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "PMKFoundation",
    dependencies: [
        .Package(url: "https://github.com/mxcl/PromiseKit.git", majorVersion: 8)
    ],
    swiftLanguageVersions: [3, 4, 5],
    exclude: [
        "Sources/NSNotificationCenter+AnyPromise.m",
        "Sources/NSTask+AnyPromise.m",
        "Sources/NSURLSession+AnyPromise.m",
        "Sources/PMKFoundation.h",
		"Tests"  // currently SwiftPM is not savvy to having a single test…
    ]
)

#if os(Linux)
package.exclude += [
    "Sources/afterlife.swift",
    "Sources/NSObject+Promise.swift"
]
#endif
