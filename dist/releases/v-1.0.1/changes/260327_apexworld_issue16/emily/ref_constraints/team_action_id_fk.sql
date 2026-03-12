-- liquibase formatted sql
-- changeset EMILY:1773348927688 stripComments:false  logicalFilePath:260327_apexworld_issue16/emily/ref_constraints/team_action_id_fk.sql
-- sqlcl_snapshot src/database/emily/ref_constraints/team_action_id_fk.sql:null:e336cd9de68e0aeb7fe9cd017e7b1b679ef6a837:create

alter table emily.action_item_team_members
    add constraint team_action_id_fk
        foreign key ( action_id )
            references emily.action_items ( id )
                on delete cascade
        enable;

