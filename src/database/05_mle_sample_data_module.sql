--liquibase formatted sql
--changeset martin.b.bach:r1_04 failOnError:true labels:r1

mle create-module -filename ../../dist/bundle.js -module-name sample_data_module -replace

create or replace mle env apexworld_env imports (
    'sampleData' module sample_data_module
);