if (isWindows()) {
	loadlib("ring_toml.dll")
elseif (isLinux() || isFreeBSD())
	loadlib("libring_toml.so")
elseif (isMacOSX())
	loadlib("libring_toml.dylib")
else
	raise("Unsupported OS! You need to build the library for your OS.")
}

// Load StdLibCore.
load "stdlibcore.ring"

// Load Ring TOML.
load "src/toml.ring"
load "src/toml.rh"