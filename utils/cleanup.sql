set echo on

drop table if exists eml_email_content purge;
drop table if exists eml_recipients purge;
drop table if exists databasechangelog_actions purge;
drop table if exists databasechangelog purge;
drop table if exists databasechangeloglock purge;
drop mle module if exists sample_data_module;
drop mle module if exists fakerjs_module;