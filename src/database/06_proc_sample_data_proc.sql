--liquibase formatted sql
--changeset martin.b.bach:r1_06 failOnError:true labels:r1 endDelimiter:/ stripComments:false

create or replace package sample_data_pkg as
   procedure generate_sample_email_recipients (
      p_num_rows number
   ) as mle module sample_data_module signature 'generateSampleRecipients';
   procedure generate_sample_email (
      p_num_rows number
   ) as mle module sample_data_module signature 'generateSampleEmail';
end sample_data_pkg;
/