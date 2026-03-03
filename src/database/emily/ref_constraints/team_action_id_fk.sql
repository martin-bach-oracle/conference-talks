alter table emily.action_item_team_members
    add constraint team_action_id_fk
        foreign key ( action_id )
            references emily.action_items ( id )
                on delete cascade
        enable;


-- sqlcl_snapshot {"hash":"e336cd9de68e0aeb7fe9cd017e7b1b679ef6a837","type":"REF_CONSTRAINT","name":"TEAM_ACTION_ID_FK","schemaName":"EMILY","sxml":""}