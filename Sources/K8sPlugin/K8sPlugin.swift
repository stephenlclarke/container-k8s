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

import ArgumentParser
import Foundation
import K8sCore

private let pluginBuildInfo = K8sBuildInfo.load()
private let pluginVersionString = "container-k8s \(pluginBuildInfo.version)"

@main
struct K8sPlugin: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "k8s",
        abstract: "Manage local Kubernetes clusters on Apple's container runtime",
        version: pluginVersionString,
        subcommands: [
            Version.self,
            Run.self,
            Create.self,
            Delete.self,
            List.self,
            LoadImage.self,
            WriteConfig.self,
            GetKubeconfig.self,
        ]
    )
}

struct Version: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Show container-k8s build information"
    )

    @Flag(name: .long, help: "Print only the version number.")
    var short = false

    @Option(name: [.customShort("f"), .long], help: "Output format: pretty or json.")
    var format: VersionFormat = .pretty

    func run() throws {
        let info = K8sBuildInfo.load()
        if short {
            print(info.version)
            return
        }
        switch format {
        case .pretty:
            print("container-k8s \(info.version)")
            print("source: \(info.source)")
            print("branch: \(info.branch)")
            print("lane: \(info.lane)")
            print("commit: \(info.commit)")
            print("build: \(info.buildType)")
            print("container ref: \(info.containerRef)")
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(info)
            print(String(decoding: data, as: UTF8.self))
        }
    }
}

enum VersionFormat: String, ExpressibleByArgument {
    case pretty
    case json
}

struct Run: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Create and start a single-node Kubernetes cluster"
    )

    @Argument(help: "Cluster name.")
    var cluster: String

    @Option(help: "Number of CPUs to allocate to the node.")
    var cpus: Int?

    @Option(help: "Memory to allocate to the node, such as 4G.")
    var memory: String?

    @Flag(help: "Print the planned operation without running it.")
    var dryRun = false

    func run() throws {
        try handlePlannedCommand(
            PlannedCommand(
                name: "run",
                summary: "create and start a single-node k3s cluster",
                cluster: cluster,
                arguments: [cpus.map { "cpus=\($0)" }, memory.map { "memory=\($0)" }].compactMap { $0 }
            ),
            dryRun: dryRun
        )
    }
}

struct Create: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a Kubernetes cluster without starting it"
    )

    @Argument(help: "Cluster name.")
    var cluster: String

    @Flag(help: "Print the planned operation without running it.")
    var dryRun = false

    func run() throws {
        try handlePlannedCommand(
            PlannedCommand(name: "create", summary: "create a stopped single-node k3s cluster", cluster: cluster),
            dryRun: dryRun
        )
    }
}

struct Delete: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a Kubernetes cluster and generated kubeconfig entries"
    )

    @Argument(help: "Cluster name.")
    var cluster: String

    @Flag(help: "Delete even if the cluster is running.")
    var force = false

    @Flag(help: "Print the planned operation without running it.")
    var dryRun = false

    func run() throws {
        try handlePlannedCommand(
            PlannedCommand(
                name: "delete",
                summary: "remove cluster containers and generated kubeconfig entries",
                cluster: cluster,
                arguments: force ? ["force=true"] : []
            ),
            dryRun: dryRun
        )
    }
}

struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List Kubernetes clusters managed by this plugin",
        aliases: ["ls"]
    )

    @Flag(help: "Print the planned operation without running it.")
    var dryRun = false

    func run() throws {
        try handlePlannedCommand(
            PlannedCommand(name: "list", summary: "discover containers with plugin=k8s labels"),
            dryRun: dryRun
        )
    }
}

struct LoadImage: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "load-image",
        abstract: "Load a local container image into a cluster node image store"
    )

    @Argument(help: "Cluster name.")
    var cluster: String

    @Argument(help: "Image reference to load.")
    var image: String

    @Flag(help: "Print the planned operation without running it.")
    var dryRun = false

    func run() throws {
        try handlePlannedCommand(
            PlannedCommand(
                name: "load-image",
                summary: "save an OCI archive from container image storage and import it with ctr",
                cluster: cluster,
                arguments: ["image=\(image)"]
            ),
            dryRun: dryRun
        )
    }
}

struct WriteConfig: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "write-config",
        abstract: "Merge a generated cluster kubeconfig into the user kubeconfig"
    )

    @Argument(help: "Cluster name.")
    var cluster: String

    @Flag(help: "Print the planned operation without running it.")
    var dryRun = false

    func run() throws {
        try handlePlannedCommand(
            PlannedCommand(name: "write-config", summary: "merge generated kubeconfig and set current context", cluster: cluster),
            dryRun: dryRun
        )
    }
}

struct GetKubeconfig: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get-kubeconfig",
        abstract: "Print the generated kubeconfig for a cluster"
    )

    @Argument(help: "Cluster name.")
    var cluster: String

    @Flag(help: "Print the planned operation without running it.")
    var dryRun = false

    func run() throws {
        try handlePlannedCommand(
            PlannedCommand(name: "get-kubeconfig", summary: "print generated kubeconfig to stdout", cluster: cluster),
            dryRun: dryRun
        )
    }
}

private func handlePlannedCommand(_ command: PlannedCommand, dryRun: Bool) throws {
    if dryRun {
        print(command.dryRunDescription)
        return
    }
    throw ValidationError("\(command.name) is tracked in PLAN.md and is not implemented in this bootstrap release; use --dry-run to inspect the planned operation")
}
