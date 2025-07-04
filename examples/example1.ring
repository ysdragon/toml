/*
 * Example 1: Basic TOML parsing demonstration
 * This example shows how to parse a TOML file and access its data using the toml.ring library
 */

// Load the TOML extension
load "toml.ring"

// Parse the TOML file into a Ring data structure
tomlParsed = toml_parse_file("example.toml")

// Test basic values from the root level of the TOML document
? "=== Basic Values ==="
? "Title: " + toml_get(tomlParsed, "title")            // Access a simple string value
? "Author: " + toml_get(tomlParsed, "author")          // Another string value
? "Is Active: " + toml_get(tomlParsed, "is_active")    // Boolean value
? "Version: " + toml_get(tomlParsed, "version")        // Number value

? "== Data Types ==="  // Demonstrate accessing different TOML data types
? "String Basic: " + toml_get(tomlParsed, "data_types.string_basic")           // Basic string
? "String Multiline: " + toml_get(tomlParsed, "data_types.string_multiline_basic")  // Multiline string
? "String Literal: " + toml_get(tomlParsed, "data_types.string_literal")       // Literal string
? "Integer Standard: " + toml_get(tomlParsed, "data_types.integer_standard")   // Standard integer
? "Integer Hex: " + toml_get(tomlParsed, "data_types.integer_hex")             // Hexadecimal integer
? "Float Standard: " + toml_get(tomlParsed, "data_types.float_standard")       // Standard float
? "Float Scientific: " + toml_get(tomlParsed, "data_types.float_scientific")   // Scientific notation
? "Boolean True: " + toml_get(tomlParsed, "data_types.boolean_true")      // Boolean true value
? "Datetime: " + toml_get(tomlParsed, "datetime_offset")                       // Date-time with offset

? "== Database Config ==="                                                     // Access nested tables
? "IP Address: " + toml_get(tomlParsed, "database.ip_address")                // IP address in database section
? "Port: " + toml_get(tomlParsed, "database.port")                            // Port number
? "User Name: " + toml_get(tomlParsed, "database.user.name")                  // Nested table access (database.user.name)
? "Data Array: " see toml_get(tomlParsed, "database.data")                    // Array value in database section

? "== Servers ==="                                                        // Server configurations
? "Alpha IP: " + toml_get(tomlParsed, "servers.alpha.ip")                     // IP of alpha server
? "Beta DC: " + toml_get(tomlParsed, "servers.beta.dc")                       // Data center for beta server

? "== Arrays and Tables ==="                                                   // Demonstrating arrays and tables
? "Point: " see toml_get(tomlParsed, "servers.beta.point")                    // Inline array as a point
? "Colors Array: " see toml_get(tomlParsed, "servers.beta.colors")            // Simple string array
? "Mixed Types: " see toml_get(tomlParsed, "servers.beta.mixed_types_array")  // Array with mixed data types
? "Nested Arrays: " see toml_get(tomlParsed, "servers.beta.nested_arrays")    // Array containing other arrays

? "== Array of Tables ==="
? "First Product: " see toml_get(tomlParsed, "products[1]")                   // Access first product in products array
? "Second Product: " see toml_get(tomlParsed, "products[2]")                  // Access second product in products array
? "First Person: " see toml_get(tomlParsed, "people[1]")                      // Access first person in people array
? "Second Person Physical: " see toml_get(tomlParsed, "people[2].physical")   // Access nested data in array of tables

? nl + "Done!"                                                                // Print final message