-- liquibase formatted sql
-- changeset EMILY:1789330712308 stripComments:false  logicalFilePath:unique-key/emily/tables/action_item_team_members.sql
-- sqlcl_snapshot src/database/emily/tables/action_item_team_members.sql:f3b4dd0f8fe71755bbd484289cbafbb72d0e19bd:de503bd8a29fade652d85a8da7787548ed72a425:alter

alter table emily.action_item_team_members
    add constraint aitm_action_user_u unique ( action_id,
                                               user_id )
        using index enable
/

