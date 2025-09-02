-- liquibase formatted sql
-- changeset DEMOUSER:1756815470555 stripComments:false  logicalFilePath:initial_version/demouser/tables/todo_categories.sql runAlways:false runOnChange:false replaceIfExists:true failOnError:true
-- sqlcl_snapshot src/database/demouser/tables/todo_categories.sql:null:69979b5f5a4ebeb0397957f1f60d6a59d6d768c9:create

create table todo_categories (
    category_id   number
        generated always as identity
    not null enable,
    user_id       number not null enable,
    category_name varchar2(50 byte) not null enable,
    created_date  date default sysdate not null enable
);

alter table todo_categories
    add constraint todo_categories_pk primary key ( category_id )
        using index enable;

alter table todo_categories
    add constraint todo_categories_uk unique ( user_id,
                                               category_name )
        using index enable;

