-- liquibase formatted sql
-- changeset DEMOUSER:1762775918889 stripComments:false  logicalFilePath:cicd/demouser/package_bodies/user_admin_pkg.sql
-- sqlcl_snapshot src/database/demouser/package_bodies/user_admin_pkg.sql:null:6cf44b31f9079416b4f6fca0c0c7db6146e476e7:create

create or replace package body user_admin_pkg as

    procedure create_user (
        p_username todo_users.username%type,
        p_email    todo_users.email%type
    ) as
    begin
        insert into todo_users (
            username,
            email
        ) values ( p_username,
                   p_email );

    end;

end;
/

