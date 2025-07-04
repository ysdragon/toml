# Ring TOML

A comprehensive TOML parser extension for the Ring programming language, built as a wrapper around the [`tomlc17`](https://github.com/cktan/tomlc17) C library.

## Features

*   Cross-platform (Windows, Linux, FreeBSD)
*   Parse TOML files and strings into Ring Lists.
*   Supports all TOML data types, including strings, numbers, booleans, dates, times, arrays, and tables.

## Getting Started

### Installation

#### Using RingPM

```shell
ringpm install toml from ysdragon
```

#### Manual Build

##### Prerequisites

*   [Ring](http://ring-lang.net) programming language (1.22 or later)
*   CMake (3.5 or later)
*   C compiler (GCC, Clang, or MSVC)

##### Manual Build Steps

1.  **Clone the repository:**
    ```bash
    git clone --recursive https://github.com/ysdragon/toml.git
    cd toml
    ```

2.  **Set RING environment variable to your Ring installation directory:**

    On Windows (cmd):
    ```cmd
    set RING=X:\path\to\ring
    ```

    On Windows (PowerShell):
    ```powershell
    $env:RING = "X:\path\to\ring"
    ```

    On Unix-like systems:
    ```bash
    export RING=/path/to/ring
    ```
3. **Build the extension:**
    ```bash
    cmake -Bbuild -DCMAKE_BUILD_TYPE=Release
    cmake --build build
    ```

    This will compile the extension and place the resulting shared library (`libring_toml.so` on Linux or FreeBSD, `ring_toml.dll` on Windows) into the `lib/<os>/<arch>` directory.

## Usage

```ring
// Load the TOML extension
load "toml.ring"

// Parse a TOML file
pToml = toml_parse_file("examples/example.toml")

// Access data using the toml_get() function
title = toml_get(pToml, "title")
db_ip = toml_get(pToml, "database.ip_address")
first_product_name = toml_get(pToml, "products[1].name")

? "Title: " + title
? "Database IP: " + db_ip
? "First Product: " + first_product_name

// You can also convert the entire TOML structure to a Ring list
aTomlList = toml2list(pToml)
see aTomlList
```

## API Reference

### High-Level Functions

*   `toml_get(pTomlResult, cPath)`: Retrieves a value from the parsed TOML data using a dot-separated path.
    *   `pTomlResult`: The pointer returned by `toml_parse()` or `toml_parse_file()`.
    *   `cPath`: A string representing the path to the desired value (e.g., `"database.user.name"`, `"products[2].sku"`).

### Core Extension Functions

*   `toml_parse(cTomlString)`: Parses a TOML-formatted string. Returns a pointer to the parsed result.
*   `toml_parse_file(cFilePath)`: Parses a TOML file. Returns a pointer to the parsed result.
*   `toml2list(pTomlResult)`: Converts the entire parsed TOML result into a Ring list.
*   `toml_get_ex(pTomlResult, cKey)`: Retrieves a specific value, table, or array by its key from the top level.
*   `toml_type(pTomlResult, cKey)`: Returns the TOML type of a value by its key as an integer.
*   `toml_lasterror()`: Returns a string containing the last error message if a parsing operation fails.

## Examples

The [**`examples`**](examples) directory contains several files demonstrating how to use the Ring TOML extension.

*   [**`example1.ring`**](examples/example1.ring): Demonstrates basic TOML file parsing and how to access various data types using the `toml_get()` helper function.
*   [**`example2.ring`**](examples/example2.ring): Shows how to parse an inline TOML string and convert the entire structure into a Ring list for easier manipulation.
*   [**`example3.ring`**](examples/example3.ring): Illustrates an alternative way to access TOML data by using the `toml_get_ex()` function to directly extract arrays and tables without first converting to a list.
*   [**`example4.ring`**](examples/example4.ring): Shows how to perform type checking on TOML data using the `toml_type()` function and the predefined type constants.

## Running Tests

The project includes a test suite to verify the functionality of the extension. To run the tests:

```bash
ring tests/TOML_test.ring
```

The test script will parse `tests/test.toml` and run a series of assertions against the parsed data, covering all major features of the library.

## License

This project is licensed under the [MIT](LICENSE) License.
