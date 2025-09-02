-- this script assumes that you are either connected to CDB$ROOT either
-- as SYS or SYSTEM. It assumes you are using the Oracle Database 23ai Free
-- container image.
--
-- ADJUST THE PATHS IF NEEDED!
-- 
-- NOTE: you _must_ run this script in SQLcl

-- create a new PDB to simulate production
whenever sqlerror exit
declare
  l_con_name varchar2(255);
  l_username varchar2(255);
begin
  select
     sys_context('USERENV', 'CON_NAME') into l_con_name;
  if l_con_name != 'CDB$ROOT' then
    raise_application_error(-20001, 'must execute this script in CDB$ROOT');
  end if;

  select
    user into l_username;
  
  if user != 'SYS' then
    raise_application_error(-20002, 'must be connected as SYS to this script');
  end if;
end;
/

-- CHANGE THIS PATH if you don't use the container image
alter system set db_create_file_dest = '/opt/oracle/oradata' scope = both;

-- create your simulated "production" environment. It's intentionally created before
-- the PDB clone to allow a subset of privileges to be granted to the production
-- user/schema.
create pluggable database prodpdb from freepdb1;
alter pluggable database prodpdb open;
alter pluggable database prodpdb save state;

-- setup for the "development" database
alter session set container = freepdb1;

accept v_freepdb1_pwd prompt 'choose a password for your account in freepdb1: '

create user demouser identified by "&v_freepdb1_pwd"
  default tablespace users
  temporary tablespace temp
  quota 100M on users;

grant db_developer_role to demouser;

-- setup for the "production" database
alter session set container = prodpdb;

accept v_prodpdb_pwd prompt 'choose a password for your account in prodpdb: '

-- you shouldn't grant db_developer_role to a production account. Only grant
-- the privileges that are absolutely necessary. In this case they are direct
-- grants, more elaborate configurations merit the use of roles.
create user demouser identified by "&v_prodpdb_pwd"
  default tablespace users
  temporary tablespace temp
  quota 100M on users;

grant create session to demouser;
grant create table to demouser;
grant create view to demouser;
grant create procedure to demouser;
grant create sequence to demouser;
grant create trigger to demouser;
grant create type to demouser;
grant create synonym to demouser;
grant create mle to demouser;

-- named connections are required for SQLcl projects
connect -save development -replace -savepwd demouser/"&v_freepdb1_pwd"@localhost/freepdb1

exec ords.enable_schema;
commit;

connect -save production -replace -savepwd demouser/"&v_prodpdb_pwd"@localhost/prodpdb

-- no need to enable the schema, this is done by SQLcl project's workflow