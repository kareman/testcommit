#!/usr/bin/env swiftshell

import SwiftShell
import FileSmith
import Foundation

extension Dictionary where Key:Hashable {
	public func filterToDictionary <C: Collection> (keys: C) -> [Key:Value]
		where C.Iterator.Element == Key, C.IndexDistance == Int {

		var result = [Key:Value](minimumCapacity: keys.count)
		for key in keys { result[key] = self[key]	}
		return result
	}
}

// Prepare an environment as close to a new OS X user account as possible.
var cleancontext = CustomContext(main)
let cleanenvvars = ["TERM_PROGRAM", "SHELL", "TERM", "TMPDIR", "Apple_PubSub_Socket_Render", "TERM_PROGRAM_VERSION", "TERM_SESSION_ID", "USER", "SSH_AUTH_SOCK", "__CF_USER_TEXT_ENCODING", "PATH", "XPC_FLAGS", "XPC_SERVICE_NAME", "SHLVL", "HOME", "LOGNAME", "LC_CTYPE", "_"]
cleancontext.env = cleancontext.env.filterToDictionary(keys: cleanenvvars)
cleancontext.env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

// Create a temporary directory for testing.
cleancontext.currentdirectory = main.tempdirectory

do {
	try cleancontext.runAndPrint("git", "clone", main.currentdirectory)
	cleancontext.currentdirectory += DirectoryPath(main.currentdirectory).name
	let testdir = try Directory(open: cleancontext.currentdirectory)

	if testdir.contains("Makefile") {
		let targets = cleancontext.run(bash: "make -qp | awk -F':' '/^[a-zA-Z0-9][^$#\\/\t=]*:([^=]|$)/ {split($1,A,/ /);for(i in A)print A[i]}'").stdout.lines()
		if targets.contains("build") { try cleancontext.runAndPrint("make", "build") }
		if targets.contains("test") { try cleancontext.runAndPrint("make", "test") }
	}

	if testdir.contains("Package.swift") {
		// Use the version of Swift defined in ".swift-version".
		// If that file does not exist, or that version is not installed, use the system default.
		let dotversion = cleancontext.run("cat", ".swift-version").stdout
		let fullversion = dotversion.characters.count > 8 ? dotversion : dotversion + "-RELEASE"
		cleancontext.env["TOOLCHAINS"] = (
			cleancontext.run("defaults", "read",
			          "/Library/Developer/Toolchains/swift-\(fullversion).xctoolchain/Info", "CFBundleIdentifier")
			|| cleancontext.run("echo", "swift")
			).stdout

		try cleancontext.runAndPrint("swift","build")

		let packagedescription = cleancontext.run("swift", "package", "describe")
		if packagedescription.succeeded {
			if packagedescription.stdout.contains("Test module: true") {
				try cleancontext.runAndPrint("swift", "test")
			}
		} else { // Swift < 3.1
			let runtests = cleancontext.run("swift", "test")
			if let error = runtests.error {
				if !runtests.stderror.contains("no tests found to execute") {
					main.stderror.write(runtests.stderror) // test results are printed to stderror.
					throw error
				}
			} else {
				main.stderror.write(runtests.stderror)
			}
		}
	}

	print("","Used temp directory", cleancontext.currentdirectory, separator: "\n")
	try runAndPrint("say", "-v", "Daniel", "commit is okay")
} catch {
	run("say", "-v", "Daniel", "commit is faulty")
	try runAndPrint("open", ".") // open the temporary test folder in Finder.
	print("","Used temp directory", cleancontext.currentdirectory, separator: "\n")
	exit(error)
}

