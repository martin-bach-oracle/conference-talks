-- liquibase formatted sql
-- changeset EMILY:1773348927242 stripComments:false  logicalFilePath:260327_apexworld_issue16/emily/mle_envs/javascript_impl_env.sql
-- sqlcl_snapshot src/database/emily/mle_envs/javascript_impl_env.sql:null:0aa7f8becfd4a47a8381c4e533a20fdd00d5a751:create

create or replace mle env emily.javascript_impl_env imports ( 'handlers' module emily.javascript_impl_module );

