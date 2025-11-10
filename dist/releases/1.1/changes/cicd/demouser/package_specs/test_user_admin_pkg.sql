-- liquibase formatted sql
-- changeset DEMOUSER:1762775918902 stripComments:false  logicalFilePath:cicd/demouser/package_specs/test_user_admin_pkg.sql
-- sqlcl_snapshot src/database/demouser/package_specs/test_user_admin_pkg.sql:null:c845d0a45516ca5d339770446ef89b3653f142cc:create

create or replace package test_user_admin_pkg as

    --%suite(Unit-tests covering the backend API)

    --%test(ensure new user is successfully created)
    procedure test_create_user;

end;
/

