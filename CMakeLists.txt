cmake_minimum_required(VERSION 3.16)
project(RingTOML)

include(FetchContent)
find_package(Git QUIET)

# Get the Ring source directory from environment or use default
if(NOT DEFINED ENV{RING})
	set(RING_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/../..")
	message(STATUS "RING_SOURCE not defined, using default: ${RING_SOURCE}")
else()
	set(RING_SOURCE $ENV{RING})
	message(STATUS "Using RING_SOURCE from environment: ${RING_SOURCE}")
endif()

# Set paths
set(RING_INCLUDE "${RING_SOURCE}/language/include")
set(RING_LIB "${RING_SOURCE}/lib")
set(CODEGEN_SCRIPT "${RING_SOURCE}/extensions/codegen/parsec.ring")

# Build the tomlc17 object library
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/tomlc17")
    FetchContent_Declare(
        tomlc17_external
        GIT_REPOSITORY https://github.com/cktan/tomlc17.git
        GIT_TAG main
    )
    FetchContent_MakeAvailable(tomlc17_external)
    set(TOMLC17_SOURCE_DIR "${tomlc17_external_SOURCE_DIR}")
else()
    set(TOMLC17_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/tomlc17")
endif()

add_library(tomlc17 OBJECT
	${TOMLC17_SOURCE_DIR}/src/tomlc17.c
)
set_target_properties(tomlc17 PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(tomlc17 PUBLIC
	${TOMLC17_SOURCE_DIR}/src
)

# Generate the C source code from the configuration file
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/ring_toml.c")
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/src/ring_toml.c
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}
        COMMAND ${RING_SOURCE}/bin/ring ${CODEGEN_SCRIPT} ${CMAKE_CURRENT_SOURCE_DIR}/src/tomlc17.cf ${CMAKE_CURRENT_SOURCE_DIR}/src/ring_toml.c ${CMAKE_CURRENT_SOURCE_DIR}/src/ring_toml.rh
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/tomlc17.cf ${CODEGEN_SCRIPT} ${TOMLC17_SOURCE_DIR}/src/tomlc17.c
        COMMENT "Generating C code from tomlc17.cf"
        VERBATIM
    )
endif()

# Determine OS and Architecture specific paths
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
	set(OS_DIR "linux")
elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
	set(OS_DIR "freebsd")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
	set(OS_DIR "windows")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
	set(OS_DIR "macos")
else()
	message(FATAL_ERROR "Unsupported operating system: ${CMAKE_SYSTEM_NAME}")
endif()

# Determine architecture
if(CMAKE_SYSTEM_NAME STREQUAL "Windows" AND DEFINED CMAKE_GENERATOR_PLATFORM)
    if(CMAKE_GENERATOR_PLATFORM STREQUAL "Win32")
        set(ARCH_DIR "i386")
    elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "x64")
        set(ARCH_DIR "amd64")
    elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "ARM64")
        set(ARCH_DIR "arm64")
    else()
        message(WARNING "Unsupported CMAKE_GENERATOR_PLATFORM: ${CMAKE_GENERATOR_PLATFORM}, falling back to CMAKE_SYSTEM_PROCESSOR")
    endif()
endif()

# Fallback to CMAKE_SYSTEM_PROCESSOR if ARCH_DIR is not set
if(NOT DEFINED ARCH_DIR)
    string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" CMAKE_SYSTEM_PROCESSOR_LC)
    if(CMAKE_SYSTEM_PROCESSOR_LC MATCHES "x86_64|amd64")
        set(ARCH_DIR "amd64")
    elseif(CMAKE_SYSTEM_PROCESSOR_LC MATCHES "aarch64|arm64")
        set(ARCH_DIR "arm64")
    elseif(CMAKE_SYSTEM_PROCESSOR_LC MATCHES "riscv64")
        set(ARCH_DIR "riscv64")
    elseif(CMAKE_SYSTEM_PROCESSOR_LC MATCHES "i386|i686|x86")
        set(ARCH_DIR "i386")
    else()
        message(FATAL_ERROR "Unsupported architecture: ${CMAKE_SYSTEM_PROCESSOR}")
    endif()
endif()

# Set the destination directory for the built library
set(LIB_DEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lib/${OS_DIR}/${ARCH_DIR}")

# Create the Ring TOML extension shared library
add_library(ring_toml SHARED
	${CMAKE_CURRENT_SOURCE_DIR}/src/ring_toml.c
)

# Include directories
target_include_directories(ring_toml PRIVATE 
	${RING_INCLUDE}
)

# Enable optimizations and strip debug symbols for release builds
if(NOT CMAKE_BUILD_TYPE MATCHES Debug)
	if(UNIX)
		target_compile_options(ring_toml PRIVATE -O3 -DNDEBUG)
		target_compile_options(tomlc17 PRIVATE -O3 -DNDEBUG)
		target_link_options(ring_toml PRIVATE -s)
	elseif(WIN32)
		target_compile_options(ring_toml PRIVATE /O2 /DNDEBUG)
		target_compile_options(tomlc17 PRIVATE /O2 /DNDEBUG)
	endif()
endif()

# Link libraries
if(WIN32)
	target_link_libraries(ring_toml PRIVATE
		${RING_LIB}/ring.lib
		tomlc17
	)
else()
	target_link_libraries(ring_toml PRIVATE
		${RING_LIB}/libring${CMAKE_SHARED_LIBRARY_SUFFIX}
		tomlc17
	)
endif()

# Set target properties for output name and prefix
if(WIN32)
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
	LIBRARY DESTINATION ${RING_LIB}
)

# Print info message
message(STATUS "Ring TOML Extension Configuration:")
message(STATUS "  - Ring Include Dir: ${RING_INCLUDE}")
message(STATUS "  - Ring Library Dir: ${RING_LIB}")