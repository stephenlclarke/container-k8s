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

public struct PlannedCommand: Equatable, Sendable {
    public var name: String
    public var summary: String
    public var cluster: String?
    public var arguments: [String]

    public init(name: String, summary: String, cluster: String? = nil, arguments: [String] = []) {
        self.name = name
        self.summary = summary
        self.cluster = cluster
        self.arguments = arguments
    }

    public var dryRunDescription: String {
        var fields = ["command=\(name)"]
        if let cluster {
            fields.append("cluster=\(cluster)")
        }
        if !arguments.isEmpty {
            fields.append("arguments=\(arguments.joined(separator: ","))")
        }
        return "planned: \(summary) (\(fields.joined(separator: " ")))"
    }
}
