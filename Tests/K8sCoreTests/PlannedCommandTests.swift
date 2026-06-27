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

import K8sCore
import XCTest

final class PlannedCommandTests: XCTestCase {
    func testDryRunDescriptionIncludesCommandClusterAndArguments() {
        let command = PlannedCommand(
            name: "run",
            summary: "create and start a single-node k3s cluster",
            cluster: "demo",
            arguments: ["cpus=4", "memory=8G"]
        )

        XCTAssertEqual(
            command.dryRunDescription,
            "planned: create and start a single-node k3s cluster (command=run cluster=demo arguments=cpus=4,memory=8G)"
        )
    }

    func testDryRunDescriptionOmitsOptionalFieldsWhenAbsent() {
        let command = PlannedCommand(name: "list", summary: "discover clusters")

        XCTAssertEqual(
            command.dryRunDescription,
            "planned: discover clusters (command=list)"
        )
    }

    func testCommandsCompareByValue() {
        XCTAssertEqual(
            PlannedCommand(name: "delete", summary: "remove cluster", cluster: "demo", arguments: ["force=true"]),
            PlannedCommand(name: "delete", summary: "remove cluster", cluster: "demo", arguments: ["force=true"])
        )
    }
}
