/*
 * Example 3: Using toml_get_ex() for direct array access
 * This example demonstrates an alternative way to access complex TOML data
 * using the toml_get_ex() function for direct array extraction
 */

// Load the TOML extension
load "toml.ring"

// Define a TOML string with nested arrays of tables (same as Example 2)
// This TOML data represents a collection of fruits with their properties
tomlContent = `
[[fruits]]
name = "apple"

[fruits.physical]  # subtable
color = "red"
shape = "round"

[[fruits.varieties]]  # nested array of tables
name = "red delicious"

[[fruits.varieties]]
name = "granny smith"


[[fruits]]
name = "banana"

[[fruits.varieties]]
name = "plantain"
`

// Parse the TOML string into the native representation
tomlParsed = toml_parse(tomlContent)

// Display the fruits data using toml_get_ex() for direct array access
// Unlike example2.ring, this example doesn't convert to a Ring list first
? "=== Fruits Data ==="
? "First Fruit:"
? "Name: " + toml_get_ex(tomlParsed, "fruits")[1][:name]                   // Access name of first fruit
? "Color: " + toml_get_ex(tomlParsed, "fruits")[1][:physical][:color]      // Access nested physical properties
? "Shape: " + toml_get_ex(tomlParsed, "fruits")[1][:physical][:shape]      // Access shape property
? "Varieties:"
? "- " + toml_get_ex(tomlParsed, "fruits")[1][:varieties][1][:name]        // Access first variety of first fruit
? "- " + toml_get_ex(tomlParsed, "fruits")[1][:varieties][2][:name]        // Access second variety of first fruit

? nl + "Second Fruit:"
? "Name: " + toml_get_ex(tomlParsed, "fruits")[2][:name]                   // Access name of second fruit
? "Varieties:"
? "- " + toml_get_ex(tomlParsed, "fruits")[2][:varieties][1][:name]        // Access first variety of second fruit

? nl + "Done!"                                                              // Print final message