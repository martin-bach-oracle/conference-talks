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

export function getThings(
    options = {
        skip: 0,
        limit: 0,
        searchTerm: '%'
    }
)
{
    // pagination: limit the number of pages
    if (options.limit !== undefined) {

        if (! Number.isNaN(options.limit)) {
            
            options.limit = Number.parseInt(options.limit);
        } else {

            return {
                error: `limit ${options.limit} is not a number`
            }
        }

    } else {

        options.limit = 0;
    }

    // pagination: define an offset (called `skip` in SODA)
    if (options.skip !== undefined) {

        if (! Number.isNaN(options.skip)) {
            
            options.skip = Number.parseInt(options.skip);
        } else {
            
            return {
                error: `limit ${options.skip} is not a number`
            }
        }

    } else {

        options.skip = 0;
    }

    // the $like QBE requires the search term to be surrounded with percent signs
    if (options.searchTerm !== undefined) {

        options.searchTerm = `%${options.searchTerm}%`;
    } else {

        options.searchTerm = '%';
    }

    // return an error in case the duality view cannot be opened
	const collection = soda.openCollection("THINGS");
	if (collection === null) {

		return {
            error: 'unable to access the THINGS duality view. Has it been created?'
        }
	}
		
    const qbe = {
        $or: [
            { name:        { $upper: { $like: options.searchTerm.toUpperCase() } } },
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

export function getThing(id) {

    // check if the ID is valid
    if (id === undefined || Number.isNaN(id)) {
        return {
            error: 'please provide a valid numeric ID to this API call'
        }
    }

    // return an error in case the duality view cannot be opened
	const collection = soda.openCollection("THINGS");
	if (collection === null) {

		return {
            error: 'unable to access the THINGS duality view. Has it been created?'
        }
	}
	
    try {
        const doc = collection
            .find()
            .filter( { "_id": { "$eq": Number.parseInt(id) } } )
            .getOne();
        
        const content = doc.getContent();
        content._metadata.etag = toHexString(content._metadata.etag);
        content._metadata.asof = toHexString(content._metadata.asof);

        const items = [
            content
        ];

        return items;
    } catch (err) {
        return {
            error: `cannot find a document with id ${id} (${err})`
        }
    }
}

export function postThing(thing) {
	return {
		todo: "implement me: postThing()",
	};
}

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
