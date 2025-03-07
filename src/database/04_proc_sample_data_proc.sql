--liquibase formatted sql
--changeset martin.b.bach:r1_04 failOnError:true labels:r1 endDelimiter:/ stripComments:false

create or replace procedure sample_data_proc (
   p_num_rows number
) as mle module sample_data_module signature 'generateSampleData';
/