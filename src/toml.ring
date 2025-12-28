/*
 *  toml_get(pTomlData, cPath)
 *  Finds a value in the parsed TOML data using a dot-separated path.
 *  Examples: "database.ip", "products[1].name", "servers.alpha.dc"
 */
func toml_get(data, path) {
	if isNull(data) { return NULL }
	
	// Validate path
	if (!isstring(path) || len(trim(path)) = 0) { return NULL }
	
	// Check for invalid path patterns
	if (substr(path, "..") > 0) { return NULL }
	if (left(path, 1) = ".") { return NULL }
	if (right(path, 1) = ".") { return NULL }
	
	aParts = split(path, ".")
	current_data = toml2list(data)
	
	for part in aParts {
		// Skip empty parts
		if (len(trim(part)) = 0) { return NULL }
		
		cKey = part
		nIndex = 0

		// Check for array index like "ports[1]"
		if (right(cKey, 1) = "]") {
			nPos = substr(cKey, "[")
			if (nPos > 0) {
				cIndexStr = substr(cKey, nPos + 1, len(cKey) - nPos - 1)
				if (len(cIndexStr) = 0) { return NULL }
				nIndex = number(cIndexStr)
				if (nIndex < 1) { return NULL }
				cKey = left(cKey, nPos - 1)
			}
		}

		// Find the key in the current table
		if (!is_a_toml_table(current_data)) {
			return NULL
		}

		found_item = find(current_data, cKey, 1)

		if (!found_item) {
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

/*
 *  toml_exists(pTomlData, cPath)
 *  Checks if a key exists at the given path without retrieving the value.
 *  Returns true if the path exists, false otherwise.
 */
func toml_exists(data, path) {
	return !isNull(toml_get(data, path))
}

/*
 *  toml_keys(pTomlData, cPath)
 *  Returns a list of keys at the given path.
 *  If cPath is empty or NULL, returns top-level keys.
 *  Returns NULL if path doesn't exist or doesn't point to a table.
 */
func toml_keys(data, path) {
	if (isNull(data)) { return NULL }
	
	// Get the table at the path (or root if path is empty)
	if (isNull(path) || len(trim(path)) = 0) {
		table_data = toml2list(data)
	else
		table_data = toml_get(data, path)
	}
	
	// Check if it's a valid table
	if (!is_a_toml_table(table_data)) {
		return NULL
	}
	
	// Extract keys
	aKeys = []
	for item in table_data {
		add(aKeys, item[1])
	}
	
	return aKeys
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