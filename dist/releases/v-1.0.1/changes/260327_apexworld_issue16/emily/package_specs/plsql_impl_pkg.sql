-- liquibase formatted sql
-- changeset EMILY:1773348927649 stripComments:false  logicalFilePath:260327_apexworld_issue16/emily/package_specs/plsql_impl_pkg.sql
-- sqlcl_snapshot src/database/emily/package_specs/plsql_impl_pkg.sql:null:3eb19e3eac6e6fa8de784e6367fa28565204f886:create

create or replace package emily.plsql_impl_pkg as
    procedure get_action_item (
        p_id number
    );

    procedure get_all_action_items (
        p_search varchar2,
        p_offset number,
        p_limit  number
    );

    procedure insert_action_item (
        p_action_item json
    );

    procedure update_action_item (
        p_action_item json
    );

    procedure delete_action_item (
        p_action_item_id number
    );

end;
/

