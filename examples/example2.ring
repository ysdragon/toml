/*
 * Example 2: Inline TOML parsing and list conversion demonstration
 * This example shows how to parse TOML content from a string variable and
 * convert it to a Ring list for easy data manipulation
 */

// Load the TOML extension
load "toml.ring"

// Define a TOML string with nested arrays of tables
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

// Convert the parsed TOML to a more convenient Ring list structure
// This makes accessing nested data more straightforward
tomlList = toml2list(tomlParsed)

// Display the fruits data using the converted list structure
? "=== Fruits Data ==="
? "First Fruit:"
? "Name: " + tomlList[:fruits][1][:name]                   // Access name of first fruit
? "Color: " + tomlList[:fruits][1][:physical][:color]      // Access nested physical properties
? "Shape: " + tomlList[:fruits][1][:physical][:shape]      // Access shape property
? "Varieties:"
? "- " + tomlList[:fruits][1][:varieties][1][:name]        // Access first variety of first fruit
? "- " + tomlList[:fruits][1][:varieties][2][:name]        // Access second variety of first fruit

? nl + "Second Fruit:"
? "Name: " + tomlList[:fruits][2][:name]                   // Access name of second fruit
? "Varieties:"
? "- " + tomlList[:fruits][2][:varieties][1][:name]        // Access first variety of second fruit

? nl + "Done!"                                             // Print final message