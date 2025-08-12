#include "ring.h"

/**
* Ring TOML extension
* Copyright (c) 2025, Youssef Saeed (ysdragon)
* Wrapper for tomlc17 library: https://github.com/cktan/tomlc17
*/

#include "tomlc17.h"

/* Store the last error message from a parsing operation */
static char gc_toml_last_error[200] = {0};

/* Forward declarations for the recursive conversion functions */
static void add_converted_toml_value(VM *pVM, List *pList, toml_datum_t datum);
static List *toml_table_to_ring_list(VM *pVM, toml_datum_t table_datum);
static List *toml_array_to_ring_list(VM *pVM, toml_datum_t array_datum);

/* This function is used to free the toml_result_t from Ring */
void ring_toml_free_result(void *pState, void *pPointer) {
	if (pPointer) {
		toml_result_t *pResult = (toml_result_t *)pPointer;
		toml_free(*pResult);
		ring_state_free(pState, pResult);
	}
}

/* Converts a TOML table datum to a new Ring list */
static List *toml_table_to_ring_list(VM *pVM, toml_datum_t table_datum) {
	if (table_datum.type != TOML_TABLE) return NULL;

	List *pList = ring_list_new_gc(pVM->pRingState, 0);
	for (int i = 0; i < table_datum.u.tab.size; i++) {
		/* Each entry in the Ring list is a sublist: [key, value] */
		List *pSubList = ring_list_newlist_gc(pVM->pRingState, pList);
		ring_list_addstring_gc(pVM->pRingState, pSubList, table_datum.u.tab.key[i]);
		add_converted_toml_value(pVM, pSubList, table_datum.u.tab.value[i]);
	}
	return pList;
}

/* Converts a TOML array datum to a new Ring list */
static List *toml_array_to_ring_list(VM *pVM, toml_datum_t array_datum) {
	if (array_datum.type != TOML_ARRAY) return NULL;

	List *pList = ring_list_new_gc(pVM->pRingState, 0);
	for (int i = 0; i < array_datum.u.arr.size; i++) {
		add_converted_toml_value(pVM, pList, array_datum.u.arr.elem[i]);
	}
	return pList;
}

/*
**  The main recursive conversion helper.
**  It takes a TOML datum and adds its Ring representation to the given Ring list.
*/
static void add_converted_toml_value(VM *pVM, List *pList, toml_datum_t datum) {
	char buffer[128];
	List *pSourceList;
	List *pDestList;

	switch (datum.type) {
		case TOML_STRING:
			ring_list_addstring2_gc(pVM->pRingState, pList, datum.u.str.ptr, datum.u.str.len);
			break;
		case TOML_INT64:
			ring_list_adddouble_gc(pVM->pRingState, pList, (double)datum.u.int64);
			break;
		case TOML_FP64:
			ring_list_adddouble_gc(pVM->pRingState, pList, datum.u.fp64);
			break;
		case TOML_BOOLEAN:
			ring_list_adddouble_gc(pVM->pRingState, pList, (double)datum.u.boolean);
			break;
		case TOML_DATE:
			snprintf(buffer, sizeof(buffer), "%04d-%02d-%02d",
					 datum.u.ts.year, datum.u.ts.month, datum.u.ts.day);
			ring_list_addstring_gc(pVM->pRingState, pList, buffer);
			break;
		case TOML_TIME:
			if (datum.u.ts.usec > 0)
				snprintf(buffer, sizeof(buffer), "%02d:%02d:%02d.%06d",
						datum.u.ts.hour, datum.u.ts.minute, datum.u.ts.second, datum.u.ts.usec);
			else
				snprintf(buffer, sizeof(buffer), "%02d:%02d:%02d",
						datum.u.ts.hour, datum.u.ts.minute, datum.u.ts.second);
			ring_list_addstring_gc(pVM->pRingState, pList, buffer);
			break;
		case TOML_DATETIME:
			if (datum.u.ts.usec > 0)
				snprintf(buffer, sizeof(buffer), "%04d-%02d-%02dT%02d:%02d:%02d.%06d",
						datum.u.ts.year, datum.u.ts.month, datum.u.ts.day,
						datum.u.ts.hour, datum.u.ts.minute, datum.u.ts.second, datum.u.ts.usec);
			else
				snprintf(buffer, sizeof(buffer), "%04d-%02d-%02dT%02d:%02d:%02d",
						datum.u.ts.year, datum.u.ts.month, datum.u.ts.day,
						datum.u.ts.hour, datum.u.ts.minute, datum.u.ts.second);
			ring_list_addstring_gc(pVM->pRingState, pList, buffer);
			break;
		case TOML_DATETIMETZ:
			{
				char sign = datum.u.ts.tz < 0 ? '-' : '+';
				int tz_hour = abs(datum.u.ts.tz) / 60;
				int tz_min = abs(datum.u.ts.tz) % 60;
				if (datum.u.ts.usec > 0)
					snprintf(buffer, sizeof(buffer), "%04d-%02d-%02dT%02d:%02d:%02d.%06d%c%02d:%02d",
							datum.u.ts.year, datum.u.ts.month, datum.u.ts.day,
							datum.u.ts.hour, datum.u.ts.minute, datum.u.ts.second, datum.u.ts.usec,
							sign, tz_hour, tz_min);
				else
					snprintf(buffer, sizeof(buffer), "%04d-%02d-%02dT%02d:%02d:%02d%c%02d:%02d",
							datum.u.ts.year, datum.u.ts.month, datum.u.ts.day,
							datum.u.ts.hour, datum.u.ts.minute, datum.u.ts.second,
							sign, tz_hour, tz_min);
				ring_list_addstring_gc(pVM->pRingState, pList, buffer);
			}
			break;
		case TOML_ARRAY:
			pSourceList = toml_array_to_ring_list(pVM, datum);
			pDestList = ring_list_newlist_gc(pVM->pRingState, pList);
			ring_list_copy_gc(pVM->pRingState, pDestList, pSourceList);
			ring_list_delete_gc(pVM->pRingState, pSourceList);
			break;
		case TOML_TABLE:
			pSourceList = toml_table_to_ring_list(pVM, datum);
			pDestList = ring_list_newlist_gc(pVM->pRingState, pList);
			ring_list_copy_gc(pVM->pRingState, pDestList, pSourceList);
			ring_list_delete_gc(pVM->pRingState, pSourceList);
			break;
		case TOML_UNKNOWN:
		default:
			/* Add a nil representation (empty string in this context) */
			ring_list_addstring_gc(pVM->pRingState, pList, "");
			break;
	}
}

RING_FUNC(ring_toml_parse)
{
	if (RING_API_PARACOUNT != 1 || !RING_API_ISSTRING(1)) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	
	const char *toml_string = RING_API_GETSTRING(1);
	int len = RING_API_GETSTRINGSIZE(1);

	toml_result_t result = toml_parse(toml_string, len);

	if (!result.ok) {
		strncpy(gc_toml_last_error, result.errmsg, sizeof(gc_toml_last_error) - 1);
		toml_free(result);
		return;
	}
	
	toml_result_t *pResult = (toml_result_t *)ring_state_malloc(((VM*)pPointer)->pRingState, sizeof(toml_result_t));
	if (pResult) {
		*pResult = result;
		RING_API_RETMANAGEDCPOINTER(pResult, "TOML_RESULT", ring_toml_free_result);
	} else {
		toml_free(result);
		RING_API_ERROR(RING_OOM);
	}
}

RING_FUNC(ring_toml_parse_file)
{
	if (RING_API_PARACOUNT != 1 || !RING_API_ISSTRING(1)) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	const char *filename = RING_API_GETSTRING(1);
	
	toml_result_t result = toml_parse_file_ex(filename);

	if (!result.ok) {
		strncpy(gc_toml_last_error, result.errmsg, sizeof(gc_toml_last_error) - 1);
		toml_free(result);
		return;
	}
	
	toml_result_t *pResult = (toml_result_t *)ring_state_malloc(((VM*)pPointer)->pRingState, sizeof(toml_result_t));
	if (pResult) {
		*pResult = result;
		RING_API_RETMANAGEDCPOINTER(pResult, "TOML_RESULT", ring_toml_free_result);
	} else {
		toml_free(result);
		RING_API_ERROR(RING_OOM);
	}
}

RING_FUNC(ring_toml_get_ex)
{
	if (RING_API_PARACOUNT != 2 || !RING_API_ISCPOINTER(1) || !RING_API_ISSTRING(2)) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	toml_result_t *pResult = (toml_result_t *)RING_API_GETCPOINTER(1, "TOML_RESULT");
	if (!pResult) {
		RING_API_ERROR(RING_API_NULLPOINTER);
		return;
	}

	const char *key = RING_API_GETSTRING(2);
	
	toml_datum_t datum = toml_get(pResult->toptab, key);
	
	if (datum.type == TOML_UNKNOWN) {
		return;
	}
	
	List* pValueList = ring_list_new_gc(((VM*)pPointer)->pRingState, 0);
	add_converted_toml_value((VM*)pPointer, pValueList, datum);

	if (ring_list_isstring(pValueList, 1)) {
		RING_API_RETSTRING2(ring_list_getstring(pValueList, 1), ring_list_getstringsize(pValueList, 1));
	} else if (ring_list_isnumber(pValueList, 1)) {
		RING_API_RETNUMBER(ring_list_getdouble(pValueList, 1));
	} else if (ring_list_islist(pValueList, 1)) {
		RING_API_RETLIST(ring_list_getlist(pValueList, 1));
	}

	ring_list_delete_gc(((VM*)pPointer)->pRingState, pValueList);
}

RING_FUNC(ring_toml2list)
{
	if (RING_API_PARACOUNT != 1 || !RING_API_ISCPOINTER(1)) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	toml_result_t *pResult = (toml_result_t *)RING_API_GETCPOINTER(1, "TOML_RESULT");
	if (!pResult) {
		RING_API_ERROR(RING_API_NULLPOINTER);
		return;
	}
	
	if (pResult->toptab.type != TOML_TABLE) {
		return;
	}

	List *pList = toml_table_to_ring_list((VM*)pPointer, pResult->toptab);
	RING_API_RETLIST(pList);
}

RING_FUNC(ring_toml_type)
{
	if (RING_API_PARACOUNT != 2 || !RING_API_ISCPOINTER(1) || !RING_API_ISSTRING(2)) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	toml_result_t *pResult = (toml_result_t *)RING_API_GETCPOINTER(1, "TOML_RESULT");
	if (!pResult) {
		RING_API_ERROR(RING_API_NULLPOINTER);
		return;
	}

	const char *key = RING_API_GETSTRING(2);
	
	toml_datum_t datum = toml_get(pResult->toptab, key);
	
	RING_API_RETNUMBER(datum.type);
}

RING_FUNC(ring_toml_lasterror)
{
	if (RING_API_PARACOUNT != 0) {
		RING_API_ERROR(RING_API_BADPARACOUNT);
		return;
	}
	RING_API_RETSTRING(gc_toml_last_error);
}

RING_FUNC(ring_get_toml_unknown)
{
	RING_API_RETNUMBER(TOML_UNKNOWN);
}

RING_FUNC(ring_get_toml_string)
{
	RING_API_RETNUMBER(TOML_STRING);
}

RING_FUNC(ring_get_toml_int64)
{
	RING_API_RETNUMBER(TOML_INT64);
}

RING_FUNC(ring_get_toml_fp64)
{
	RING_API_RETNUMBER(TOML_FP64);
}

RING_FUNC(ring_get_toml_boolean)
{
	RING_API_RETNUMBER(TOML_BOOLEAN);
}

RING_FUNC(ring_get_toml_date)
{
	RING_API_RETNUMBER(TOML_DATE);
}

RING_FUNC(ring_get_toml_time)
{
	RING_API_RETNUMBER(TOML_TIME);
}

RING_FUNC(ring_get_toml_datetime)
{
	RING_API_RETNUMBER(TOML_DATETIME);
}

RING_FUNC(ring_get_toml_datetimetz)
{
	RING_API_RETNUMBER(TOML_DATETIMETZ);
}

RING_FUNC(ring_get_toml_array)
{
	RING_API_RETNUMBER(TOML_ARRAY);
}

RING_FUNC(ring_get_toml_table)
{
	RING_API_RETNUMBER(TOML_TABLE);
}

RING_LIBINIT
{
	RING_API_REGISTER("toml_parse",ring_toml_parse);
	RING_API_REGISTER("toml_parse_file",ring_toml_parse_file);
	RING_API_REGISTER("toml_get_ex",ring_toml_get_ex);
	RING_API_REGISTER("toml2list",ring_toml2list);
	RING_API_REGISTER("toml_type",ring_toml_type);
	RING_API_REGISTER("toml_lasterror",ring_toml_lasterror);
	RING_API_REGISTER("get_toml_unknown",ring_get_toml_unknown);
	RING_API_REGISTER("get_toml_string",ring_get_toml_string);
	RING_API_REGISTER("get_toml_int64",ring_get_toml_int64);
	RING_API_REGISTER("get_toml_fp64",ring_get_toml_fp64);
	RING_API_REGISTER("get_toml_boolean",ring_get_toml_boolean);
	RING_API_REGISTER("get_toml_date",ring_get_toml_date);
	RING_API_REGISTER("get_toml_time",ring_get_toml_time);
	RING_API_REGISTER("get_toml_datetime",ring_get_toml_datetime);
	RING_API_REGISTER("get_toml_datetimetz",ring_get_toml_datetimetz);
	RING_API_REGISTER("get_toml_array",ring_get_toml_array);
	RING_API_REGISTER("get_toml_table",ring_get_toml_table);
}
