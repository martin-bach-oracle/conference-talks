-- liquibase formatted sql
-- changeset DEMOUSER:1762775918856 stripComments:false  logicalFilePath:cicd/demouser/package_bodies/test_user_admin_pkg.sql
-- sqlcl_snapshot src/database/demouser/package_bodies/test_user_admin_pkg.sql:null:f804c9d8320f41eeecec26066e1ac7dae0a612a1:create

create or replace package body test_user_admin_pkg as

    procedure test_create_user as
        l_num_users pls_integer;
    begin
        user_admin_pkg.create_user('Toto', 'toto@nowhere.com');
        select
            count(*)
        into l_num_users
        from
            todo_users
        where
            email = 'toto@nowhere.com';

        ut.expect(l_num_users).to_equal(1);
    end;

end;
/

