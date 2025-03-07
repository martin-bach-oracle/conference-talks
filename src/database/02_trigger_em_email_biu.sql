--liquibase formatted sql
--changeset martin.b.bach:r1_02 failOnError:true labels:r1 endDelimiter:/ stripComments:false

create or replace trigger em_email_1_biu
    before insert or update
    on em_email_1
    for each row
begin
    :new.updated_on := sysdate;
    :new.updated_by := coalesce(sys_context('APEX$SESSION','APP_USER'),user);
    if inserting then
        :new.row_version := 1;
        :new.created_on := :new.updated_on;
        :new.created_by := :new.updated_by;
    elsif updating then
        :new.row_version := nvl(:old.row_version, 0) + 1;
    end if;
end em_email_1_biu;
/