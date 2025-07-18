if (isWindows()) {
	loadlib("../lib/windows/amd64/ring_toml.dll")
elseif (isLinux())
	if (getarch() = "x64") {
		loadlib("../lib/linux/amd64/libring_toml.so")
	elseif (getarch() = "arm64")
		loadlib("../lib/linux/arm64/libring_toml.so")
	}
elseif (isFreeBSD())
	loadlib("../lib/freebsd/amd64/libring_toml.so")
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
load "../src/ring_toml.rh"
 
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
}

/*
 *  toml_get(aTomlData, "key.subkey[index]")
 *  This helper function finds a value in the parsed TOML data using a dot-separated path.
 */
func toml_get(data, path) {
	aParts = split(path, ".")
	current_data = toml2list(data)
	for part in aParts {
		cKey = part
		nIndex = 0

		// Check for array index like "ports[1]"
		if (right(cKey, 1) = "]") {
			nPos = substr(cKey, "[")
			if (nPos > 0) {
				nIndex = number(substr(cKey, nPos + 1, len(cKey) - nPos - 1))
				cKey = left(cKey, nPos - 1)
			}
		}

		// Find the key in the current table
		if (!is_a_toml_table(current_data)) {
			return NULL
		}

		found_item = find(current_data, cKey, 1)

		if (!found_item)  {
			return NULL
		}

		// Move to the value part
		current_data = current_data[found_item][2] 

		// If an index was specified, access that element
		if (nIndex > 0) {
			if (islist(current_data) && nIndex <= len(current_data)) {
				current_data = current_data[nIndex]
			else
				return NULL
			}
		}
	}

	return current_data
}

// Checks if a list represents a TOML table (list of [key, value] pairs)
func is_a_toml_table(list) {
	if (!islist(list)) {
		return false
	}

	if (len(list) = 0) {
		return false
	}

	for item in list {
		if (!islist(item) || len(item) != 2 || !isstring(item[1])) {
			return false
		}
	}
	return true
}