-- liquibase formatted sql
-- changeset EMILY:1789392169107 stripComments:false  logicalFilePath:change-plsql-handler-code-to-functions/emily/package_specs/plsql_impl_pkg.sql
-- sqlcl_snapshot src/database/emily/package_specs/plsql_impl_pkg.sql:3eb19e3eac6e6fa8de784e6367fa28565204f886:118f26d5358e8dae6e4e3ee9d3b55df61946e79d:alter

create or replace package emily.plsql_impl_pkg as
    function get_action_item (
        p_id number
    ) return json;

    function insert_action_item (
        p_action_item json
    ) return json;

    function update_action_item (
        p_action_item json
    ) return json;

    procedure delete_action_item (
        p_action_item_id number
    );

end;
/

