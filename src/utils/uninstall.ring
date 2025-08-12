load "stdlibcore.ring"

cPathSep = "/"

if isWindows()
	cPathSep = "\\"
ok

# Remove the toml.ring file from the load directory
remove(exefolder() + "load" + cPathSep + "toml.ring")

# Remove the toml.ring file from the Ring2EXE libs directory
remove(exefolder() + ".." + cPathSep + "tools" + cPathSep + "ring2exe" + cPathSep + "libs" + cPathSep + "toml.ring")

# Change current directory to the samples directory
chdir(exefolder() + ".." + cPathSep + "samples")

# Remove the UsingTOML directory if it exists
if direxists("UsingTOML")
	OSDeleteFolder("UsingTOML")
ok