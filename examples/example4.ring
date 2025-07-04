/*
 * Example 4: Type checking for TOML data
 * This example demonstrates how to check the data types of values in a TOML file
 * using the toml_type() function and predefined TOML type constants
 */

// Load the TOML extension
load "toml.ring"

? "--- Example: Checking TOML Data Types ---"

// 1. Parse the TOML file. This returns a C pointer to the parsed data structure
cFile = "example.toml"
pTomlResult = toml_parse_file(cFile)

// Check for parsing errors before proceeding
if (isNull(pTomlResult)) {
    ? "Error parsing file: " + toml_lasterror()   // Display last error message
    bye                                           // Exit the program if parsing failed
}

// 2. Define the keys we want to check for type information
// This array includes keys at different levels of the TOML hierarchy and a nonexistent key
aKeysToCheck = ["version", "is_active", "data_types", "title", "author", "database", "servers", "products", "nonexistent_key"]

// 3. Loop through the keys and check their types using toml_type()
for cKey in aKeysToCheck {
    see "Checking type for key: '" + cKey + "'" + "..."   // Display the current key being checked

    // Use toml_type() to get the type constant for this key
    nType = toml_type(pTomlResult, cKey)

    // Use a switch statement to convert the numeric type constant to a human-readable description
    switch nType {
        case TOML_FP64
            ?  "  -> Type is TOML_FP64 (Floating-Point Number)"    // Floating-point number type
        case TOML_BOOLEAN
            ? "  -> Type is TOML_BOOLEAN (Boolean)"                // Boolean (true/false) type
        case TOML_ARRAY
            ? "  -> Type is TOML_ARRAY (Array)"                    // Array type (ordered collection)
        case TOML_STRING
            ? "  -> Type is TOML_STRING (String)"                  // String type
        case TOML_INT64
            ? "  -> Type is TOML_INT64 (Integer)"                  // Integer number type
        case TOML_TABLE
            ? "  -> Type is TOML_TABLE (Table)"                    // Table type (key/value mapping)
        case TOML_UNKNOWN
            ? "  -> Key not found or type is unknown."             // Unknown or nonexistent key
        else
            ? "  -> Another TOML type (like Date/Time)."           // Other specialized TOML types
    }
}

? nl + "Done!"                                                     // Print final message