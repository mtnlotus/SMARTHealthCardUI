// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SMARTHealthCardUI",
	platforms: [
		.macOS(.v15),
		.iOS(.v17),
	],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SMARTHealthCardUI",
            targets: ["SMARTHealthCardUI"]
        ),
    ],
	dependencies: [
		.package(url: "https://github.com/apple/FHIRModels.git", "0.7.0"..<"1.0.0"),
//		.package(url: "https://github.com/mtnlotus/SMARTHealthCard.git", branch: "main"),
		.package(name: "SMARTHealthCard", path: "../SMARTHealthCard"),
		.package(url: "https://github.com/twostraws/CodeScanner.git", "2.5.2"..<"3.0.0"),
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SMARTHealthCardUI",
			dependencies: [
				.product(name: "ModelsR4", package: "FHIRModels"),
				.product(name: "SMARTHealthCard", package: "SMARTHealthCard"),
				.product(name: "CodeScanner", package: "CodeScanner"),
			],
			resources: [.process("BundleResources")]
		),
        .testTarget(
            name: "SMARTHealthCardUITests",
            dependencies: ["SMARTHealthCardUI"],
			resources: [.copy("TestData")]
        ),
    ]
)
