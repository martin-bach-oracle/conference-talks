alter table todo_items
    add constraint todo_items_fk_category
        foreign key ( category_id )
            references todo_categories ( category_id )
                on delete set null
        enable;


-- sqlcl_snapshot {"hash":"baeacb6ad64cde7aba9dcccd2da6153c4050dd23","type":"REF_CONSTRAINT","name":"TODO_ITEMS_FK_CATEGORY","schemaName":"DEMOUSER","sxml":""}