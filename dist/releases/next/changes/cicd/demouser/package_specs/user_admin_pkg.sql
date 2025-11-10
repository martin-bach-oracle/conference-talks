-- liquibase formatted sql
-- changeset DEMOUSER:1762775918916 stripComments:false  logicalFilePath:cicd/demouser/package_specs/user_admin_pkg.sql
-- sqlcl_snapshot src/database/demouser/package_specs/user_admin_pkg.sql:null:58208d91062b4a2c3eb81f64d1501bb66ef2b242:create

create or replace package user_admin_pkg as
    procedure create_user (
        p_username todo_users.username%type,
        p_email    todo_users.email%type
    );

end;
/

