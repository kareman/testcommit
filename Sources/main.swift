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
var clean = CustomContext(main)
let cleanenvvars = ["TERM_PROGRAM", "SHELL", "TERM", "TMPDIR", "Apple_PubSub_Socket_Render", "TERM_PROGRAM_VERSION", "TERM_SESSION_ID", "USER", "SSH_AUTH_SOCK", "__CF_USER_TEXT_ENCODING", "PATH", "XPC_FLAGS", "XPC_SERVICE_NAME", "SHLVL", "HOME", "LOGNAME", "LC_CTYPE", "_"]
clean.env = clean.env.filterToDictionary(keys: cleanenvvars)
clean.env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

// Create a temporary directory for testing.
clean.currentdirectory = main.tempdirectory

do {
	try clean.runAndPrint("git", "clone", main.currentdirectory)
	clean.currentdirectory += DirectoryPath(main.currentdirectory).name
	let testdir = try Directory(open: clean.currentdirectory)

	if testdir.contains("Makefile") {
		let targets = Array(clean.runAsync(bash: "make -qp | awk -F':' '/^[a-zA-Z0-9][^$#\\/\t=]*:([^=]|$)/ {split($1,A,/ /);for(i in A)print A[i]}'").stdout.lines())
		if targets.contains("build") { try clean.runAndPrint("make", "build") }
		if targets.contains("test") { try clean.runAndPrint("make", "test") }
	}

	if testdir.contains("Package.swift") {
		// Use the version of Swift defined in ".swift-version".
		// If that file does not exist, or that version is not installed, use the system default.
		clean.env["TOOLCHAINS"] = (run("defaults", "read", "/Library/Developer/Toolchains/swift-\(run("cat", ".swift-version").stdout).xctoolchain/Info", "CFBundleIdentifier") || run("echo", "swift")).stdout
		try clean.runAndPrint("swift","build")

		if !testdir.directories("Tests/*").isEmpty {
			try clean.runAndPrint("swift","test")
		}
	}

	print("","Used temp directory", clean.currentdirectory, separator: "\n")
	try runAndPrint("say", "-v", "Daniel", "commit is okay")
} catch {
	run("say", "-v", "Daniel", "commit is faulty")
	try runAndPrint("open", ".") // open the temporary test folder in Finder.
	print("","Used temp directory", clean.currentdirectory, separator: "\n")
	exit(error)
}

