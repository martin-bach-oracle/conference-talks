conn -n apexworld

set echo on

drop table if exists EM_EMAIL_1 purge;
drop table if exists DATABASECHANGELOG_ACTIONS purge;
drop table if exists DATABASECHANGELOG purge;
drop table if exists DATABASECHANGELOGLOCK purge;

drop mle module if exists SAMPLE_DATA_MODULE;
drop mle module if exists fakerjs_module;