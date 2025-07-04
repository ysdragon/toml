aPackageInfo = [
	:name = "Ring TOML",
	:description = "A comprehensive TOML parser extension for Ring programming language.",
	:folder = "toml",
	:developer = "ysdragon",
	:email = "youssefelkholey@gmail.com",
	:license = "MIT License",
	:version = "1.0.0",
	:ringversion = "1.22",
	:versions = 	[
		[
			:version = "1.0.0",
			:branch = "master"
		]
	],
	:libs = 	[
		[
			:name = "",
			:version = "",
			:providerusername = ""
		]
	],
	:files = 	[
		"README.md",
		"CMakeLists.txt",
		"lib.ring",
		"main.ring",
		"src/ring_toml.rh",
		"src/setup.ring",
		"src/tomlc17.cf",
		"examples/example.toml",
		"examples/example1.ring",
		"examples/example2.ring",
		"examples/example3.ring",
		"examples/example4.ring",
		"tests/test.toml",
		"tests/TOML_test.ring"
	],
	:ringfolderfiles = 	[

	],
	:windowsfiles = 	[
		"lib/windows/amd64/ring_toml.dll"
	],
	:linuxfiles = 	[
		"lib/linux/amd64/libring_toml.so"
	],
	:ubuntufiles = 	[

	],
	:fedorafiles = 	[

	],
	:freebsdfiles	= [
		"lib/freebsd/amd64/libring_toml.so"
	],
	:macosfiles = 	[

	],
	:windowsringfolderfiles = 	[

	],
	:linuxringfolderfiles = 	[

	],
	:ubunturingfolderfiles = 	[

	],
	:fedoraringfolderfiles = 	[

	],
	:freebsdringfolderfiles	= [
		
	],
	:macosringfolderfiles = 	[

	],
	:run = "ring main.ring",
	:windowsrun = "",
	:linuxrun = "",
	:macosrun = "",
	:ubunturun = "",
	:fedorarun = "",
	:setup = "ring src/setup.ring",
	:windowssetup = "",
	:linuxsetup = "",
	:macossetup = "",
	:ubuntusetup = "",
	:fedorasetup = "",
	:remove = "",
	:windowsremove = "",
	:linuxremove = "",
	:macosremove = "",
	:ubunturemove = "",
	:fedoraremove = ""
]