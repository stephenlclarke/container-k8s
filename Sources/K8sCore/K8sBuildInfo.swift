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

public struct K8sBuildInfo: Codable, Equatable, Sendable {
    public var version: String
    public var source: String
    public var branch: String
    public var lane: String
    public var commit: String
    public var buildType: String
    public var containerRef: String

    public init(
        version: String = "0.1.0",
        source: String = "unspecified",
        branch: String = "unspecified",
        lane: String = "unspecified",
        commit: String = "unspecified",
        buildType: String = K8sBuildInfo.defaultBuildType,
        containerRef: String = "unspecified"
    ) {
        self.version = version
        self.source = source
        self.branch = branch
        self.lane = lane
        self.commit = commit
        self.buildType = buildType
        self.containerRef = containerRef
    }

    public static func load() -> K8sBuildInfo {
        if let path = ProcessInfo.processInfo.environment["CONTAINER_K8S_BUILD_INFO"],
           let info = decode(path: path) {
            return info
        }
        if let info = decode(path: packagedBuildInfoPath()) {
            return info
        }
        return localBuildInfo()
    }

    public static var defaultBuildType: String {
        #if DEBUG
        "debug"
        #else
        "release"
        #endif
    }

    public static func lane(for branch: String) -> String {
        if branch == "main" {
            return "main"
        }
        if branch.hasPrefix("release/") {
            return "release"
        }
        if branch.hasPrefix("snapshot/") {
            return "snapshot"
        }
        if branch == "HEAD" || branch.isEmpty {
            return "detached"
        }
        return "development"
    }

    private static func packagedBuildInfoPath() -> String {
        let executable = URL(fileURLWithPath: CommandLine.arguments.first ?? "")
        return executable
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("resources/build-info.json")
            .path
    }

    private static func decode(path: String) -> K8sBuildInfo? {
        guard let data = FileManager.default.contents(atPath: path) else {
            return nil
        }
        return try? JSONDecoder().decode(K8sBuildInfo.self, from: data)
    }

    private static func localBuildInfo() -> K8sBuildInfo {
        let root = git(["rev-parse", "--show-toplevel"]) ?? FileManager.default.currentDirectoryPath
        let branch = git(["branch", "--show-current"], root: root) ?? "unspecified"
        return K8sBuildInfo(
            source: remoteSource(root: root),
            branch: branch,
            lane: lane(for: branch),
            commit: git(["rev-parse", "HEAD"], root: root) ?? "unspecified",
            containerRef: firstLine(in: "\(root)/APPLE_CONTAINER_REF") ?? "unspecified"
        )
    }

    private static func remoteSource(root: String) -> String {
        let remote = git(["remote", "get-url", "origin"], root: root) ?? "unspecified"
        return remote.normalizedGitHubSource()
    }

    private static func git(_ arguments: [String], root: String? = nil) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: GitMetadata.executablePath)
        process.arguments = root.map { ["-C", $0] + arguments } ?? arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }
        guard process.terminationStatus == 0 else {
            return nil
        }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let value = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private static func firstLine(in path: String) -> String? {
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }
        return text.split(whereSeparator: \.isNewline).first.map(String.init)
    }
}

private enum GitMetadata {
    static let httpsSourcePrefix = ["https:", "", "github.com", ""].joined(separator: "/")
    static let sshSourcePrefix = "git@" + "github.com:"
    static let repositorySuffix = ".git"
    static var executablePath: String {
        ProcessInfo.processInfo.environment["CONTAINER_K8S_GIT"]
            ?? ["", "usr", "bin", "git"].joined(separator: "/")
    }
}

private extension String {
    func normalizedGitHubSource() -> String {
        self
            .replacingOccurrences(of: GitMetadata.httpsSourcePrefix, with: "")
            .replacingOccurrences(of: GitMetadata.sshSourcePrefix, with: "")
            .replacingOccurrences(of: GitMetadata.repositorySuffix, with: "")
    }
}
