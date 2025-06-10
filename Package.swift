// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


let local = false

let pykit_package: Package.Dependency = if local {
    .package(path: "/Volumes/CodeSSD/PythonSwiftGithub/PySwiftKit")
} else {
    .package(url: "https://github.com/py-swift/PySwiftKit", from: .init(311, 0, 0))
}


let pykit: Target.Dependency =  .product(name: "SwiftonizeModules", package: "PySwiftKit")


let package = Package(
    name: "PythonLauncher",
    platforms: [
        .iOS(.v13), .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PythonLauncher",
            targets: ["PythonLauncher"]),
    ],
    dependencies: [
        pykit_package,
        .package(url: "https://github.com/kylef/PathKit", .upToNextMajor(from: "1.0.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PythonLauncher",
            dependencies: [
                pykit,
                "PathKit"
            ]
        ),

    ]
)
