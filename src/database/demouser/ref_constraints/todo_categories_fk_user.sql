alter table todo_categories
    add constraint todo_categories_fk_user
        foreign key ( user_id )
            references todo_users ( user_id )
                on delete cascade
        enable;


-- sqlcl_snapshot {"hash":"d5ca1b9e509515e2d4a1aae44163dbaab3c55a5c","type":"REF_CONSTRAINT","name":"TODO_CATEGORIES_FK_USER","schemaName":"DEMOUSER","sxml":""}