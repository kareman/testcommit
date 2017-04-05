![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Linux-lightgrey.svg)

# testcommit

Locally test the latest commit to a software project. Supports Swift Package Manager and `make`.

This is mostly made as a demonstration of how to use [SwiftShell](https://github.com/kareman/SwiftShell) and [FileSmith](https://github.com/kareman/FileSmith). Especially this part:

```swift
if testdir.contains("Package.swift") {
	// Use the version of Swift defined in ".swift-version".
	// If that file does not exist, or that version is not installed, use the system default.
	let dotversion = cleanctx.run("cat", ".swift-version").stdout
	let fullversion = dotversion.characters.count > 8 ? dotversion : dotversion + "-RELEASE"
	cleanctx.env["TOOLCHAINS"] = (
		cleanctx.run("defaults", "read", "/Library/Developer/Toolchains/swift-\(fullversion).xctoolchain/Info", "CFBundleIdentifier")
		|| cleanctx.run("echo", "swift")
		).stdout

	try cleanctx.runAndPrint("swift","build")

	// If there are any unit tests, run them.
	let packagedescription = cleanctx.run("swift", "package", "describe")
	if packagedescription.succeeded {
		if packagedescription.stdout.contains("Test module: true") {
			try cleanctx.runAndPrint("swift", "test")
		}
	} else { // Swift < 3.1
		let runtests = cleanctx.run("swift", "test")
		if let error = runtests.error {
			if !runtests.stderror.contains("no tests found to execute") {
				main.stderror.write(runtests.stderror) // "swift test" prints results to stderror.
				throw error
			}
		} else {
			main.stderror.write(runtests.stderror)
		}
	}
}
```

## Installation

```bash
git clone https://github.com/kareman/testcommit
cd testcommit
swift build -c release
cp .build/release/testcommit /usr/local/bin/testcommit
```

## License

Released under the MIT License (MIT), http://opensource.org/licenses/MIT

Kåre Morstøl, [NotTooBad Software](http://nottoobadsoftware.com)

