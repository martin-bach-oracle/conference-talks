-- select 'drop table if exists ' || lower(table_name) || ' cascade constraints purge;' from tabs;

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
drop view if exists thing;

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