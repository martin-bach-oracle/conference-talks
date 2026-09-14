
--
        
DECLARE

  l_roles     OWA.VC_ARR;
  l_modules   OWA.VC_ARR;
  l_patterns  OWA.VC_ARR;

BEGIN
  ORDS.ENABLE_SCHEMA(
      p_enabled             => TRUE,
      p_url_mapping_type    => 'BASE_PATH',
      p_url_mapping_pattern => 'emily',
      p_auto_rest_auth      => FALSE);

  ORDS.DEFINE_MODULE(
      p_module_name    => 'js',
      p_base_path      => '/js/',
      p_items_per_page => 25,
      p_status         => 'PUBLISHED',
      p_comments       => 'ORDS handlers written in JavaScript');

  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'js',
      p_pattern        => 'actionItem/:id',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => 'single action item');

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'js',
      p_pattern        => 'actionItem/:id',
      p_method         => 'GET',
      p_source_type    => 'mle/javascript',
      p_items_per_page => 0,
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_mle_env_name => 'JAVASCRIPT_IMPL_ENV',
      p_source         => 
'
(req, resp) => {

    const { getActionItemHandler } = await import (''handlers'');
    getActionItemHandler(req, resp);
}    
    ');

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'js',
      p_pattern        => 'actionItem/:id',
      p_method         => 'PUT',
      p_source_type    => 'mle/javascript',
      p_items_per_page => 0,
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_mle_env_name => 'JAVASCRIPT_IMPL_ENV',
      p_source         => 
'
(req, resp) => {

    const { updateActionItemHandler } = await import (''handlers'');
    updateActionItemHandler(req, resp);
}    
    ');

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'js',
      p_pattern        => 'actionItem/:id',
      p_method         => 'DELETE',
      p_source_type    => 'mle/javascript',
      p_items_per_page => 0,
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_mle_env_name => 'JAVASCRIPT_IMPL_ENV',
      p_source         => 
'
(req, resp) => {

    const { deleteActionItemHandler } = await import (''handlers'');
    deleteActionItemHandler(req, resp);
}    
    ');

  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'js',
      p_pattern        => 'actionItem/',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => 'potentially multiple action items and/or POST');

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'js',
      p_pattern        => 'actionItem/',
      p_method         => 'GET',
      p_source_type    => 'json/collection',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'
            select
                json{
                    ''actionId'' value      a.id,
                    ''actionName'' value    a.name,
                    ''status'' value       a.status,
                    ''team'' value (
                        select json_arrayagg(
                            json{
                                ''assignmentId'' value tm.id,
                                ''role'' value         tm.role,
                                ''staffId'' value      tm.user_id,
                                ''staffName'' value    s.name
                            }
                            order by tm.role desc, s.name
                        )
                        from
                            action_item_team_members tm
                            join staff s on s.id = tm.user_id
                        where
                            tm.action_id = a.id
                    )
                } as actionItem
            from
                action_items a
      ' || '      where
                upper(a.name) like ''%'' || upper(:search) || ''%''
    ');

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'js',
      p_pattern        => 'actionItem/',
      p_method         => 'POST',
      p_source_type    => 'mle/javascript',
      p_items_per_page => 0,
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_mle_env_name => 'JAVASCRIPT_IMPL_ENV',
      p_source         => 
'
(req, resp) => {

    const { createActionItemHandler } = await import (''handlers'');
    createActionItemHandler(req, resp);
}    
    ');

  ORDS.DEFINE_MODULE(
      p_module_name    => 'plsql',
      p_base_path      => '/plsql/',
      p_items_per_page => 25,
      p_status         => 'PUBLISHED',
      p_comments       => 'ORDS handlers for plsql_impl_pkg');

  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'plsql',
      p_pattern        => 'actionItem/:id',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'plsql',
      p_pattern        => 'actionItem/:id',
      p_method         => 'GET',
      p_source_type    => 'json/collection',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'
select 
            json_object(
                ''actionId''  value     a.id,
                ''actionName'' value     a.name,
                ''status'' value        a.status,
                ''team''value (
                    select
                        json_arrayagg(
                            json_object(
                                ''assignmentId'' value tm.id,
                                ''role'' value        tm.role,
                                ''staffId'' value     tm.user_id,
                                ''staffName'' value   s.name
                            )
                        order by tm.role desc, s.name
                        )
                    from 
                        action_item_team_members tm
                        join staff s on s.id = tm.user_id
                    where
                        tm.action_id = a.id
                )
        ) as action_items_json
        from
            action_items a
        where
            a.id = :id
');

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'plsql',
      p_pattern        => 'actionItem/:id',
      p_method         => 'DELETE',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'
begin
  plsql_impl_pkg.delete_action_item(p_action_item_id => :id);
exception
  when others then
    if sqlcode = -20004 then
      :status_code := 404;
      htp.p ( sqlerrm );
    else
      :status_code := 500;
      htp.p ( sqlerrm );
    end if;
end;');

  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'plsql',
      p_pattern        => 'actionItem/',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'plsql',
      p_pattern        => 'actionItem/',
      p_method         => 'GET',
      p_source_type    => 'json/collection',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'
      select *
      from (
        select
            json{
                ''actionId'' value      a.id,
                ''actionName'' value    a.name,
                ''status'' value       a.status,
                ''team'' value (
                    select json_arrayagg(
                        json{
                            ''assignmentId'' value tm.id,
                            ''role'' value         tm.role,
                            ''staffId'' value      tm.user_id,
                            ''staffName'' value    s.name
                        }
                        order by tm.role desc, s.name
                    )
                    from
                        action_item_team_members tm
                        join staff s on s.id = tm.user_id
                    where
                        tm.action_id = a.id
                )
            } as actionItem
        from
            action_items a
        where
            upper(a.name) like ''%'' || upper(:search) || ''%''
' || '      )
');

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'plsql',
      p_pattern        => 'actionItem/',
      p_method         => 'POST',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'declare
  l_payload json;
  l_result json;
begin
  l_payload := JSON(:body_text);
  dbms_output.put_line(JSON_SERIALIZE(l_payload));
  l_result := plsql_impl_pkg.insert_action_item(p_action_item => l_payload);
  htp.p(json_serialize(l_result));
  :status := 201;
exception
  when others then
    if sqlcode = -20001 then
      :status_code := 400;
      htp.p ( sqlerrm );
    else
      :status_code := 500;
      htp.p ( sqlerrm );
    end if;
end;');

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'plsql',
      p_pattern        => 'actionItem/',
      p_method         => 'PUT',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'
declare
  l_payload json;
  l_result json;
begin
  l_payload := json(:body_text);
  l_result := plsql_impl_pkg.update_action_item(p_action_item => l_payload);
  -- commit;
  htp.p(json_serialize(l_result));
  :status := 201;
exception
  when others then
    if sqlcode = -20001 then
      :status_code := 400;
      htp.p ( sqlerrm );
    elsif sqlcode = -20004 then
      :status_code := 404;
      htp.p ( sqlerrm );
    else
      :status_code := 500;
      htp.p ( sqlerrm );
    end if;
end;');

  ORDS.CREATE_ROLE(
      p_role_name=> 'oracle.dbtools.role.autorest.EMILY');
  ORDS.CREATE_ROLE(
      p_role_name=> 'oracle.dbtools.role.autorest.any.EMILY');
  l_roles(1) := 'oracle.dbtools.auth.roles.builtin.VecDB';

  ORDS.DEFINE_PRIVILEGE(
      p_privilege_name => 'oracle.dbtools.auth.privileges.builtin.VecDB',
      p_roles          => l_roles,
      p_patterns       => l_patterns,
      p_modules        => l_modules,
      p_label          => NULL,
      p_description    => NULL,
      p_comments       => NULL); 

  l_roles.DELETE;
  l_modules.DELETE;
  l_patterns.DELETE;

  l_roles(1) := 'oracle.dbtools.autorest.any.schema';
  l_roles(2) := 'oracle.dbtools.role.autorest.EMILY';

  ORDS.DEFINE_PRIVILEGE(
      p_privilege_name => 'oracle.dbtools.autorest.privilege.EMILY',
      p_roles          => l_roles,
      p_patterns       => l_patterns,
      p_modules        => l_modules,
      p_label          => 'EMILY metadata-catalog access',
      p_description    => 'Provides access to the metadata catalog of the objects in the EMILY schema.',
      p_comments       => NULL); 

  l_roles.DELETE;
  l_modules.DELETE;
  l_patterns.DELETE;

  l_roles(1) := 'SODA Developer';
  l_patterns(1) := '/soda/*';

  ORDS.DEFINE_PRIVILEGE(
      p_privilege_name => 'oracle.soda.privilege.developer',
      p_roles          => l_roles,
      p_patterns       => l_patterns,
      p_modules        => l_modules,
      p_label          => NULL,
      p_description    => NULL,
      p_comments       => NULL); 

  l_roles.DELETE;
  l_modules.DELETE;
  l_patterns.DELETE;

  ORDS.FINALIZE_IMPORT(
      p_prune => FALSE,
      p_objects => null);

COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;

END;
/


-- sqlcl_snapshot {"hash":"b52b2ee7ece8af9c570c7e732faa5d6deec284f5","type":"ORDS_SCHEMA","name":"ords","schemaName":"EMILY","sxml":""}