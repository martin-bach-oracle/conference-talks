create or replace package user_admin_pkg as
    procedure create_user (
        p_username todo_users.username%type,
        p_email    todo_users.email%type
    );

end;
/


-- sqlcl_snapshot {"hash":"58208d91062b4a2c3eb81f64d1501bb66ef2b242","type":"PACKAGE_SPEC","name":"USER_ADMIN_PKG","schemaName":"DEMOUSER","sxml":""}