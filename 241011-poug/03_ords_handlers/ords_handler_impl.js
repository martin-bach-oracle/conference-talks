/**
 * implementation of the REST operations defined in ords_handler.sql.
 *
 * GET
 *   - get a specific thing by ID
 *   - get all things
 * POST
 *   - create a new thing (= insert)
 * PUT
 *   - update an existing thing (= update)
 * DELETE
 *   - delete a thing by ID
 */

import * as businessLogic from 'demo';
import * as utils from 'utils';

/**
 * GET handler (select)
 * Query the relational duality view to return all rows, or a subset. It is possible
 * to optionally provide a search string, offset, and limit clause. Uses the SODA
 * noSQL document API to interact with the database. If no data is found, an empty
 * items array is returned. If errors occur, they will be reported, too.
 *
 * TODO:
 * - use getDocuments() instead of document cursor
 *
 * @param {object} options optional search string, offset, and limit
 * @returns {object} The result set; empty array if no data found; error if one occurred
 */
export function getThings(options) {
	const defaults = {
		skip: 0,
		limit: 0,
		searchTerm: "%",
	};

	// biome-ignore lint: make sure options are properly configured without any undefined ones
	options = utils.mergeOptions(defaults, options);

	// pagination: limit the number of pages
	if (options.limit !== undefined) {
		if (!Number.isNaN(options.limit)) {
			options.limit = Number.parseInt(options.limit);
		} else {
			return {
				error: `limit ${options.limit} is not a number`,
			};
		}
	} else {
		options.limit = 0;
	}

	// pagination: define an offset (called `skip` in SODA)
	if (options.skip !== undefined) {
		if (!Number.isNaN(options.skip)) {
			options.skip = Number.parseInt(options.skip);
		} else {
			return {
				error: `limit ${options.skip} is not a number`,
			};
		}
	} else {
		options.skip = 0;
	}

	// the $like QBE requires the search term to be surrounded with percent signs
	if (options.searchTerm !== undefined) {
		options.searchTerm = `%${options.searchTerm}%`;
	} else {
		options.searchTerm = "%";
	}

	// return an error in case the duality view cannot be opened
	const collection = soda.openCollection("THINGS");
	if (collection === null) {
		return {
			error: "unable to access the THINGS duality view. Has it been created?",
		};
	}

	const qbe = {
		$or: [
			{ name: { $upper: { $like: options.searchTerm.toUpperCase() } } },
			{ description: { $upper: { $like: options.searchTerm.toUpperCase() } } },
		],
	};

	options.qbe = qbe;

	const docCursor = collection
		.find()
		.filter(qbe)
		.skip(options.skip)
		.limit(options.limit)
		.getCursor();

	let doc;
	const items = [];
	// biome-ignore lint/suspicious/noAssignInExpressions: workaround until the iterable interface is implemented
	while ((doc = docCursor.getNext())) {
		const content = doc.getContent();
		content._metadata.etag = toHexString(content._metadata.etag);
		content._metadata.asof = toHexString(content._metadata.asof);

		items.push(content);
	}

	docCursor.close();

	return { items };
}

/**
 * GET handler (select)
 * Query the duality view by primary key. Returns the result set or an empty items array
 * in case no data is found. Errors are returned if appropriate
 *
 * @param {string} id the table/duality view's primary key
 * @returns {object} The result set; empty array if no data found; error if one occurred
 */
export function getThing(id) {
	// check if the ID is valid
	if (id === undefined || Number.isNaN(id)) {
		return {
			error: "please provide a valid numeric ID to this API call",
		};
	}

	// return an error in case the duality view cannot be opened
	const collection = soda.openCollection("THINGS");
	if (collection === null) {
		return {
			error: "unable to access the THINGS duality view. Has it been created?",
		};
	}

	try {
		const doc = collection
			.find()
			.filter({ _id: { $eq: Number.parseInt(id) } })
			.getOne();

		const content = doc.getContent();
		content._metadata.etag = toHexString(content._metadata.etag);
		content._metadata.asof = toHexString(content._metadata.asof);

		const items = [content];

		return { items };
	} catch (err) {
		return {
			items: [],
		};
	}
}

/**
 * POST handler (insert)
 * Update a thing after verification
 *
 * @param {object} thing - an object representing the updated thing
 * @returns {boolean} an object containing the status and an error message (if any)
 */
export function postThing(thing) {

	// consolidate multiple entries for stock in the same warehouse into one
	// before the validation begins
	const tracker = new Map();
	thing.stock = thing.stock.reduce((acc, value) => {
		if (tracker.has(value.warehouse)) {
			acc[tracker.get(value.warehouse)].quantity += value.quantity;
		} else {
			tracker.set(value.warehouse, acc.push(value) - 1);
		}
		return acc;
	}, []);

	// make sure the new thing adheres to our rules about things

	const status = checkRequiredFields(thing);
	if (!status.success) {
		return {
			success: false,
			error: `failed to insert a thing: ${status.error}`,
		};
	}

	if (!checkAtLeastOneWarehouse(thing.stock)) {
		return {
			success: false,
			error: "failed to insert a thing: all stock require at least 1 warehouse",
		};
	}

	if (!businessLogic.validateAvailable(thing.available.toString())) {
		return {
			success: false,
			error: "failed to insert a thing: failed availability verification",
		};
	}

	if (!businessLogic.validatePrice(thing.price.toString())) {
		return {
			success: false,
			error: "failed to insert a thing: price must be in range [0.1;100000[",
		};
	}

	if (!validateWareHouseAndQuantity(thing.stock)) {
		return {
			success: false,
			error: "failed to insert a thing: quantities must be whole integers > 0",
		};
	}

	thing.price = businessLogic.closest99Cent(thing.price.toString());

	// should be good - new let's insert the thing
	try {
		const collection = soda.openCollection("THINGS");
		if (collection === null) {
			return {
				success: false,
				error: "unable to access the THINGS duality view. Has it been created?",
			};
		}

		collection.insertOne(thing);
		session.commit();

	} catch (err) {
		return {
			success: false,
			error: `failed to insert a thing: ${err}`,
		};
	}

	return {
		success: true,
		error: ''
	}
}

/**
 * PUT handler (update)
 * @param {} id
 * @param {*} newThing
 * @returns
 */
export function putThing(id, newThing) {
	return {
		todo: "implement me: putThing()",
	};
}

export function deleteThing(id) {
	return {
		todo: "implement me: deleteThing()",
	};
}

// ---------------------------------------------------------------------- auxiliary functions

/**
 * Convert an ETAG or ASOF value in MLE SODA to match the output in node-oracledb
 * @param {UInt8Arry} byteArray - the raw etag | asof values to be converted
 * @returns {string} the converted etag | asof value matching the database's output
 */
export function toHexString(byteArray) {
	return Array.from(byteArray, (byte) => {
		// biome-ignore lint: this is a workaround until MLE supports node's Buffer API
		return ("0" + (byte & 0xff).toString(16)).slice(-2);
	}).join("");
}

/**
 * Checks if an object is empty, e.g. has no keys. This function is more performant
 * than testing object.keys(): O(1) vs O(n) :)
 * @param {object} obj - the object to check
 * @returns {boolean} true if the object is empty, false otherwise
 */
export function isEmpty(obj) {
	for (const prop in obj) {
		if (Object.hasOwn(obj, prop)) {
			return false;
		}
	}
	return true;
}

/**
 * Check if the required fields for a given thing are present prior to inserting
 * or updating
 *
 * @param {object} thing - a thing
 * @returns {object} a status object containing status and an error should one have occurred
 */
function checkRequiredFields(thing) {
	if (thing === undefined) {
		return {
			success: false,
			error: "thing is undefined",
		};
	}

	let missingField = "none";

	if (thing.price === undefined) {
		missingField = "price";
	} else if (thing.available === undefined) {
		missingField = "available";
	} else if (thing.name === undefined) {
		missingField = "name";
	} else if (thing.category === undefined) {
		missingField = "category";
	}

	switch (missingField) {
		case "none":
			return {
				success: true,
				error: "none",
			};
		default:
			return {
				success: false,
				error: `missing field (${missingField} detected)`,
			};
	}
}

/**
 * Ensure there is a warehouse associated with the stock. Name has been kept to stay in line
 * with the original sample code. Could also have been named checkForWarehouses
 *
 * @param {object} stock - stock to be checked
 * @returns true if each stock has a warehouse, false otherwise
 */
function checkAtLeastOneWarehouse(stock) {
	if (stock === undefined || !Array.isArray(stock)) {
		return false;
	}

	return stock.every((element) => {
		return element.warehouse !== undefined && element.warehouse.length !== 0;
	});
}

/**
 * Ensure there are no negative or fractionaly quantities associated with the stock.
 * Warehouse validation, present in the PL/SQL example is not needed here.
 *
 * @param {object} stock - all the stock of a given thing
 * @returns {boolean} whether or not the validation was successful
 */
function validateWareHouseAndQuantity(stock) {
	if (stock === undefined || !Array.isArray(stock)) {
		return false;
	}

	return stock.every((element) => {
		return businessLogic.validateQuantity(element.quantity.toString());
	});
}
