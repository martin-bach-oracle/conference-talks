--liquibase formatted sql
--changeset martin.b.bach:r1_06 failOnError:true labels:r1 endDelimiter:/ stripComments:false

create or replace package "GENERATE_SAMPLE_DATA" as

   /**
    * Generates a list of sample email recipients.
    * This procedure is implemented using Oracle's Machine Learning Engine (MLE),
    * which allows JavaScript execution inside the database.
    *
    * @param p_num_rows  The number of sample recipients to generate.
    */
   procedure generate_sample_email_recipients (
      p_num_rows number
   ) as mle module sample_data_module signature 'generateSampleRecipients';

   /**
    * Generates a list of sample emails.
    * This procedure is also executed using Oracle MLE, utilizing 
    * JavaScript functions from the specified module.
    *
    * @param p_num_rows  The number of sample emails to generate.
    */
   procedure generate_sample_email (
      p_num_rows number
   ) as mle module sample_data_module signature 'generateSampleEmail';
end "GENERATE_SAMPLE_DATA";
/