alter table todo_items
    add constraint todo_items_fk_user
        foreign key ( user_id )
            references todo_users ( user_id )
                on delete cascade
        enable;


-- sqlcl_snapshot {"hash":"89d4db778dcf56044878efbaf1adcd7b8329691c","type":"REF_CONSTRAINT","name":"TODO_ITEMS_FK_USER","schemaName":"DEMOUSER","sxml":""}