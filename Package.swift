import PackageDescription

let package = Package(
    name: "testcommit"
)

package.dependencies.append(.Package(url: "/Users/karemorstol/Programming/SwiftShell/SwiftShell3", majorVersion: 3))
