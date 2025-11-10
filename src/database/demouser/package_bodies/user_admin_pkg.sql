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


-- sqlcl_snapshot {"hash":"6cf44b31f9079416b4f6fca0c0c7db6146e476e7","type":"PACKAGE_BODY","name":"USER_ADMIN_PKG","schemaName":"DEMOUSER","sxml":""}