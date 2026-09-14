create or replace package body emily.plsql_impl_pkg as

    insert_schema constant json :=
        json(
            ' {
        type: "object",
        required: ["actionName", "status", "team"],
        additionalProperties: false,
        properties: {
            actionName: { type: "string", minLength: 10 },
            status: { type: "string", enum: ["OPEN", "COMPLETE"] },
            team: {
                type: "array",
                minItems: 1,
                contains: {
                    type: "object",
                    properties: { role: { const: "LEAD" } },
                    required: ["role"],
                },
                maxContains: 1,
                items: {
                    type: "object",
                    required: ["role", "staffName", "staffId"],
                    additionalProperties: false,
                    properties: {
                        role: { type: "string", enum: ["LEAD", "MEMBER"] },
                        staffName: { type: "string", minLength: 5 },
                        staffId: { type: "integer", minimum: 1 },
                    },
                },
            },
        }}'
        );
    update_schema constant json :=
        json(
            ' {
        type: "object",
        required: ["actionName", "status", "team", "actionId"],
        additionalProperties: false,
        properties: {
            actionId: { type: "number" },
            actionName: { type: "string", minLength: 10 },
            status: { type: "string", enum: ["OPEN", "COMPLETE"] },
            team: {
                type: "array",
                minItems: 1,
                contains: {
                    type: "object",
                    properties: { role: { const: "LEAD" } },
                    required: ["role"],
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
                        assignmentId: { type: "integer", minimum: 1 },
                    },
                },
            },
        }}'
        );

    function get_action_item (
        p_id number
    ) return json as
        l_ret json :=
            json(
                '{}'
            );
    begin
        select
                json_object(
                    'actionId' value a.id,
                            'actionName' value a.name,
                            'status' value a.status,
                            'team' value(
                        select
                            json_arrayagg(
                                json_object(
                                    'assignmentId' value tm.id,
                                    'role' value tm.role,
                                    'staffId' value tm.user_id,
                                    'staffName' value s.name
                                )
                            order by
                                tm.role desc,
                                s.name
                            )
                        from
                                 action_item_team_members tm
                            join staff s on s.id = tm.user_id
                        where
                            tm.action_id = a.id
                    )
                )
            as action_items_json
        into l_ret
        from
            action_items a
        where
            a.id = p_id;

        return l_ret;
    end;

    function update_action_item (
        p_action_item json
    ) return json as
        l_action_id action_items.id%type;
        valid_json  boolean;
        json_errors json;
    begin
        dbms_json_schema.is_valid(p_action_item, update_schema, valid_json, json_errors);
        if not valid_json then
            raise_application_error(-20001,
                                    json_serialize(json_errors returning varchar2));
        else
            update action_items acit
            set
                acit.name = jsta.action_name,
                acit.status = upper(jsta.status)
            from
                    json_table ( p_action_item, '$'
                        columns (
                            action_id number path '$.actionId',
                            action_name varchar2 path '$.actionName',
                            status varchar2 path '$.status'
                        )
                    )
                jsta
            where
                acit.id = jsta.action_id
            returning new acit.id into l_action_id;

            if sql%rowcount = 0 then
                raise_application_error(-20004, 'action item not found');
            end if;
            dbms_output.put_line('Updated ' || sql%rowcount);
            merge into action_item_team_members t
            using (
                with new_members as (
                    select
                        *
                    from
                        json_table ( p_action_item, '$'
                            columns (
                                action_id number path '$.actionId',
                                nested path '$.team[*]'
                                    columns (
                                        id number path '$.assignmentId',
                                        role varchar2 ( 20 ) path '$.role',
                                        user_id number path '$.staffId'
                                    )
                            )
                        )
                )
                select
                    jsta.id,
                    coalesce(jsta.action_id, aitm.action_id) action_id,
                    coalesce(jsta.user_id, aitm.user_id)     user_id,
                    coalesce(jsta.role, aitm.role)           role
                from
                    (
                        select
                            *
                        from
                            action_item_team_members
                        where
                            action_id = l_action_id
                    )           aitm
                    full join new_members jsta on aitm.user_id = jsta.user_id
                                                  and aitm.action_id = jsta.action_id
            ) s on ( s.user_id = t.user_id
                     and s.action_id = t.action_id )
            when matched then update
            set t.role = s.role delete
            where
                s.id is null
            when not matched then
            insert (
                action_id,
                user_id,
                role )
            values
                ( s.action_id,
                  s.user_id,
                  s.role );

            dbms_output.put_line('Merged ' || sql%rowcount);
        end if;

        return get_action_item(p_id => l_action_id);
    end;

    function insert_action_item (
        p_action_item json
    ) return json as

        l_action_name action_items.name%type;
        l_status      action_items.status%type;
        l_action_id   action_items.id%type;
        valid_json    boolean;
        json_errors   json;
    begin
        dbms_json_schema.is_valid(p_action_item, insert_schema, valid_json, json_errors);
        if valid_json then
            select
                action_name,
                status
            into
                l_action_name,
                l_status
            from
                json_table ( p_action_item, '$'
                    columns (
                        action_name varchar2 path '$.actionName',
                        status varchar2 path '$.status'
                    )
                );

            insert into action_items (
                name,
                status
            ) values
                ( l_action_name,
                  coalesce(
                      upper(l_status),
                      'OPEN'
                  ) )
            returning id into l_action_id;

            dbms_output.put_line('Inserted ' || sql%rowcount);
            insert into action_item_team_members (
                action_id,
                user_id,
                role
            )
                select
                    l_action_id,
                    member_user_id,
                    upper(member_role)
                from
                    json_table ( p_action_item, '$.team[*]'
                        columns (
                            member_user_id number path '$.staffId',
                            member_role varchar2 path '$.role'
                        )
                    );

            dbms_output.put_line('Inserted ' || sql%rowcount);
        else
            raise_application_error(-20001,
                                    json_serialize(json_errors returning varchar2));
        end if;

        return get_action_item(p_id => l_action_id);
    end;

    procedure delete_action_item (
        p_action_item_id number
    ) as
    begin
        delete from action_item_team_members
        where
            action_id = p_action_item_id;

        dbms_output.put_line('Deleted ' || sql%rowcount);
/**/
        delete from action_items
        where
            id = p_action_item_id;

        if sql%rowcount = 0 then
            raise_application_error(-20004, 'action item not found');
        else
            dbms_output.put_line('Deleted ' || sql%rowcount);
        end if;

    end;

end;
/


-- sqlcl_snapshot {"hash":"580316b996dd08682bf0777f11b68b330767bfb2","type":"PACKAGE_BODY","name":"PLSQL_IMPL_PKG","schemaName":"EMILY","sxml":""}