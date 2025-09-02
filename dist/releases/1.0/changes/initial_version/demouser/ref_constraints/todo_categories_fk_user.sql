-- liquibase formatted sql
-- changeset DEMOUSER:1756815470526 stripComments:false  logicalFilePath:initial_version/demouser/ref_constraints/todo_categories_fk_user.sql runAlways:false runOnChange:false replaceIfExists:true failOnError:true
-- sqlcl_snapshot src/database/demouser/ref_constraints/todo_categories_fk_user.sql:null:d5ca1b9e509515e2d4a1aae44163dbaab3c55a5c:create

alter table todo_categories
    add constraint todo_categories_fk_user
        foreign key ( user_id )
            references todo_users ( user_id )
                on delete cascade
        enable;

