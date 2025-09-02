prompt Invalid object counts (INVALID status only):

set define on
define schemas="DEMOUSER"

var p_schemas varchar2(4000)
exec :p_schemas :='&schemas';

set feedback off pagesize 100 linesize 150 heading on
set serveroutput ON

-- check currently invalid
column owner format a20
select owner,
       object_type,
       count(*) as compilation_needed
  from dba_objects
 where owner in (
     select upper(regexp_substr(:p_schemas,'[^,]+', 1, level)) schema
     from dual
     connect by regexp_substr(:p_schemas, '[^,]+', 1, level) is not null
     )
   and status = 'INVALID'
   and object_name not like 'BIN$%'
 group by owner,
          object_type
 order by owner,
          object_type;

prompt
prompt Compiling invalid objects...
prompt

-- compile invalid
declare
  l_schemas sys.odcivarchar2list;
begin
  select regexp_substr(:p_schemas, '[^,]+', 1, level)
  bulk collect into l_schemas
  from dual
  connect by regexp_substr(:p_schemas, '[^,]+', 1, level) is not null;

  for rec in (
   select username from dba_users
   where username in (
     select upper(column_value) schema
     from table(cast(multiset(select regexp_substr(:p_schemas, '[^,]+', 1, level)
                                from dual
                               connect by regexp_substr(:p_schemas, '[^,]+', 1, level) is not null) as sys.odcivarchar2list))
    )
    order by username
  ) loop
    dbms_output.put('Compiling '||rec.username||' ...');
    dbms_utility.compile_schema(
                               rec.username,
                               false
    );
    dbms_output.put_line('Done!');
  end loop;
end;
/

prompt
prompt Invalid object counts after recompilation (INVALID status + synonyms with missing targets):

--column owner format a20
with synonyms as (
  select owner,
         synonym_name,
         table_owner,
         table_name
    from dba_synonyms
   where owner in (
    select upper(regexp_substr(:p_schemas, '[^,]+', 1, level)) schema
      from dual
     connect by regexp_substr(:p_schemas, '[^,]+', 1, level) is not null
  )
), synonyms_by_owner as (
  select owner,
         count(*) cnt
    from synonyms
   group by owner
), invalid_synonyms_by_owner as (
  select owner,
         nullif(
           count(
             case
               when not exists(
                 select 1
                   from dba_objects o
                  where s.table_name = o.object_name
                    and s.table_owner = o.owner
               ) then
                 1
             end
           ),
           0
         ) cnt
    from synonyms s
   group by owner
)
select owner,
       object_type,
       count(*) as object_count,
       nullif(
         count(nullif(
           status,
           'VALID'
         )),
         0
       ) as invalid_count
  from dba_objects
 where owner in (
  select upper(regexp_substr(:p_schemas, '[^,]+', 1, level)) schema
    from dual
   connect by regexp_substr(:p_schemas, '[^,]+', 1, level) is not null
)
   and object_type != 'SYNONYM'
   and object_name not like 'BIN$%'
 group by owner,
          object_type
union
select sbo.owner,
       'SYNONYM' object_type,
       sbo.cnt total_count,
       nullif(
         isbo.cnt,
         0
       ) invalid_count
  from synonyms_by_owner sbo
  left join invalid_synonyms_by_owner isbo
on sbo.owner = isbo.owner
 order by owner,
          object_type;

set feedback on

prompt
prompt Invalid objects:

column invalid_object format a50
select owner,
       object_type
       || ' '
       || object_name as invalid_object
  from dba_objects
 where status = 'INVALID'
   and owner in (
  select upper(regexp_substr(:p_schemas, '[^,]+', 1, level)) schema
    from dual
   connect by regexp_substr(:p_schemas, '[^,]+', 1, level) is not null
)
   and object_type != 'SYNONYM'
   and object_name not like 'BIN$%'
union
select s.owner,
       'SYNONYM ' || s.synonym_name invalid_object
  from dba_synonyms s
 where owner in (
  select upper(regexp_substr(:p_schemas, '[^,]+', 1, level)) schema
    from dual
   connect by regexp_substr(:p_schemas, '[^,]+', 1, level) is not null
)
   and not exists (
  select 1
    from dba_objects o
   where o.object_name = s.table_name
     and o.owner = s.table_owner
)
order by 2;

prompt
prompt Compilation errors:
column error_location format a50
column error_text format a50
select owner,
       type
       || ' '
       || name
       || ' '
       || line
       || ','
       || position as error_location,
       text as error_text
  from dba_errors
 where owner in
   (
     select upper(regexp_substr(:p_schemas, '[^,]+', 1, level)) schema
     from dual
     connect by regexp_substr(:p_schemas, '[^,]+', 1, level) is not null
     )
   and text not like 'PL/SQL: ORA-06575: %' /*Package or function is in an invalid state*/
   and text not like 'PLS-00905: %' /*object is invalid*/
   and name not like 'BIN$%'
union
select s.owner,
       'SYNONYM ' || synonym_name error_location,
       'Synonym target does not exist'
  from dba_synonyms s
 where owner in (
  select upper(regexp_substr(:p_schemas, '[^,]+', 1, level)) schema
    from dual
   connect by regexp_substr(:p_schemas, '[^,]+', 1, level) is not null
)
   and not exists (
  select 1
    from dba_objects o
   where o.object_name = s.table_name
     and o.owner = s.table_owner
)
order by 1, 2;

set feedback off

select count(*) as "Other compilation errors not listed"
  from dba_errors
 where owner in
   (
     select upper(regexp_substr(:p_schemas, '[^,]+', 1, level)) schema
     from dual
     connect by regexp_substr(:p_schemas, '[^,]+', 1, level) is not null
   )
   and ( text like 'PL/SQL: ORA-06575: %' /*Package or function is in an invalid state*/
    or text like 'PLS-00905: %' /*object is invalid*/ )
   and name not like 'BIN$%';