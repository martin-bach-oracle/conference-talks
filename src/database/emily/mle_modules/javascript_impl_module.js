 
// this is what the input must look like _for inserts. An ID for
// the new action item cannot be provided, it is auto-generated via
// an identity column.
const actionItemInsertSchema = {
    $schema: 'https://json-schema.org/draft/2019-09/schema',
    type: 'object',
    required: ['actionName', 'status', 'team'],
    additionalProperties: false,
    properties: {
        actionName: { type: 'string', minLength: 10 },
        status: { type: 'string', enum: ['OPEN', 'COMPLETE'] },
        team: {
            type: 'array',
            minItems: 1,

            // At most one LEAD in the team array
            contains: {
                type: 'object',
                properties: { role: { const: 'LEAD' } },
                required: ['role'],
            },
            maxContains: 1,

            items: {
                type: 'object',
                required: ['role', 'staffName', 'staffId'],
                additionalProperties: false,
                properties: {
                    role: { type: 'string', enum: ['LEAD', 'MEMBER'] },
                    staffName: { type: 'string', minLength: 5 },
                    staffId: { type: 'integer', minimum: 1 },
                },
            },
        },
    },
};

// this is what the input must look like _for updates. The _id
// is now required
const actionItemUpdateSchema = {
    $schema: 'https://json-schema.org/draft/2019-09/schema',
    type: 'object',
    required: ['actionName', 'status', 'team', 'actionId'],
    additionalProperties: false,
    properties: {
        actionId: { type: 'integer', minimum: 1 },
        actionName: { type: 'string', minLength: 10 },
        status: { type: 'string', enum: ['OPEN', 'COMPLETE'] },
        team: {
            type: 'array',
            minItems: 1,

            // At most one LEAD in the team array
            contains: {
                type: 'object',
                properties: { role: { const: 'LEAD' } },
                required: ['role'],
            },
            maxContains: 1,

            items: {
                type: 'object',
                required: ['role', 'staffName', 'staffId', 'assignmentId'],
                additionalProperties: false,
                properties: {
                    role: { type: 'string', enum: ['LEAD', 'MEMBER'] },
                    staffName: { type: 'string', minLength: 5 },
                    staffId: { type: 'integer', minimum: 1 },
                    assignmentId: { type: 'integer', minimum: 1 },
                },
            },
        },
    },
};

/**
 * Helper function to make sure that limit and offset are numbers and not
 * bogus characters. Must ensure they aren't '10abc' because that would 
 * not faze Number.parseInt()
 * 
 * @param {string} input the string to validate
 * @param {number} lowerBound lowest possible value for input
 * @param {number} upperBound highest possible value for input
 * @returns {number} -1 if validation failed, otherwise the parsed number
 */
function validateNumber(input, lowerBound, upperBound) {

    // that's kind of obvious but nevertheless important to validate
    if (lowerBound > upperBound) {
        throw new Error (`upper bound ${upperBound} cannot be smaller than lower bound ${lowerBound} in pagination query`);
    }

    // check if the input string contains non-numeric characters
    if (!/^\d+$/.test(input)) {
        return -1;
    }

    // now parse the string and check if it's within the bounds
    // provided to the function
    const parsedNumber = Number.parseInt(
        input,
        10,
    );

    if (
        parsedNumber < lowerBound ||
        parsedNumber > upperBound ||
        !Number.isInteger(parsedNumber) 
    )
        return -1;
    else
        return parsedNumber;

}

/**
 * Get a single action item - handler. This function is invoked by ORDS
 *
 * The actual work is done by getActionItem() below.
 *
 * @param {object} req the request object, as provided by ORDS
 * @param {object} resp the corresponding response object
 */
export function getActionItemHandler(req, resp) {
    resp.content_type('application/json');

    const rawId = req.uri_parameters.id;
    const saneId = Number.parseInt(rawId, 10);
    if (!/^\d+$/.test(rawId) || !Number.isInteger(saneId)) {
        resp.status(400);
        resp.json({
            message: 'ID must be numeric',
            details: `${rawId} is not a number`
        });
        return;
    } 

    try {
        // retrieve the ID to look up from the URI
        const input = {
            id: saneId,
        };

        const data = getActionItem(input);

        if (!data) {
            // return a Not Found error in case there is no such ID
            resp.status(404);
        } else {
            // this is the happy path: everything found
            resp.status(200);
            resp.content_type('application/json');
            resp.json(data);
        }
    } catch (err) {
        // this was ... unexpected. And shouldn't happen
        resp.status(500);
        resp.json({
            message: 'an unexpected error occurred in getActionItemHandler()',
            details: err.message,
        });
    }
}

/**
 * Get an action item from the database. Parameters have been parsed/sanitised
 * by the invoking function
 *
 * @param {object} params the object containing all input parameters
 * @param {number} params.id the action item ID to retrieve
 * @returns {object|null} all details pertaining to this action item, or null
 * if no row was found
 */
function getActionItem({ id }) {
    console.log(`fetching details about action item ${id}`);

    const result = session.execute(
        `select 
            json{
                'actionId':      a.id,
                'actionName':    a.name,
                'status':        a.status,
                'team' value (
                    select json_arrayagg(
                        json{
                            'assignmentId': tm.id,
                            'role':         tm.role,
                            'staffId':      tm.user_id,
                            'staffName':    s.name
                        }
                        order by tm.role desc, s.name
                    )
                    from
                        action_item_team_members tm
                        join staff s on s.id = tm.user_id
                    where
                        tm.action_id = a.id
                )
            } as ACTION_ITEMS_JSON
        from
            action_items a
        where
            a.id = :id`,
        [id],
    );

    // the equivalent of a NO_DATA_FOUND exception. Returning null
    // to allow the caller to return a HTTP 404 error
    if (result.rows.length === 0) {
        return null;
    }

    console.log(
        `found some data: ${JSON.stringify(result.rows[0].ACTION_ITEMS_JSON)}`,
    );

    // we found some data!
    return result.rows[0].ACTION_ITEMS_JSON;
}


/**
 * Update a single action item - handler. This function is invoked by ORDS.
 *
 * Input validation via JSON Schema, same approach as with the insert (POST)
 * handler.
 *
 * @param {object} req the request object, as provided by ORDS
 * @param {object} resp the corresponding response object
 * @returns {object} the updated action item
 */
export function updateActionItemHandler(req, resp) {
    resp.content_type('application/json');

    // let's validate the submitted JSON first. This code block uses
    // the PL/SQL Foreign Function Interface.
    const dbmsJSONSchema = plsffi.resolvePackage('DBMS_JSON_SCHEMA');
    const result = plsffi.arg();
    const errors = plsffi.arg();
    dbmsJSONSchema.is_valid(req.body, actionItemUpdateSchema, result, errors);

    if (!result.val) {
        resp.status(400);
        resp.json(errors.val);
        return;
    }

    const actionItem = req.body;

    console.log('update: incoming data successfully validated');

    // update the action item after successful JSON validation
    // still might fail due to invalid team member names etc.
    // This is a 2 staged process:
    // 1. update the action item itself
    // 2. associate team members with the action item.
    // for the sake of simplicity errors thrown by the database such
    // as constraint violations, will be passed straight back to the
    // caller
    try {
        let result;

        // update the action item
        result = session.execute(
            'update action_items set name = :name, status = :status where id = :id',
            {
                name: {
                    dir: oracledb.BIND_IN,
                    val: actionItem.actionName,
                },
                status: {
                    dir: oracledb.BIND_IN,
                    val: actionItem.status,
                },
                id: {
                    dir: oracledb.BIND_IN,
                    val: actionItem.actionId,
                },
            },
        );

        if (result.rowsAffected !== 1) {
          resp.status(400);
          resp.json({
              message:
                  `no action item found`,
              details: `action item with id ${actionItem.actionId} not present in the database`,
          });
        }

        console.log('action_items successfully updated');

        // now modify the action_item_team_members table. This merge statement
        // uses the action item's team array, normalised to look like a regular
        // table. The inline view is the source, whereas action_item_team_members
        // is the target. To keep it simple, errors such as constraint violations,
        // are passed straight back from the database.
        result = session.execute(
            `merge into action_item_team_members t
            using (
                select
                    id,
                    action_id,
                    user_id,
                    role
                from
                    json_table(
                        :actionItem,
                        '$'
                        columns (
                            action_id path '$.actionId',
                            nested path '$.team[*]' columns (
                                id number path '$.assignmentId',
                                role varchar2(20) path '$.role',
                                user_id number path '$.staffId'
                            )
                        )
                    )
            ) s
            on (s.id = t.id)
            when matched then
                update set
                    t.action_id = s.action_id,
                    t.user_id = s.user_id,
                    t.role = s.role
            when not matched then
                insert (action_id, user_id, role)
                values (s.action_id, s.user_id, s.role)`,
            {
                actionItem: {
                    type: oracledb.DB_TYPE_JSON,
                    val: actionItem,
                    dir: oracledb.BIND_IN,
                },
            },
        );

        console.log(`merge completed. ${result.rowsAffected} rows updated`);

        // looks like everything went fine, let the user know
        const data = getActionItem({ id: actionItem.actionId });
        resp.status(200);
        resp.json(data);
    } catch (err) {
        resp.status(500);
        resp.json({
            message:
                'an unexpected error occurred in updateActionItemHandler()',
            details: err.message,
        });
    }
}

/**
 * Create a new action item - handler. This function is invoked by ORDS.
 *
 * Input validation via JSON Schema, same approach as with the update (PUT)
 * handler.
 *
 * @param {object} req the request object, as provided by ORDS
 * @param {object} resp the corresponding response object
 * @returns {object} the updated action item
 */
export function createActionItemHandler(req, resp) {
    resp.content_type('application/json');

    // let's validate the submitted JSON first. This code block uses
    // the PL/SQL Foreign Function Interface.
    const dbmsJSONSchema = plsffi.resolvePackage('DBMS_JSON_SCHEMA');
    const result = plsffi.arg();
    const errors = plsffi.arg();
    dbmsJSONSchema.is_valid(req.body, actionItemInsertSchema, result, errors);

    if (!result.val) {
        resp.status(400);
        resp.json(errors.val);
        return;
    }

    const actionItem = req.body;

    // create the action item after the JSON validation succeeded
    // still might fail due to invalid team member names etc.
    // This is a 2 staged process:
    // 1. create the action item itself
    // 2. associate team members with the action item.
    // for the sake of simplicity errors thrown by the database such
    // as constraint violations, will be passed straight back to the
    // caller
    try {
        let result;

        // IDs in these tables are generated by identity columns. Their
        // values must be fetched using the returning into clause.
        result = session.execute(
            `insert into action_items (name, status) values (:name, :status)
             returning id into :id`,
            {
                name: {
                    dir: oracledb.BIND_IN,
                    val: actionItem.actionName,
                },
                status: {
                    dir: oracledb.BIND_IN,
                    val: actionItem.status,
                },
                id: {
                    dir: oracledb.BIND_OUT,
                    type: oracledb.NUMBER,
                },
            },
        );

        // this variable contains the auto-generated ID
        const id = result.outBinds.id[0];

        // since we're inserting multiple team members per action item, it makes
        // sense to use a batch update (`insertMany()`)
        const sql = `insert into action_item_team_members(
                action_id, user_id, role
            ) values (
                :actionId, :userId, :role
            )`;

        const binds = actionItem.team.map((m) => ({
            actionId: id,
            userId: m.staffId,
            role: m.role,
        }));

        result = session.executeMany(sql, binds);
        if (result.rowsAffected === 0)
            throw new Error(
                `failed to associate team members with action item ${id}`,
            );

        // looks like everything went fine, let the user know
        resp.status(201);
        const data = getActionItem({ id: id });
        resp.json(data);
    } catch (err) {
        resp.status(500);
        resp.json({
            message:
                'an unexpected error occurred in createActionItemHandler()',
            details: err.message,
        });
    }
}

/**
 * Delete an action item - handler. This function is invoked by ORDS.
 *
 * @param {object} req the request object, as provided by ORDS
 * @param {object} resp the corresponding response object
 */
export function deleteActionItemHandler(req, resp) {

    const rawId = req.uri_parameters.id;
    const saneId = Number.parseInt(rawId, 10);
    if (!/^\d+$/.test(rawId) || !Number.isInteger(saneId)) {
        resp.status(400);
        resp.json({
            message: 'ID must be numeric',
            details: `${rawId} is not a number`
        });
        return;
    } 

    try {
        let result = session.execute(
            'delete from action_item_team_members where action_id = :id',
            [ saneId ],
        );

        result = session.execute('delete from action_items where id = :id', [
            saneId,
        ]);

        console.log(`deleted ${result.rowsAffected} rows`);

        if (result.rowsAffected === 0) {
            // no data found -> HTTP 404
            resp.status(404);
        } else {

            resp.status(204);
        }
    } catch (err) {
        resp.content_type('application/json');
        resp.status(500);
        resp.json({
            message:
                'an unexpected error occurred in deleteActionItemHandler()',
            details: err.message,
        });
    }
}
