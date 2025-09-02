-- liquibase formatted sql
-- changeset DEMOUSER:1756815470581 stripComments:false  logicalFilePath:initial_version/demouser/tables/todo_items.sql runAlways:false runOnChange:false replaceIfExists:true failOnError:true
-- sqlcl_snapshot src/database/demouser/tables/todo_items.sql:null:8080a26c4ef23f5a78d39c63b1c9e08ff0732ba9:create

create table todo_items (
    item_id         number
        generated always as identity
    not null enable,
    user_id         number not null enable,
    category_id     number,
    title           varchar2(200 byte) not null enable,
    description     clob,
    priority        varchar2(10 byte) not null enable,
    target_date     date,
    completion_date date,
    created_date    date default sysdate not null enable
);

alter table todo_items
    add constraint todo_items_pk primary key ( item_id )
        using index enable;

alter table todo_items
    add constraint todo_items_priority_chk
        check ( priority in ( 'LOW', 'NORMAL', 'HIGH', 'low', 'normal',
                              'high' ) ) enable;

