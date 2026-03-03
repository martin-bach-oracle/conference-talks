
  CREATE OR REPLACE MLE MODULE "EMILY"."JAVASCRIPT_IMPL_MODULE" 
   LANGUAGE JAVASCRIPT AS 
// src/javascript/javascript_impl_module.mjs
var actionItemInsertSchema = {
  $schema: "https://json-schema.org/draft/2019-09/schema",
  type: "object",
  required: ["actionName", "status", "team"],
  additionalProperties: false,
  properties: {
    actionName: { type: "string", minLength: 10 },
    status: { type: "string", enum: ["OPEN", "COMPLETE"] },
    team: {
      type: "array",
      minItems: 1,
      // At most one LEAD in the team array
      contains: {
        type: "object",
        properties: { role: { const: "LEAD" } },
        required: ["role"]
      },
      maxContains: 1,
      items: {
        type: "object",
        required: ["role", "staffName", "staffId"],
        additionalProperties: false,
        properties: {
          role: { type: "string", enum: ["LEAD", "MEMBER"] },
          staffName: { type: "string", minLength: 5 },
          staffId: { type: "integer", minimum: 1 }
        }
      }
    }
  }
};
var actionItemUpdateSchema = {
  $schema: "https://json-schema.org/draft/2019-09/schema",
  type: "object",
  required: ["actionName", "status", "team", "actionId"],
  additionalProperties: false,
  properties: {
    actionId: { type: "integer", minimum: 1 },
    actionName: { type: "string", minLength: 10 },
    status: { type: "string", enum: ["OPEN", "COMPLETE"] },
    team: {
      type: "array",
      minItems: 1,
      // At most one LEAD in the team array
      contains: {
        type: "object",
        properties: { role: { const: "LEAD" } },
        required: ["role"]
      },
      maxContains: 1,
      items: {
        type: "object",
        required: ["role", "staffName", "staffId", "assignmentId"],
        additionalProperties: false,
        properties: {
          role: { type: "string", enum: ["LEAD", "MEMBER"] },
          staffName: { type: "string", minLength: 5 },
          staffId: { type: "integer", minimum: 1 },
          assignmentId: { type: "integer", minimum: 1 }
        }
      }
    }
  }
};
function validateNumber(input, lowerBound, upperBound) {
  if (lowerBound > upperBound) {
    throw new Error(`upper bound ${upperBound} cannot be smaller than lower bound ${lowerBound} in pagination query`);
  }
  if (!/^\d+$/.test(input)) {
    return -1;
  }
  const parsedNumber = Number.parseInt(
    input,
    10
  );
  if (parsedNumber < lowerBound || parsedNumber > upperBound || !Number.isInteger(parsedNumber))
    return -1;
  else
    return parsedNumber;
}
function getActionItemHandler(req, resp) {
  resp.content_type("application/json");
  const rawId = req.uri_parameters.id;
  const saneId = Number.parseInt(rawId, 10);
  if (!/^\d+$/.test(rawId) || !Number.isInteger(saneId)) {
    resp.status(400);
    resp.json({
      message: "ID must be numeric",
      details: `${rawId} is not a number`
    });
    return;
  }
  try {
    const input = {
      id: saneId
    };
    const data = getActionItem(input);
    if (!data) {
      resp.status(404);
    } else {
      resp.status(200);
      resp.content_type("application/json");
      resp.json(data);
    }
  } catch (err) {
    resp.status(500);
    resp.json({
      message: "an unexpected error occurred in getActionItemHandler()",
      details: err.message
    });
  }
}
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
    [id]
  );
  if (result.rows.length === 0) {
    return null;
  }
  console.log(
    `found some data: ${JSON.stringify(result.rows[0].ACTION_ITEMS_JSON)}`
  );
  return result.rows[0].ACTION_ITEMS_JSON;
}
function getAllActionItemsHandler(req, resp) {
  console.log(`req: ${JSON.stringify(req)}`);
  try {
    let searchPattern = req.query_parameters?.search;
    if (!searchPattern) {
      searchPattern = "%";
    } else if (!/^[A-Za-z0-9]+$/.test(searchPattern)) {
      resp.status(400);
      resp.content_type("application/json");
      resp.json({
        error: "Invalid query parameter (search)",
        message: "search pattern must only contain letters and numbers"
      });
      return;
    } else {
      searchPattern = `%${searchPattern}%`;
    }
    const saneLimit = validateNumber(req.query_parameters?.limit ?? "25", 1, 100);
    const saneOffset = validateNumber(req.query_parameters?.offset ?? "0", 0, 100);
    if (saneLimit < 0 || saneOffset < 0) {
      resp.status(400);
      resp.content_type("application/json");
      resp.json({
        error: "Invalid query parameter (offset or limit)",
        message: "offset must be an integer in the range [0,100], limit must be in the range [1,100]"
      });
      return;
    }
    const input = {
      search: searchPattern,
      limit: saneLimit,
      offset: saneOffset
    };
    console.log(`input: ${JSON.stringify(input)}`);
    const data = getAllActionItems(input);
    resp.status(200);
    resp.content_type("application/json");
    resp.json(data);
  } catch (err) {
    resp.status(500);
    resp.json({
      message: "an unexpected error occurred in getAllActionItemsHandler()",
      details: err.message
    });
  }
}
function getAllActionItems({ search, limit, offset }) {
  let result = session.execute(
    `select
            count(*) as total_count
         from
            action_items a
         where
            upper(a.name) like upper(:search)`,
    {
      search: {
        dir: oracledb.BIND_IN,
        val: search
      }
    }
  );
  const totalRows = result.rows[0].TOTAL_COUNT;
  if (totalRows === 0) {
    return {
      items: [],
      hasMore: false,
      totalRows: 0
    };
  }
  result = session.execute(
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
            } as actionItem
        from
            action_items a
        where
            upper(a.name) like upper(:search)
        offset :offset rows fetch first :limit rows only`,
    {
      search: {
        dir: oracledb.BIND_IN,
        val: search
      },
      offset: {
        dir: oracledb.BIND_IN,
        val: offset
      },
      limit: {
        dir: oracledb.BIND_IN,
        val: limit
      }
    },
    {
      fetchTypeHandler: (metaData) => {
        metaData.name = metaData.name.toLowerCase();
      }
    }
  );
  const items = result.rows ?? [];
  return {
    items,
    hasMore: offset + items.length < totalRows,
    totalRows
  };
}
function updateActionItemHandler(req, resp) {
  resp.content_type("application/json");
  const dbmsJSONSchema = plsffi.resolvePackage("DBMS_JSON_SCHEMA");
  const result = plsffi.arg();
  const errors = plsffi.arg();
  dbmsJSONSchema.is_valid(req.body, actionItemUpdateSchema, result, errors);
  if (!result.val) {
    resp.status(400);
    resp.json(errors.val);
    return;
  }
  const actionItem = req.body;
  console.log("update: incoming data successfully validated");
  try {
    let result2;
    result2 = session.execute(
      "update action_items set name = :name, status = :status where id = :id",
      {
        name: {
          dir: oracledb.BIND_IN,
          val: actionItem.actionName
        },
        status: {
          dir: oracledb.BIND_IN,
          val: actionItem.status
        },
        id: {
          dir: oracledb.BIND_IN,
          val: actionItem.actionId
        }
      }
    );
    console.log("action_items successfully updated");
    result2 = session.execute(
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
          dir: oracledb.BIND_IN
        }
      }
    );
    console.log(`merge completed. ${result2.rowsAffected} rows updated`);
    result2 = session.execute(
      `delete from action_item_team_members t
            where
                t.action_id = :actionId
                and not exists (
                    select
                        1
                    from
                        json_table(
                            :actionItem,
                            '$.team[*]'
                            columns (
                                assignment_id number path '$.assignmentId'
                            )
                ) s
                where s.assignment_id = t.id
            )`,
      {
        actionId: {
          dir: oracledb.BIND_IN,
          val: actionItem.actionId
        },
        actionItem: {
          type: oracledb.DB_TYPE_JSON,
          val: actionItem,
          dir: oracledb.BIND_IN
        }
      }
    );
    console.log(`delete completed. ${result2.rowsAffected} rows deleted`);
    const data = getActionItem({ id: actionItem.actionId });
    resp.status(200);
    resp.json(data);
  } catch (err) {
    resp.status(500);
    resp.json({
      message: "an unexpected error occurred in updateActionItemHandler()",
      details: err.message
    });
  }
}
function createActionItemHandler(req, resp) {
  resp.content_type("application/json");
  const dbmsJSONSchema = plsffi.resolvePackage("DBMS_JSON_SCHEMA");
  const result = plsffi.arg();
  const errors = plsffi.arg();
  dbmsJSONSchema.is_valid(req.body, actionItemInsertSchema, result, errors);
  if (!result.val) {
    resp.status(400);
    resp.json(errors.val);
    return;
  }
  const actionItem = req.body;
  try {
    let result2;
    result2 = session.execute(
      `insert into action_items (name, status) values (:name, :status)
             returning id into :id`,
      {
        name: {
          dir: oracledb.BIND_IN,
          val: actionItem.actionName
        },
        status: {
          dir: oracledb.BIND_IN,
          val: actionItem.status
        },
        id: {
          dir: oracledb.BIND_OUT,
          type: oracledb.NUMBER
        }
      }
    );
    const id = result2.outBinds.id[0];
    const sql = `insert into action_item_team_members(
                action_id, user_id, role
            ) values (
                :actionId, :userId, :role
            )`;
    const binds = actionItem.team.map((m) => ({
      actionId: id,
      userId: m.staffId,
      role: m.role
    }));
    result2 = session.executeMany(sql, binds);
    if (result2.rowsAffected === 0)
      throw new Error(
        `failed to associate team members with action item ${id}`
      );
    resp.status(201);
    const data = getActionItem({ id });
    resp.json(data);
  } catch (err) {
    resp.status(500);
    resp.json({
      message: "an unexpected error occurred in createActionItemHandler()",
      details: err.message
    });
  }
}
function deleteActionItemHandler(req, resp) {
  const rawId = req.uri_parameters.id;
  const saneId = Number.parseInt(rawId, 10);
  if (!/^\d+$/.test(rawId) || !Number.isInteger(saneId)) {
    resp.status(400);
    resp.json({
      message: "ID must be numeric",
      details: `${rawId} is not a number`
    });
    return;
  }
  try {
    let result = session.execute(
      "delete from action_item_team_members where action_id = :id",
      [saneId]
    );
    result = session.execute("delete from action_items where id = :id", [
      saneId
    ]);
    console.log(`deleted ${result.rowsAffected} rows`);
    if (result.rowsAffected === 0) {
      resp.status(404);
    } else {
      resp.status(204);
    }
  } catch (err) {
    resp.content_type("application/json");
    resp.status(500);
    resp.json({
      message: "an unexpected error occurred in deleteActionItemHandler()",
      details: err.message
    });
  }
}
export {
  createActionItemHandler,
  deleteActionItemHandler,
  getActionItemHandler,
  getAllActionItemsHandler,
  updateActionItemHandler
};
/


-- sqlcl_snapshot {"hash":"69f7d202b36f9ca36a68cdee279b80349404f446","type":"MLE_MODULE","name":"JAVASCRIPT_IMPL_MODULE","schemaName":"EMILY","sxml":""}