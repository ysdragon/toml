if (isWindows()) {
	if (getarch() = "x64") {
		loadlib("../lib/windows/amd64/ring_toml.dll")
	elseif (getarch() = "arm64")
		loadlib("../lib/windows/arm64/ring_toml.dll")
	elseif (getarch() = "x86")
		loadlib("../lib/windows/i386/ring_toml.dll")
	}
elseif (isLinux())
	if (getarch() = "x64") {
		loadlib("../lib/linux/amd64/libring_toml.so")
	elseif (getarch() = "arm64")
		loadlib("../lib/linux/arm64/libring_toml.so")
	}
elseif (isFreeBSD())
	if (getarch() = "x64") {
		loadlib("../lib/freebsd/amd64/libring_toml.so")
	elseif (getarch() = "arm64")
		loadlib("../lib/freebsd/arm64/libring_toml.so")
	}
elseif (isMacOSX())
	if (getarch() = "x64") {
		loadlib("../lib/macos/amd64/libring_toml.dylib")
	elseif (getarch() = "arm64")
		loadlib("../lib/macos/arm64/libring_toml.dylib")
	}
else
	raise("Unsupported OS! You need to build the library for your OS.")
}

load "stdlibcore.ring"
load "../src/toml.ring"
load "../src/toml.rh"
 
func main() {
	oTester = new TomlTest()
	oTester.runAllTests()
}

class TomlTest {
	cTestFile = "test.toml"
	pTomlResult
	aTomlList

	nTestsRun = 0
	nTestsFailed = 0

	func init() {
		? "Attempting to parse file: " + cTestFile
		pTomlResult = toml_parse_file(cTestFile)
		if (isNull(pTomlResult)) {
			? "Failed to parse TOML file. Error: " + toml_lasterror()
			raise("Prerequisite Failed: Could not parse the test file '" + cTestFile + "'. Error: " + toml_lasterror())
		}

		aTomlList = toml2list(pTomlResult)
		if (isNull(aTomlList)) {
			? "Failed to convert TOML result to list."
			raise("Prerequisite Failed: Could not convert TOML result to a Ring list.")
		}
		? "Successfully parsed TOML file and converted to list."
	}

	func assert(condition, message) {
		if (!condition) {
			raise("Assertion Failed: " + message)
		}
	}

	func run(testName, methodName) {
		nTestsRun++
		see "  " + testName + "..."
		try {
			call methodName()
			see " [PASS]" + nl
		catch
			nTestsFailed++
			see " [FAIL]" + nl
			see "    -> " + cCatchError + nl
		}
	}

	func runAllTests() {
		? "========================================"
		? "  Running TOML Extension Test Suite"
		? "========================================" + nl

		? "Testing Easy API (Direct to List)..."
		run("test_easy_parse_file", "test_easy_parse_file")
		run("test_easy_parse_string", "test_easy_parse_string")
		run("test_error_handling", "test_error_handling")
		? ""

		? "Testing Advanced API (Pointer-based)..."
		run("test_adv_get_simple_values", "test_adv_get_simple_values")
		run("test_adv_get_type", "test_adv_get_type")
		run("test_adv_get_table_and_array", "test_adv_get_table_and_array")
		? ""
		
		? "Testing Ring Helper (toml_get with paths)..."
		run("test_helper_get_nested", "test_helper_get_nested")
		run("test_helper_get_array_item", "test_helper_get_array_item")
		run("test_helper_get_from_array_of_tables", "test_helper_get_from_array_of_tables")
		? ""

		? "Testing toml_exists..."
		run("test_exists_valid_path", "test_exists_valid_path")
		run("test_exists_invalid_path", "test_exists_invalid_path")
		? ""

		? "Testing toml_keys..."
		run("test_keys_top_level", "test_keys_top_level")
		run("test_keys_nested_table", "test_keys_nested_table")
		run("test_keys_invalid_path", "test_keys_invalid_path")
		? ""

		? "Testing path validation..."
		run("test_path_validation_empty", "test_path_validation_empty")
		run("test_path_validation_dots", "test_path_validation_dots")
		run("test_path_validation_array_index", "test_path_validation_array_index")
		? ""

		? "========================================"
		? "Test Summary:"
		? "  Total Tests: " + nTestsRun
		? "  Passed: " + (nTestsRun - nTestsFailed)
		? "  Failed: " + nTestsFailed
		? "========================================"
		if (!nTestsFailed) {
			? "SUCCESS: All tests passed!"
		else
			? "FAILURE: Some tests did not pass."
		}

		shutdown(0)
	}

	func test_easy_parse_file() {
		assert(islist(aTomlList), "Result from easy parse should be a list.")
		assert(len(aTomlList) > 0, "Parsed list should not be empty.")
	}

	func test_easy_parse_string() {
		cTomlStr = 'key = "value"'
		aData = toml_parse(cTomlStr)
		assert(isPointer(aData), "toml_parse on string should return a pointer.")
		assert(toml2list(aData)[1][1] = "key" and toml2list(aData)[1][2] = "value", "Parsed string content is incorrect.")
	}

	func test_error_handling() {
		aBadData = toml_parse_file("nonexistent.toml")
		assert(isnull(aBadData), "Parsing a non-existent file should return NULL.")
		assert(len(toml_lasterror()) > 0, "toml_lasterror() should have a message after failure.")
	}

	func test_adv_get_simple_values() {
		cAuthor = toml_get_ex(pTomlResult, "author")
		assert(cAuthor = "Test User", "toml_get_ex should retrieve a top-level string.")
		
		nVersion = toml_get_ex(pTomlResult, "version")
		assert(nVersion = 1.0, "toml_get_ex should retrieve a number.")
	}
	
	func test_adv_get_type() {
		assert(toml_type(pTomlResult, "is_active") = TOML_BOOLEAN, "toml_type should identify TOML_BOOLEAN.")
		assert(toml_type(pTomlResult, "servers") = TOML_TABLE, "toml_type should identify TOML_TABLE.")
	}

	func test_adv_get_table_and_array() {
		aServers = toml_get_ex(pTomlResult, "servers")
		assert(islist(aServers), "toml_get_ex should return a list for a table.")
		assert(islist(aServers[1]) and aServers[1][1] = "alpha", "Table content is incorrect.")

		aProducts = toml_get_ex(pTomlResult, "products")
		assert(islist(aProducts), "toml_get_ex should return a list for an array of tables.")
		assert(len(aProducts) = 2, "Array of tables should have 2 items.")
	}

	func test_helper_get_nested() {
		cRole = toml_get(pTomlResult, "database.user.role")
		assert(cRole = "superuser", "Ring helper should get nested values.")
		
		cDC = toml_get(pTomlResult, "servers.beta.dc")
		assert(cDC = "us-west-1", "Ring helper should get values from tables with dotted keys.")
	}
	
	func test_helper_get_array_item() {
		cSecondItem = toml_get(pTomlResult, "database.data[2]")
		assert(cSecondItem = "posts", "Ring helper should get item by index from an array.")
	}

	func test_helper_get_from_array_of_tables() {
		cProductName = toml_get(pTomlResult, "products[2].name")
		assert(cProductName = "Nail", "Ring helper should get nested value from an array of tables.")
		
		nProductSku = toml_get(pTomlResult, "products[1].sku")
		assert(nProductSku = 738594937, "Ring helper should handle numeric values in array of tables.")
	}

	// toml_exists tests
	func test_exists_valid_path() {
		assert(toml_exists(pTomlResult, "author") = true, "toml_exists should return true for existing top-level key.")
		assert(toml_exists(pTomlResult, "database.ip_address") = true, "toml_exists should return true for nested key.")
		assert(toml_exists(pTomlResult, "products[1].name") = true, "toml_exists should return true for array item path.")
	}

	func test_exists_invalid_path() {
		assert(toml_exists(pTomlResult, "nonexistent") = false, "toml_exists should return false for non-existent key.")
		assert(toml_exists(pTomlResult, "database.nonexistent") = false, "toml_exists should return false for non-existent nested key.")
		assert(toml_exists(pTomlResult, "products[999].name") = false, "toml_exists should return false for out-of-bounds index.")
	}

	// toml_keys tests
	func test_keys_top_level() {
		aKeys = toml_keys(pTomlResult, "")
		assert(islist(aKeys), "toml_keys should return a list for top-level.")
		assert(len(aKeys) > 0, "toml_keys should return non-empty list for top-level.")
		assert(find(aKeys, "author") > 0, "Top-level keys should include 'author'.")
	}

	func test_keys_nested_table() {
		aKeys = toml_keys(pTomlResult, "database")
		assert(islist(aKeys), "toml_keys should return a list for nested table.")
		assert(find(aKeys, "ip_address") > 0, "database keys should include 'ip_address'.")
		assert(find(aKeys, "user") > 0, "database keys should include 'user'.")
	}

	func test_keys_invalid_path() {
		aKeys = toml_keys(pTomlResult, "nonexistent")
		assert(isNull(aKeys), "toml_keys should return NULL for non-existent path.")
		
		aKeys = toml_keys(pTomlResult, "author")
		assert(isNull(aKeys), "toml_keys should return NULL for non-table value.")
	}

	// Path validation tests
	func test_path_validation_empty() {
		assert(isNull(toml_get(pTomlResult, "")), "Empty path should return NULL.")
		assert(isNull(toml_get(pTomlResult, "   ")), "Whitespace-only path should return NULL.")
	}

	func test_path_validation_dots() {
		assert(isNull(toml_get(pTomlResult, ".author")), "Leading dot should return NULL.")
		assert(isNull(toml_get(pTomlResult, "author.")), "Trailing dot should return NULL.")
		assert(isNull(toml_get(pTomlResult, "database..user")), "Consecutive dots should return NULL.")
	}

	func test_path_validation_array_index() {
		assert(isNull(toml_get(pTomlResult, "products[]")), "Empty array index should return NULL.")
		assert(isNull(toml_get(pTomlResult, "products[0]")), "Zero index should return NULL (Ring is 1-based).")
		assert(isNull(toml_get(pTomlResult, "products[-1]")), "Negative index should return NULL.")
	}
}