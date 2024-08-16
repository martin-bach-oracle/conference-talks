-- select 'drop table if exists ' || lower(table_name) || ' cascade constraints purge;' from tabs;

drop table if exists databasechangelog_actions cascade constraints purge;
drop table if exists databasechangelog cascade constraints purge;
drop table if exists databasechangeloglock cascade constraints purge;

drop table if exists demo_thing_categories cascade constraints purge;
drop table if exists demo_things cascade constraints purge;
drop table if exists demo_warehouse cascade constraints purge;
drop table if exists  demo_thing_stock cascade constraints purge;
drop view if exists thing;

drop mle module if exists VALIDATOR_MODULE;
drop mle module if exists DEMO_THINGS_MODULE;

drop package if exists DEMO_THINGS_PKG;