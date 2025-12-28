cmake_minimum_required(VERSION 3.16)
project(RingTOML LANGUAGES C)

include(FetchContent)
find_package(Git QUIET)

set(RING_ROOT_DEFAULT "${CMAKE_CURRENT_SOURCE_DIR}/../..")
if(DEFINED ENV{RING})
	set(RING_ROOT_DEFAULT "$ENV{RING}")
endif()
set(RING_ROOT "${RING_ROOT_DEFAULT}" CACHE PATH "Path to the Ring project root directory.")
message(STATUS "Using Ring from: ${RING_ROOT}")

if(NOT TARGET Ring::Ring)
	add_library(Ring::Ring UNKNOWN IMPORTED)
	find_path(RING_INCLUDE_DIR ring.h PATHS "${RING_ROOT}/language/include")
	find_library(RING_LIBRARY_PATH NAMES ring PATHS "${RING_ROOT}/lib")

	if(NOT RING_INCLUDE_DIR OR NOT RING_LIBRARY_PATH)
		message(FATAL_ERROR "Could not find Ring headers or library in ${RING_ROOT}. "
							"Please set the RING_ROOT cache variable correctly.")
	endif()

	set_target_properties(Ring::Ring PROPERTIES
		IMPORTED_LOCATION "${RING_LIBRARY_PATH}"
		INTERFACE_INCLUDE_DIRECTORIES "${RING_INCLUDE_DIR}"
	)
endif()

# Set paths
set(RING_INCLUDE "${RING_ROOT}/language/include")
set(RING_LIB "${RING_ROOT}/lib")
set(CODEGEN_SCRIPT "${RING_ROOT}/extensions/codegen/parsec.ring")

# Build the tomlc17 object library
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/tomlc17")
	FetchContent_Declare(
		tomlc17_external
		GIT_REPOSITORY https://github.com/cktan/tomlc17.git
		GIT_TAG main
	)
	FetchContent_MakeAvailable(tomlc17_external)
	set(TOMLC17_SOURCE_DIR "${tomlc17_external_SOURCE_DIR}")
	if(EXISTS "${TOMLC17_SOURCE_DIR}/tomlc17.c")
		set(TOMLC17_C_FILE "${TOMLC17_SOURCE_DIR}/tomlc17.c")
	elseif(EXISTS "${TOMLC17_SOURCE_DIR}/src/tomlc17.c")
		set(TOMLC17_C_FILE "${TOMLC17_SOURCE_DIR}/src/tomlc17.c")
	else()
		message(FATAL_ERROR "Could not find tomlc17.c in fetched tomlc17 repository.")
	endif()
else()
	set(TOMLC17_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/tomlc17")
	set(TOMLC17_C_FILE "${TOMLC17_SOURCE_DIR}/src/tomlc17.c")
endif()

add_library(tomlc17 OBJECT
	${TOMLC17_C_FILE}
)
set_target_properties(tomlc17 PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(tomlc17 PUBLIC
	${TOMLC17_SOURCE_DIR}/src
)

# Determine OS and Architecture specific paths
string(TOLOWER "${CMAKE_SYSTEM_NAME}" OS_DIR)
if(OS_DIR STREQUAL "darwin")
	set(OS_DIR "macos")
endif()

string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" ARCH_DIR_RAW)

if(CMAKE_SYSTEM_NAME STREQUAL "Windows" AND DEFINED CMAKE_GENERATOR_PLATFORM)
	if(CMAKE_GENERATOR_PLATFORM STREQUAL "Win32")
		set(ARCH_DIR_RAW "i386")
	elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "x64")
		set(ARCH_DIR_RAW "amd64")
	elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "ARM64")
		set(ARCH_DIR_RAW "arm64")
	else()
		message(WARNING "Unsupported CMAKE_GENERATOR_PLATFORM: ${CMAKE_GENERATOR_PLATFORM}, falling back to CMAKE_SYSTEM_PROCESSOR")
	endif()
endif()

if(NOT DEFINED ARCH_DIR)
	if(ARCH_DIR_RAW MATCHES "x86_64|amd64")
		set(ARCH_DIR "amd64")
	elseif(ARCH_DIR_RAW MATCHES "aarch64|arm64")
		set(ARCH_DIR "arm64")
	elseif(ARCH_DIR_RAW MATCHES "riscv64")
		set(ARCH_DIR "riscv64")
	elseif(ARCH_DIR_RAW MATCHES "i386|i686|x86")
		set(ARCH_DIR "i386")
	else()
		set(ARCH_DIR "${ARCH_DIR_RAW}")
		message(WARNING "Unsupported architecture: ${ARCH_DIR_RAW}. Using as directory name.")
	endif()
endif()

# Detect musl libc
option(MUSL "Build for musl libc" OFF)
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
	# Auto-detect musl if not explicitly set
	if(NOT MUSL)
		execute_process(
			COMMAND ldd --version
			OUTPUT_VARIABLE LDD_OUTPUT
			ERROR_VARIABLE LDD_OUTPUT
			OUTPUT_STRIP_TRAILING_WHITESPACE
		)
		if(LDD_OUTPUT MATCHES "musl")
			set(MUSL ON)
			message(STATUS "Detected musl libc")
		endif()
	endif()
endif()

# Set the destination directory for the built library
if(MUSL AND OS_DIR STREQUAL "linux")
	set(LIB_DEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lib/${OS_DIR}/musl/${ARCH_DIR}")
else()
	set(LIB_DEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lib/${OS_DIR}/${ARCH_DIR}")
endif()

# Create the Ring TOML extension shared library
add_library(ring_toml SHARED
	${CMAKE_CURRENT_SOURCE_DIR}/src/ring_toml.c
)

# Include directories
target_include_directories(ring_toml PRIVATE 
	${RING_INCLUDE}
)

# Link libraries
target_link_libraries(ring_toml PRIVATE
	Ring::Ring
	tomlc17
)

target_compile_options(ring_toml PRIVATE
	$<$<CONFIG:Release,RelWithDebInfo,MinSizeRel>:
		$<$<C_COMPILER_ID:MSVC>:/O2>
		$<$<NOT:$<C_COMPILER_ID:MSVC>>:-O3>
		-DNDEBUG
	>
)

target_compile_options(tomlc17 PRIVATE
	$<$<CONFIG:Release,RelWithDebInfo,MinSizeRel>:
		$<$<C_COMPILER_ID:MSVC>:/O2>
		$<$<NOT:$<C_COMPILER_ID:MSVC>>:-O3>
		-DNDEBUG
	>
)

# Set target properties for output name and prefix
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
	set_target_properties(ring_toml PROPERTIES
		OUTPUT_NAME "ring_toml"
	)
else()
	set_target_properties(ring_toml PROPERTIES
		PREFIX "lib"
		OUTPUT_NAME "ring_toml"
	)
endif()

# Add post-build command to move the built library to the OS/architecture-specific directory
add_custom_command(
	TARGET ring_toml
	POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E make_directory ${LIB_DEST_DIR}
	COMMAND ${CMAKE_COMMAND} -E rename $<TARGET_FILE:ring_toml> ${LIB_DEST_DIR}/$<TARGET_FILE_NAME:ring_toml>
	COMMENT "Moving built library to ${LIB_DEST_DIR}"
	VERBATIM
)

# Install rule
install(TARGETS ring_toml
	LIBRARY DESTINATION "${RING_ROOT}/lib"
)

# Print info message
message(STATUS "Ring TOML Extension Configuration:")
message(STATUS "  - Ring Include Dir: ${RING_INCLUDE_DIR}")
message(STATUS "  - Ring Library Path: ${RING_LIBRARY_PATH}")