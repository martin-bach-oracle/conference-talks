--liquibase formatted sql
--changeset mcb:r1-07 failonerror:true labels:r1 endDelimiter:/ stripComments:false

create or replace package DEMO_THINGS_PKG as

    function validatePrice(p_price varchar2)       return boolean as mle module DEMO_THINGS_MODULE env validator_env signature 'validatePrice';
    function validateAvailable(p_date varchar2)    return boolean as mle module DEMO_THINGS_MODULE env validator_env signature 'validateAvailable';
    function validateQuantity(p_quantity varchar2) return boolean as mle module DEMO_THINGS_MODULE env validator_env signature 'validateQuantity';

    procedure consolidateThingWarehouses(p_thingID varchar2) as mle module DEMO_THINGS_MODULE env validator_env signature 'consolidateThingWarehouses';

end DEMO_THINGS_PKG;
/