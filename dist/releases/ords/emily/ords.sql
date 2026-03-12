-- liquibase formatted sql
-- changeset EMILY:1773348928072 stripComments:false  logicalFilePath:ords/emily/ords.sql
-- sqlcl_snapshot {"hash":"73fb5bbc9f29c44c971d17fdc4bf54640dc93ff9","type":"ORDS_SCHEMA","name":"ords","schemaName":"EMILY","sxml":""}
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

  ORDS.CREATE_ROLE(
      p_role_name=> 'oracle.dbtools.role.autorest.EMILY');
  ORDS.CREATE_ROLE(
      p_role_name=> 'oracle.dbtools.role.autorest.any.EMILY');
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


COMMIT;

END;
/


