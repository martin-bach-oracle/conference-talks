-- this script assumes that you are either connected to CDB$ROOT either
-- as SYS or SYSTEM.
-- 
-- you _must_ run this script in SQLcl

alter session set container = freepdb1;

accept v_devuser_pwd prompt 'Enter password for devuser: '
accept v_produser_pwd prompt 'Enter password for produser: '

create user devuser identified by "&v_devuser_pwd"
  default tablespace users
  temporary tablespace temp
  quota 100M on users;

grant db_developer_role to devuser;

-- you shouldn't grant db_developer_role to a production account. Only grant
-- the privileges that are absolutely necessary. In this case they are direct
-- grants, more elaborate configurations merit the use of roles.
create user produser identified by "&v_produser_pwd"
  default tablespace users
  temporary tablespace temp
  quota 100M on users;

grant create session to produser;
grant create table to produser;
grant create view to produser;
grant create procedure to produser;
grant create sequence to produser;
grant create trigger to produser;
grant create type to produser;
grant create synonym to produser;
grant create mle to produser;

-- named connections are required for SQLcl projects
connect -save devuser -replace -savepwd devuser/"&v_devuser_pwd"@localhost/freepdb1

exec ords.enable_schema;

connect -save produser -replace -savepwd produser/"&v_produser_pwd"@localhost/freepdb1

exec ords.enable_schema;