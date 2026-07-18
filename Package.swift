// swift-tools-version: 6.2
//===----------------------------------------------------------------------===//
// Copyright 2026 container-k8s project authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//===----------------------------------------------------------------------===//

import PackageDescription

let package = Package(
    name: "container-k8s",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "k8s", targets: ["K8sPlugin"]),
        .library(name: "K8sCore", targets: ["K8sCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "K8sPlugin",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "K8sCore",
            ],
            path: "Sources/K8sPlugin"
        ),
        .target(
            name: "K8sCore",
            path: "Sources/K8sCore"
        ),
        .testTarget(
            name: "K8sCoreTests",
            dependencies: ["K8sCore"],
            path: "Tests/K8sCoreTests"
        ),
        .testTarget(
            name: "K8sPluginTests",
            dependencies: ["K8sPlugin"],
            path: "Tests/K8sPluginTests"
        ),
    ]
)
