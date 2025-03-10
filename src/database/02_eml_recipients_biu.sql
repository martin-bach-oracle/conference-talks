--liquibase formatted sql
--changeset martin.b.bach:r1_02 failOnError:true labels:r1 endDelimiter:/ stripComments:false

create or replace editionable trigger "EML_RECIPIENTS_BIU" before
   insert or update on eml_recipients
   for each row
begin
   :new.updated_on := sysdate;
   :new.updated_by := coalesce(
      sys_context(
         'APEX$SESSION',
         'APP_USER'
      ),
      user
   );
   if inserting then
      :new.row_version := 1;
      :new.created_on := :new.updated_on;
      :new.created_by := :new.updated_by;
   elsif updating then
      :new.row_version := nvl(
         :old.row_version,
         0
      ) + 1;
   end if;
end eml_recipients_biu;
/
alter trigger "EML_RECIPIENTS_BIU" enable
/