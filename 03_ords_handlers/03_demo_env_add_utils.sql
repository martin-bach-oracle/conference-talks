--liquibase formatted sql
--changeset mcb:r3-03 failOnError:true labels:r3

alter mle env JAVASCRIPT_DEMO_ENV_THINGS 
add imports (
    'utils' module utils_module
);

-- rollback alter mle env JAVASCRIPT_DEMO_ENV_THINGS drop imports ('ords');