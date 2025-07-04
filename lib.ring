if (isWindows()) {
    loadlib("ring_toml.dll")
elseif (isLinux() || isFreeBSD())
    loadlib("libring_toml.so")
else
    raise("Unsupported OS! You need to build the library for your OS.")
}

load "src/ring_toml.rh"
load "stdlibcore.ring"

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