import PackageDescription

let package = Package(
    name: "testcommit"
)

package.dependencies.append(.Package(url: "https://github.com/kareman/SwiftShell", "3.0.0-beta"))
package.dependencies.append(.Package(url: "https://github.com/kareman/FileSmith", "0.1.3"))
