/**
 * INTRODUCTION
 *
 * Initial examples
 */

------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------- let's create the user
create user emily identified by values '...'
default tablespace users quota 100m on users
temporary tablespace temp;

grant db_developer_role to emily;
grant soda_app to emily;
grant execute on javascript to emily;
grant execute dynamic mle to emily;
alter user emily default role all;

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------- example 01
-- let's create a simple JavaScript function to convert an epoch number, like 1728597600 to a Date
create or replace function epoch_to_date(
    "p_epoch" number
) return date
as mle language javascript
{{
    let d = new Date(0);
    d.setUTCSeconds(p_epoch);

    return d;
}};
/

-- that can be used anywhere :)
select to_char (
    epoch_to_date(
        1728597600
    ),
    'dd.mm.yyyy hh24:mi:ss'
);

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------- example 02
create or replace mle module utils_module
language javascript
version '1.0.0.0'
as

/**
 * Use dbms_application_info to set module and action
 * @param {string} module the module name to be set 
 * @param {string} action the corresponding action
 */
export function setModuleAction(module, action) {

    if (typeof module !== 'string' || typeof action !== 'string') {
        throw new Error('please provide valid strings as module and action pair');
    }

    session.execute(
        `begin
            dbms_application_info.set_module(
                module_name => :module,
                action_name => :action
            );
        end;`,
        [
            module,
            action
        ]
    );
}

/**
 * Read current module and action and return them to the caller
 * @returns {object} the saved module and action
 */
export function getModuleAction() {

    const result = session.execute(`
        begin 
            dbms_application_info.read_module(
                :module, 
                :action); 
            end;`,
        {
            module: {
                dir: oracledb.BIND_OUT,
                type: oracledb.STRING
            },
            action: {
                dir: oracledb.BIND_OUT,
                type: oracledb.STRING
            }
        }
    );

    return {
        module: result.outBinds.module,
        action: result.outBinds.action
    };
}
/

-- the module's source code can be found in user_source
select
    line,
    text
from
    user_source
where
    name = 'UTILS_MODULE';

-- if you want to call the module in SQL and PL/SQL you need a call specification
create or replace package utils_pkg as

    procedure set_module_action(
        p_module varchar2,
        p_action varchar2
    ) as mle module utils_module
    signature 'setModuleAction';

    function get_module_action
        return json
    as mle module utils_module
    signature 'getModuleAction';

end utils_pkg;
/

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------- example 03

create or replace mle env utils_env
imports (
    'utils' module utils_module
);

set serveroutput on;
declare
    l_ctx           dbms_mle.context_handle_t;
    l_source_code   clob;
begin
    -- Create execution context for MLE execution and provide an environment_
    l_ctx    := dbms_mle.create_context(
        environment => 'UTILS_ENV'
    );
	
    -- using q-quotes to avoid problems with unwanted string termination
    l_source_code := 
q'~

(async() => {
    const { getModuleAction, setModuleAction } = await import ('utils');

    let savedModuleAction = getModuleAction();
    console.log('module/action before: ' + JSON.stringify(savedModuleAction));

    setModuleAction('newModule','newAction');
    savedModuleAction = getModuleAction();
    console.log('module/action after: ' + JSON.stringify(savedModuleAction));
})()
~';
    dbms_mle.eval(
        context_handle => l_ctx,
        language_id => 'JAVASCRIPT',
        source => l_source_code,
        source_name => 'example03'
    );

    dbms_mle.drop_context(l_ctx);
exception
    when others then
        dbms_mle.drop_context(l_ctx);
        raise;
end;
/