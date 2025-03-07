--liquibase formatted sql
--changeset mcb:r3-01 failonerror:true labels:r3 endDelimiter:/ stripComments:false

create or replace mle module ords_handler_impl_module
language javascript
version '1.0.0'
as

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

import * as businessLogic from "demo";
import * as utils from "utils";

/**
 * GET handler (select)
 * 
 * Query the relational duality view to return all rows, or a subset. It is possible
 * to optionally provide a search string, offset, and limit clause. Uses the SODA
 * noSQL document API to interact with the database. If no data is found, an empty
 * items array is returned. If errors occur, they will be reported, too.
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

	// biome-ignore lint: make sure options are properly configured
	options = utils.mergeOptions(defaults, options);

	// pagination: limit the number of pages
	if (!Number.isNaN(options.limit)) {
		options.limit = Number.parseInt(options.limit);
	} else {
		return {
			error: `limit ${options.limit} is not a number`,
		};
	}

	// pagination: define an offset (called `skip` in SODA)
	if (!Number.isNaN(options.skip)) {
		options.skip = Number.parseInt(options.skip);
	} else {
		return {
			error: `limit ${options.skip} is not a number`,
		};
	}

	// the $like QBE requires the search term to be surrounded by percent signs
	if (options.searchTerm !== '%') {
		options.searchTerm = `%${options.searchTerm}%`;
	}

	// return an error in case the duality view cannot be opened
	const collection = soda.openCollection("THINGS");
	if (collection === null) {
		return {
			error: "unable to access the THINGS duality view. Has it been created?",
		};
	}

	// if the search term is defined it may either match the name or title of the
	// thing. converting name, description and search term to upper case to make
	// sure we find a match if there is one
	const qbe = {
		$or: [
			{ name: { $upper: { $like: options.searchTerm.toUpperCase() } } },
			{ description: { $upper: { $like: options.searchTerm.toUpperCase() } } },
		],
	};

	const docs = collection
		.find()
		.filter(qbe)
		.skip(options.skip)
		.limit(options.limit)
		.getDocuments();

	const items = [];
	for (const doc of docs) {
		const content = doc.getContent();
		content._metadata.etag = toHexString(content._metadata.etag);
		content._metadata.asof = toHexString(content._metadata.asof);

		items.push(content);
	}

	// return the search result the same way auto-REST would
	return { items };
}

/**
 * GET handler (select)
 * 
 * Query the duality view by primary key using SODA. Returns the result set or an
 * empty items array in case no data is found. Errors are returned if appropriate
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

		// format the ETAG and ASOF to match those returned by node-oracledb
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
 * 
 * Update a thing after verification. No need to specify the top-level _id, the
 * duality view will populate it. Reuses the same business logic as the application.
 *
 * @param {object} thing an object representing the updated thing
 * @returns {boolean} an object containing the status and an error message (if any)
 */
export function postThing(thing) {
	
	// make sure the new thing adheres to our rules about things
	const status = beforeInsertOrUpdate(thing, 'insert');
	if (! status.success) {
		return status;
	}

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
		error: undefined,
	};
}

/**
 * PUT handler (update)
 * 
 * @param {number} id the thing to update
 * @param {object} updatedThing the updated information concerning the thing
 * @returns {object} a status object containing status (boolean) and an error if necessary
 */
export function putThing(id, updatedThing) {

	if (id === undefined || Number.isNaN(id)) {
		return {
			success: false,
			error: 'please provide a valid primary key of the thing you want to update'
		};
	}

	// make sure the updated thing adheres to our rules about things
	const status = beforeInsertOrUpdate(updatedThing, 'update');
	if (! status.success) {
		return status;
	}
	
	const collection = soda.openCollection("THINGS");
	if (collection === null) {
		return {
			success: false,
			error: "unable to access the THINGS duality view. Has it been created?",
		};
	}

	// the key of the original document, which is needed for replaceOne(). SodaCollection.save()
	// is not yet available for JSON Relational Duality Views but is being worked on.
	let key;

	// get the original document in preparation of the update (need to fetch the document's key)
	try {
		const doc = collection
			.find()
			.filter({ _id: { $eq: Number.parseInt(id) } })
			.getOne();
		
		key = doc.key;
	} catch (err) {
		return {
			success: false,
			error: `could not find a thing with id ${id}`
		};
	}

	// finally, perform the update
	try {

		collection
			.find()
			.key(key)
			.replaceOne(updatedThing);
		
		session.commit();
	} catch (err) {
		return {
			success: false,
			error: `could not update thing with id ${id}: ${err}`
		}; 
	}

    return {
        success: true,
        error: undefined
    }
}

/**
 * Delete a thing from the JSON Relational Duality View
 * 
 * @param {number} id the ID of the thing to delete
 * @returns {object} an object indicating success or failure of the operation
 */
export function deleteThing(id) {

	if (id === undefined || Number.isNaN(id)) {
        return {
            success: false,
            error: "please provide the primary key of the thing to delete"
        };
    }

	const collection = soda.openCollection("THINGS");
	if (collection === null) {
		return {
			success: false,
			error: "unable to access the THINGS duality view. Has it been created?",
		};
	}

    const result = collection
        .find()
        .filter({"_id": { $eq: Number.parseInt(id) }})
        .remove();
    
    session.commit();
    
    if (result.count === 0) {
        return {
            success: false,
            error: `no thing found with an id of ${id} to delete`
        }
    }

    return {
        success: true,
        error: undefined
    }
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
 * Perform validation of a thing prior to inserting and updating. Reuses the same code
 * as the browser-based APEX application. Note that APEX treats page items as strings,
 * which is why they were validated using validatorjs. This function therefore needs
 * to cast numbers to strings prior to handing them to validatorjs.
 * 
 * @param {object} thing the thing to update or insert
 * @param {string} operation one of `insert` or `update`
 * @returns status object containing the success and optionally an error message
 */
function beforeInsertOrUpdate(thing, operation = 'update') {

    if (thing === undefined || typeof thing !== 'object') {
        return {
            success: false,
            error: 'you must provide a valid thing'
        }
    }

	// consolidate multiple entries for stock in the same warehouse into one
	// before the validation begins. This would have been done in after_insert_or_update
	// but is easier this way.
	const tracker = new Map();
	thing.stock = thing.stock.reduce((acc, value) => {
		if (tracker.has(value.warehouse)) {
			acc[tracker.get(value.warehouse)].quantity += value.quantity;
		} else {
			tracker.set(value.warehouse, acc.push(value) - 1);
		}
		return acc;
	}, []);

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

    // avoid ORA-42603 by ensuring that an _id is present for updates
    if (operation === 'update' && thing._id === undefined) {
        return {
            success: false,
            error: 'when updating a thing you must provide its _id, which is missing'
        };
    }

	if (operation === 'insert' && !businessLogic.validateAvailable(thing.available.toString())) {
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

	// validate_category() not implemented
	
	if (!validateWareHouseAndQuantity(thing.stock)) {
		return {
			success: false,
			error: "failed to insert a thing: quantities must be whole integers > 0",
		};
	}

	thing.price = businessLogic.closest99Cent(thing.price.toString());

	// adjust_missing_or_null_qty not implemented, quantities have already been vetted

    return {
        success: true,
        error: undefined
    }
}

/**
 * Check if the required fields for a given thing are present prior to inserting
 * or updating
 *
 * @param {object} thing a thing
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
				error: undefined,
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
/