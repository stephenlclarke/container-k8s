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

import Foundation
@testable import K8sCore
import XCTest

final class K8sBuildInfoTests: XCTestCase {
    override func tearDown() {
        unsetenv("CONTAINER_K8S_BUILD_INFO")
        unsetenv("CONTAINER_K8S_GIT")
        super.tearDown()
    }

    func testDefaultInitializerValues() {
        let info = K8sBuildInfo()

        XCTAssertEqual(info.version, "0.1.0")
        XCTAssertEqual(info.source, "unspecified")
        XCTAssertEqual(info.branch, "unspecified")
        XCTAssertEqual(info.lane, "unspecified")
        XCTAssertEqual(info.commit, "unspecified")
        XCTAssertEqual(info.buildType, K8sBuildInfo.defaultBuildType)
        XCTAssertEqual(info.containerRef, "unspecified")
    }

    func testLoadReadsBuildInfoFromEnvironmentFile() throws {
        let expected = K8sBuildInfo(
            version: "9.9.9",
            source: "example/container-k8s",
            branch: "release/example",
            lane: "release",
            commit: "abc123",
            buildType: "release",
            containerRef: "container-ref"
        )
        let path = try writeBuildInfo(expected)
        setenv("CONTAINER_K8S_BUILD_INFO", path.path, 1)

        XCTAssertEqual(K8sBuildInfo.load(), expected)
    }

    func testLoadFallsBackToLocalInfoWhenConfiguredFileCannotDecode() {
        setenv("CONTAINER_K8S_BUILD_INFO", "/tmp/container-k8s-missing-build-info.json", 1)
        setenv("CONTAINER_K8S_GIT", "/tmp/container-k8s-missing-git", 1)

        let info = K8sBuildInfo.load()

        XCTAssertEqual(info.version, "0.1.0")
        XCTAssertEqual(info.source, "unspecified")
        XCTAssertEqual(info.branch, "unspecified")
        XCTAssertEqual(info.lane, "development")
        XCTAssertEqual(info.commit, "unspecified")
    }

    func testBranchLaneClassification() {
        XCTAssertEqual(K8sBuildInfo.lane(for: "main"), "main")
        XCTAssertEqual(K8sBuildInfo.lane(for: "release/v0.1.0"), "release")
        XCTAssertEqual(K8sBuildInfo.lane(for: "snapshot/bootstrap"), "snapshot")
        XCTAssertEqual(K8sBuildInfo.lane(for: "feature/kubeconfig"), "development")
        XCTAssertEqual(K8sBuildInfo.lane(for: "HEAD"), "detached")
        XCTAssertEqual(K8sBuildInfo.lane(for: ""), "detached")
    }

    private func writeBuildInfo(_ info: K8sBuildInfo) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appendingPathComponent("build-info.json")
        let data = try JSONEncoder().encode(info)
        try data.write(to: path)
        return path
    }
}
