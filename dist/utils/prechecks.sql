-- prechecks.sql
set serverout on feedback off

prompt Checking SQLcl version...
column  _SQLPLUS_RELEASE    new_value   _SQLPLUS_RELEASE
column  _PWD                new_value   _PWD
select
    null "_SQLPLUS_RELEASE",
    null "_PWD"
from sys.dual
where 1=2;

begin
    if '&&_SQLPLUS_RELEASE' is null or '&&_PWD' is null then
        raise_application_error(-20001, 'This installer must be run using SQLcl');
    end if;

    if '&&_SQLPLUS_RELEASE' != '2403000000' then
        raise_application_error(-20001, 'This installer must be run using SQLcl 24.3.0');
    end if;

end;
/

-- prompt Checking minimum database version...
-- declare
--     c_min_db_version constant number := 19;
--     c_min_db_release constant number := 0;
-- begin
--     sys.dbms_output.put_line(sys.dbms_db_version.version || '.' || sys.dbms_db_version.release);
--     if sys.dbms_db_version.version < c_min_db_version
--     or (sys.dbms_db_version.version = c_min_db_version and sys.dbms_db_version.release < c_min_db_release)
--     then
--         sys.dbms_output.put_line('FAILED');
--         raise_application_error(-20000, 'Minimum database version is ' || c_min_db_version || '.' || c_min_db_release || '.');
--     end if;
-- end;
-- /

-- prompt Checking session character Set...
-- declare
--     l_nls_characterset nls_database_parameters.value%type;
-- begin
--     select value
--     into l_nls_characterset
--     from nls_database_parameters
--     where parameter = 'NLS_CHARACTERSET';
--     sys.dbms_output.put_line(l_nls_characterset);
--     if ascii('ú') != 50106 then
--         sys.dbms_output.put_line('FAILED');
--         raise_application_error(-20000, 'Character set not AL32UTF8. Set environment variable NLS_LANG=.AL32UTF8 for sqlplus, or JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF-8 for sqlcl.');
--     end if;
-- end;
-- /

-- prompt Checking minimum APEX version...
-- declare
--     c_min_apex_version constant number := 23;
--     c_min_apex_release constant number := 1;
--     l_version dba_registry.version%type;
--     l_version_no number;
--     l_release_no number;
-- begin
--     select version into l_version from dba_registry where comp_id = 'APEX';
--     sys.dbms_output.put_line(l_version);
--     l_version_no := to_number(substr(l_version, 1, instr(l_version, '.')-1));
--     l_release_no := to_number(substr(l_version, instr(l_version, '.')+1, instr(l_version, '.', 1, 2) - instr(l_version, '.') - 1));
--     if l_version_no < c_min_apex_version
--     or (l_version_no = c_min_apex_version and l_release_no < c_min_apex_release)
--     then
--         sys.dbms_output.put_line('FAILED');
--         raise_application_error(-20000, 'Oracle APEX ' || c_min_apex_version || '.' || c_min_apex_release || ' or later must be installed');
--     end if;
-- exception
--     when no_data_found then
--         sys.dbms_output.put_line('FAILED');
--         raise_application_error(-20000, 'Oracle APEX must be installed (minimum ' || c_min_apex_version || '.' || c_min_apex_release || ')');
-- end;
-- /

prompt Prechecks successful.