alter session set container = freepdb1;

grant select on "SYS"."V_$SESSION" to demouser;
