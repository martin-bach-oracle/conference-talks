--liquibase formatted sql
--changeset mcb:r3-02 failOnError:true labels:r3

alter mle env JAVASCRIPT_DEMO_ENV_THINGS 
add imports (
    'ords' module ords_handler_impl_module
);

-- rollback alter mle env JAVASCRIPT_DEMO_ENV_THINGS drop imports ('ords');