declare
    c_module_name   constant varchar2(32) := 'demo_module';
    c_pattern       constant varchar2(32) := 'things/';
begin
    ords.define_module(
        p_module_name    => c_module_name,
        p_base_path      => '/api/',
        p_status         => 'PUBLISHED',
        p_items_per_page => 25,
        p_comments       => 'ORDS handlers written in JavaScript implementing the Things API'
    );
 
    ords.define_template(
        p_module_name    => c_module_name,
        p_pattern        => c_pattern,
        p_priority       => 0,
        p_etag_type      => 'HASH',
        p_etag_query     => null,
        p_comments       => 'entrypoint to managing things'
    );
 
    ords.define_handler(
        p_module_name    => c_module_name,
        p_pattern        => c_pattern,
        p_method         => 'GET',
        p_source_type    => 'mle/javascript',
        p_mle_env_name   => 'JAVASCRIPT_DEMO_ENV_THINGS',
        p_items_per_page => 0,
        p_mimes_allowed  => null,
        p_comments       => 'get all the things',
        p_source         => q'~
(req, resp) => {

    const { getThings, isEmpty } = await import ('ords');

    let data = {};

    if (isEmpty(req.query_parameters)) {
        
        data = getThings();
    } else {

        const options = {};

        if ( req.query_parameters.searchTerm !== undefined ) {
            options.searchTerm = req.query_parameters.searchTerm
        }

        if ( req.query_parameters.limit !== undefined ) {
            options.limit = req.query_parameters.limit
        }

        if ( req.query_parameters.offset !== undefined ) {
            options.skip = req.query_parameters.offset
        }

        if ( req.query_parameters.debug !== undefined ) {
            options.debug = true
        }

        data = getThings(options);
    }

    resp.content_type('application/json');
    resp.json(data);
}
~'
    );
 
    commit;
 
end;
/