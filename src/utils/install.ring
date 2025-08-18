/*
	Ring TOML Library Install Script
	----------------------------------
	This script installs the Ring TOML library for the current platform.
	It detects the OS and architecture, then copies or symlinks the library to the 
	appropriate system location.
*/

load "stdlibcore.ring"
load "src/utils/color.ring"

// Default library settings
cLibPrefix = "lib"
cPathSep = "/"

// Platform detection and configuration
switch (true) {
	case isWindows()
		cLibPrefix = ""
		cPathSep = "\\"
		cLibExt = ".dll"
		cOSName = "windows"
	case isLinux()
		cLibExt = ".so"
		cOSName = "linux"
	case isFreeBSD()
		cLibExt = ".so"
		cOSName = "freebsd"
	case isMacOSX()
		cLibExt = ".dylib"
		cOSName = "macos"
	else
		? colorText([:text = "Error: Unsupported operating system detected!", :color = :BRIGHT_RED, :style = :BOLD])
		return
}

// Get system architecture
cArchName = getarch()
switch (cArchName) {
	case "x86"
		cArchName = "i386"
	case "x64"
		cArchName = "amd64"
	case "arm64"
		cArchName = "arm64"
	else
		? colorText([:text = "Error: Unsupported architecture: " + cArchName, :color = :BRIGHT_RED, :style = :BOLD])
		return
}

// Construct the package path
cPackagePath = exefolder() + ".." + cPathSep + "tools" + cPathSep + "ringpm" + cPathSep + "packages" + cPathSep + "toml"

// Construct the library path
cLibPath = cPackagePath + cPathSep + "lib" + cPathSep + 
		cOSName + cPathSep + cArchName + cPathSep + cLibPrefix + "ring_toml" + cLibExt

// Verify library exists
if (!fexists(cLibPath)) {
	? colorText([:text = "Error: TOML library not found!", :color = :BRIGHT_RED, :style = :BOLD])
	? colorText([:text = "Expected location: ", :color = :YELLOW]) + colorText([:text = cLibPath, :color = :CYAN])
	? colorText([:text = "Please ensure the library is built for your platform (" + cOSName + "/" + cArchName + ")", :color = :BRIGHT_MAGENTA])
	? colorText([:text = "You can refer to README.md for build instructions: ", :color = :CYAN]) + colorText([:text = cPackagePath + cPathSep + "README.md", :color = :YELLOW])
	return
}

// Install library based on platform
try {
	if (isWindows()) {
		systemSilent("copy /y " + '"' + cLibPath + '" "' + exefolder() + '"')
	else
		cLibDir = exefolder() + ".." + cPathSep + "lib"
		if (isFreeBSD() || isMacOSX()) {
			cDestDir = "/usr/local/lib"
		elseif (isLinux())
			cDestDir = "/usr/lib"
		}
		cCommand1 = 'ln -sf "' + cLibPath + '" "' + cLibDir + '"'
		cCommand2 = 'which sudo >/dev/null 2>&1 && sudo ln -sf "' + cLibPath + '" "' + cDestDir + 
				'" || (which doas >/dev/null 2>&1 && doas ln -sf "' + cLibPath + '" "' + cDestDir + 
				'" || ln -sf "' + cLibPath + '" "' + cDestDir + '")'
		system(cCommand1)
		system(cCommand2)
	}

	// Copy examples to the samples/UsingTOML directory
	cCurrentDir = currentdir()
	cExamplesPath = cPackagePath + cPathSep + "examples"
	cSamplesPath = exefolder() + ".." + cPathSep + "samples" + cPathSep + "UsingTOML"

	// Ensure the samples directory exists and create it if not
	if (!direxists(exefolder() + ".." + cPathSep + "samples")) {
		makeDir(exefolder() + ".." + cPathSep + "samples")
	}

	// Create the UsingTOML directory
	makeDir(cSamplesPath)

	// Change to the samples directory
	chdir(cSamplesPath)

	// Loop through the examples and copy them to the samples directory
	for item in dir(cExamplesPath) {
		if (item[2]) {
			OSCopyFolder(cExamplesPath + cPathSep, item[1])
		else
			OSCopyFile(cExamplesPath + cPathSep + item[1])
		}
	}
	
	// Change back to the original directory
	chdir(cCurrentDir)

	// Check if toml.ring exists in the exefolder
	if (fexists(exefolder() + "toml.ring")) {
		// Remove the existing toml.ring file
		remove(exefolder() + "toml.ring")

		// Write the load command to the toml.ring file
		write(exefolder() + "load" + cPathSep + "toml.ring", `load "/../../tools/ringpm/packages/toml/lib.ring"`)
	}
	
	// Ensure the Ring2EXE libs directory exists
	if (direxists(exefolder() + ".." + cPathSep + "tools" + cPathSep + "ring2exe" + cPathSep + "libs")) {
		// Write the library definition to the toml.ring file for Ring2EXE
		write(exefolder() + ".." + cPathSep + "tools" + cPathSep + "ring2exe" + cPathSep + "libs" + cPathSep + "toml.ring", getRing2EXEContent())
	}
	
	? colorText([:text = "Successfully installed Ring TOML!", :color = :BRIGHT_GREEN, :style = :BOLD])
	? colorText([:text = "You can refer to samples in: ", :color = :CYAN]) + colorText([:text = cSamplesPath, :color = :YELLOW])
	? colorText([:text = "Or in the package directory: ", :color = :CYAN]) + colorText([:text = cExamplesPath, :color = :YELLOW])
catch
	? colorText([:text = "Error: Failed to install Ring TOML!", :color = :BRIGHT_RED, :style = :BOLD])
	? colorText([:text = "Details: ", :color = :YELLOW]) + colorText([:text = cCatchError, :color = :CYAN])
}


func getRing2EXEContent() {
	return `aLibrary = [:name = :toml,
	 :title = "TOML",
	 :windowsfiles = [
		"ring_toml.dll"
	 ],
	 :linuxfiles = [
		"libring_toml.so"
	 ],
	 :macosxfiles = [
		"libring_toml.dylib"
	 ],
	 :freebsdfiles = [
		"libring_toml.so"
	 ],
	 :ubuntudep = "",
	 :fedoradep = "",
	 :macosxdep = "",
	 :freebsddep = ""
	]`
}