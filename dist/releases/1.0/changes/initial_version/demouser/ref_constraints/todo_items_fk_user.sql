-- liquibase formatted sql
-- changeset DEMOUSER:1756815470544 stripComments:false  logicalFilePath:initial_version/demouser/ref_constraints/todo_items_fk_user.sql runAlways:false runOnChange:false replaceIfExists:true failOnError:true
-- sqlcl_snapshot src/database/demouser/ref_constraints/todo_items_fk_user.sql:null:89d4db778dcf56044878efbaf1adcd7b8329691c:create

alter table todo_items
    add constraint todo_items_fk_user
        foreign key ( user_id )
            references todo_users ( user_id )
                on delete cascade
        enable;

