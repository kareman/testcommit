#!/usr/bin/env swiftshell

import SwiftShell
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
var clean = CustomContext(main)
let cleanenvvars = ["TERM_PROGRAM", "SHELL", "TERM", "TMPDIR", "Apple_PubSub_Socket_Render", "TERM_PROGRAM_VERSION", "TERM_SESSION_ID", "USER", "SSH_AUTH_SOCK", "__CF_USER_TEXT_ENCODING", "PATH", "PWD", "XPC_FLAGS", "XPC_SERVICE_NAME", "SHLVL", "HOME", "LOGNAME", "LC_CTYPE", "_"]
clean.env = clean.env.filterToDictionary(keys: cleanenvvars)
clean.env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

// Create a temporary directory for testing.
clean.currentdirectory = main.tempdirectory

do {
	try clean.runAndPrint("git", "clone", main.currentdirectory)
	clean.currentdirectory += URL(fileURLWithPath: main.currentdirectory).lastPathComponent + "/"

	if Files.fileExists(atPath: clean.currentdirectory + "Makefile") {
		try clean.runAndPrint("make")
	}

	if Files.fileExists(atPath: clean.currentdirectory + "Package.swift") {
		// Use the version of Swift defined in ".swift-version".
		// If that file does not exist, or that version is not installed, use the system default.
		clean.env["TOOLCHAINS"] = run(bash:"defaults read /Library/Developer/Toolchains/swift-`cat .swift-version`.xctoolchain/Info CFBundleIdentifier || echo swift").stdout
		try clean.runAndPrint("swift","build")
		try clean.runAndPrint("swift","test")
	}

	print("","Used temp directory", clean.currentdirectory, separator: "\n")
	try runAndPrint("say", "-v", "Daniel", "commit is okay")
} catch {
	run("say", "-v", "Daniel", "commit is faulty")
	try runAndPrint("open", ".") // open the temporary test folder in Finder.
	print("","Used temp directory", clean.currentdirectory, separator: "\n")
	exit(error)
}

