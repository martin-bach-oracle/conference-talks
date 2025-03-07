-- 
-- to be run as SYSTEM in the PDB where APEX is installed
--

begin

    -- apex_instance_admin.remove_workspace(
    --     p_workspace => 'POUG_WS'
    -- );

    apex_instance_admin.add_workspace(
        p_workspace_id        => NULL,
        p_workspace           => 'POUG_WS',
        p_primary_schema      => 'EMILY'
    );
    commit;

    apex_util.set_security_group_id(
        apex_util.find_security_group_id(
            p_workspace => 'POUG_WS'
        )
    );

    -- workspace admin
    apex_util.create_user(
        p_user_name => 'POUG_WS_ADMIN',
        p_email_address => 'martin.b.bach@oracle.com',
        p_default_schema => 'EMILY',
        p_allow_access_to_schemas => 'EMILY',
        p_web_password => 'welcome1',
        p_developer_privs => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
        p_change_password_on_first_use => 'Y'
    );

    -- developer
    apex_util.create_user(
        p_user_name => 'MARTIN',
        p_email_address => 'martin.b.bach@oracle.com',
        p_default_schema => 'EMILY',
        p_allow_access_to_schemas => 'EMILY',
        p_web_password => 'welcome1',
        p_developer_privs => 'CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
        p_change_password_on_first_use => 'Y'
    );
    
    commit;
end;
/

select
    workspace_display_name 
from
    apex_workspaces;

select
    workspace_name,
    user_name,
    is_admin,
    is_application_developer
from
    apex_workspace_apex_users
where
    workspace_name = 'POUG_WS';