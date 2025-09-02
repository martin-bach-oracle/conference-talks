-- liquibase formatted sql
-- changeset DEMOUSER:1756815470606 stripComments:false  logicalFilePath:initial_version/demouser/tables/todo_users.sql runAlways:false runOnChange:false replaceIfExists:true failOnError:true
-- sqlcl_snapshot src/database/demouser/tables/todo_users.sql:null:726963fba43ae5c79d37c6173ca87d3ab1a72951:create

create table todo_users (
    user_id      number
        generated always as identity
    not null enable,
    username     varchar2(30 byte) not null enable,
    email        varchar2(255 byte) not null enable,
    created_date date default sysdate not null enable
);

alter table todo_users add constraint todo_users_email_uk unique ( email )
    using index enable;

alter table todo_users
    add constraint todo_users_pk primary key ( user_id )
        using index enable;

alter table todo_users add constraint todo_users_username_uk unique ( username )
    using index enable;

