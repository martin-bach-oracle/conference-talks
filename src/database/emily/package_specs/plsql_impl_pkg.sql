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


-- sqlcl_snapshot {"hash":"118f26d5358e8dae6e4e3ee9d3b55df61946e79d","type":"PACKAGE_SPEC","name":"PLSQL_IMPL_PKG","schemaName":"EMILY","sxml":""}