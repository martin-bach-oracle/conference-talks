-- select 'drop table if exists ' || lower(table_name) || ' cascade constraints purge;' from tabs;

declare
    l_user varchar2(255);
begin
    select
        user into l_user;
    
    if user != 'EMILY' then
        raise_application_error(-20001, 'must be connected as emily to run this script');
    end if;
end;
/

-- liquibase tables
drop table if exists databasechangelog_actions cascade constraints purge;
drop table if exists databasechangelog cascade constraints purge;
drop table if exists databasechangeloglock cascade constraints purge;
drop view  if exists databasechangelog_details;

-- schema tables
drop table if exists demo_thing_categories cascade constraints purge;
drop table if exists demo_things cascade constraints purge;
drop table if exists demo_warehouse cascade constraints purge;
drop table if exists demo_thing_stock cascade constraints purge;
drop view if exists things;

-- mle modules and envs as well as dependent objects
drop mle module if exists validator_module;
drop mle module if exists demo_things_module;
drop mle module if exists ords_handler_impl_module;
drop mle module if exists utils_module; 

drop mle env if exists validator_env;
drop mle env if exists javascript_demo_env_things;
drop mle env if exists utils_env;

drop package if exists utils_pkg;      
drop package if exists demo_things_pkg;

-- the rest
drop function if exists epoch_to_date;

select 
    count(*),
    object_type
from
    user_objects
group by object_type;

select
    object_type,
    object_name
from
    user_objects
order by
    object_type;