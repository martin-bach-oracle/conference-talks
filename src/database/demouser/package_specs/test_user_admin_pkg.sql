create or replace package test_user_admin_pkg as

    --%suite(Unit-tests covering the backend API)

    --%test(ensure new user is successfully created)
    procedure test_create_user;

end;
/


-- sqlcl_snapshot {"hash":"c845d0a45516ca5d339770446ef89b3653f142cc","type":"PACKAGE_SPEC","name":"TEST_USER_ADMIN_PKG","schemaName":"DEMOUSER","sxml":""}