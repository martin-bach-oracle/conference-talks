-- liquibase formatted sql
-- changeset DEMOUSER:1756815470536 stripComments:false  logicalFilePath:initial_version/demouser/ref_constraints/todo_items_fk_category.sql runAlways:false runOnChange:false replaceIfExists:true failOnError:true
-- sqlcl_snapshot src/database/demouser/ref_constraints/todo_items_fk_category.sql:null:baeacb6ad64cde7aba9dcccd2da6153c4050dd23:create

alter table todo_items
    add constraint todo_items_fk_category
        foreign key ( category_id )
            references todo_categories ( category_id )
                on delete set null
        enable;

