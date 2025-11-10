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


-- sqlcl_snapshot {"hash":"f804c9d8320f41eeecec26066e1ac7dae0a612a1","type":"PACKAGE_BODY","name":"TEST_USER_ADMIN_PKG","schemaName":"DEMOUSER","sxml":""}