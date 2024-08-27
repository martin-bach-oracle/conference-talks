declare
    c_module_name   constant varchar2(32) := 'demo_module';
begin
    ords.define_module(
        p_module_name    => c_module_name,
        p_base_path      => '/api/',
        p_status         => 'PUBLISHED',
        p_items_per_page => 25,
        p_comments       => 'ORDS handlers written in JavaScript implementing the Things API'
    );

    -- entrypoint to managing many things. Required for the following handlers
    -- * GET
    -- * POST
    ords.define_template(
        p_module_name    => c_module_name,
        p_pattern        => 'things/',
        p_priority       => 0,
        p_etag_type      => 'HASH',
        p_etag_query     => null,
        p_comments       => 'entrypoint to managing all things'
    );

    -- entrypoint to managing single things. Required for the following handlers
    -- * GET
    -- * DELETE
    -- * PUT
    ords.define_template(
        p_module_name    => c_module_name,
        p_pattern        => 'things/:id',
        p_priority       => 0,
        p_etag_type      => 'HASH',
        p_etag_query     => null,
        p_comments       => 'entrypoint to managing single things'
    );

    -- GET handler (including search option, skip and limit) to get all things
    -- arguments are passed as req.query_parameters
    ords.define_handler(
        p_module_name    => c_module_name,
        p_pattern        => 'things/',
        p_method         => 'GET',
        p_source_type    => 'mle/javascript',
        p_mle_env_name   => 'JAVASCRIPT_DEMO_ENV_THINGS',
        p_comments       => 'get all the things, also allow for multiple query options',
        p_source         => q'~
(req, resp) => {

    const { getThings, isEmpty } = await import ('ords');

    let data;

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

        data = getThings(options);
    }

    resp.json(data);
}
~'
    );

    -- GET handler to get a specific thing (by ID)
    -- the :id is provided by req.uri_parameters. No need to test for
    -- null/undefined. If the URI doesn't feature the things/:id the
    -- generic GET handler is invoked.
    ords.define_handler(
        p_module_name    => c_module_name,
        p_pattern        => 'things/:id',
        p_method         => 'GET',
        p_source_type    => 'mle/javascript',
        p_mle_env_name   => 'JAVASCRIPT_DEMO_ENV_THINGS',
        p_comments       => 'get a single thing',
        p_source         => q'~
(req, resp) => {

    const { getThing } = await import ('ords');

    const data = getThing(req.uri_parameters.id);

    resp.json(data);
}
~'
    );

    -- POST handler (insert)
    -- the body is provided by req.body (null if not present, it's *not* set to undefined)
    -- typeof body seems to always return 'object' so it's not very reliable
    ords.define_handler(
        p_module_name    => c_module_name,
        p_pattern        => 'things/',
        p_method         => 'POST',
        p_source_type    => 'mle/javascript',
        p_mle_env_name   => 'JAVASCRIPT_DEMO_ENV_THINGS',
        p_comments       => 'post (insert) a new thing',
        p_source         => q'~
(req, resp) => {

    const { postThing } = await import ('ords');

    let data;

    if (req.body === null) {
        data = {
            error: 'please provide a valid thing'
        };

        resp.status = 400;              // bad request
        resp.json(data);
        return;
    }

    data = postThing(req.body);

    if (data.success) {

        resp.status = 200;              // no errors, all looking good
    } else {
            
        resp.status = 500;              // internal server error
    }

    resp.json(data);
}
~'
    );

    -- PUT handler (update)
    -- things/:id is provided as part of the req.uri_parameters object. The body
    -- is available as req.body. If absent, req.body is null and it always appears to
    -- be of type object
    ords.define_handler(
        p_module_name    => c_module_name,
        p_pattern        => 'things/:id',
        p_method         => 'PUT',
        p_source_type    => 'mle/javascript',
        p_mle_env_name   => 'JAVASCRIPT_DEMO_ENV_THINGS',
        p_comments       => 'put (update) a thing',
        p_source         => q'~
(req, resp) => {

    const { isEmpty, putThing } = await import ('ords');

    if (req.body === null) {
        resp.status = 400;              // bad request
        return;
    }

    const data = putThing(
        req.uri_parameters.id,
        req.body
    );

    if (! data.success) {
        resp.status = 500;              // internal server error
    }

    resp.json(data);
}
~'
    );


    -- DELETE handler (delete)
    -- the thing/:id is provided by the req.uri_parameters object. Should the :id
    -- not be provided ORDS will throw a HTTP 405 method not allowed error
    ords.define_handler(
        p_module_name    => c_module_name,
        p_pattern        => 'things/:id',
        p_method         => 'DELETE',
        p_source_type    => 'mle/javascript',
        p_mle_env_name   => 'JAVASCRIPT_DEMO_ENV_THINGS',
        p_comments       => 'delete a thing',
        p_source         => q'~
(req, resp) => {

    const { deleteThing } = await import ('ords');

    const data = deleteThing(
        req.uri_parameters.id
    );

    if (! data.success) {
        resp.status = 500;              // internal server error
    }

    resp.json(data);
}
~'
    );

    commit;
 
end;
/