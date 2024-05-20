set time on timing on
spool &1/stats_backup_collect_&2
SELECT name from v$database ;

Create  user ACS_STATS identified by Welcome1;
grant connect,resource to ACS_STATS;
alter user ACS_STATS quota unlimited on USERS;

set serveroutput on 
set time on timing on
set line 400
col OPERATION for a30
col TARGET for a30
col USERNAME for a30
col END_TIME for a40
select operation, target, end_time from dba_optstat_operations
where ( (operation = 'gather_fixed_objects_stats')
or (operation = 'gather_dictionary_stats' and (target is null or target in ('SYS', 'SYSTEM'))) or (operation = 'gather_schema_stats' and target in ('SYS', 'SYSTEM'))) and end_time > sysdate - 7 order by  end_time;

select tablespace_name,autoextensible,sum(bytes/1024/1024/1024) "Allocated_GB",sum(maxbytes/1024/1024/1024) "Maxsize_GB" from dba_data_files where tablespace_name='USERS' group by tablespace_name,autoextensible order by 1;

select tablespace_name,sum(bytes/1024/1024/1024) "Free_GB" from dba_free_space where tablespace_name='USERS' group by tablespace_name order by 1;
select USERNAME,DEFAULT_TABLESPACE,TEMPORARY_TABLESPACE from dba_users where username='ACS_STATS';

 -- Stats backup

EXEC DBMS_STATS.CREATE_STAT_TABLE('ACS_STATS','DICT_STATS_DUMP');
EXEC DBMS_STATS.CREATE_STAT_TABLE('ACS_STATS','FIXED_STATS_DUMP');
EXEC DBMS_STATS.EXPORT_DICTIONARY_STATS('DICT_STATS_DUMP','DICT_STATS','ACS_STATS');
EXEC DBMS_STATS.EXPORT_FIXED_OBJECTS_STATS('FIXED_STATS_DUMP','FIXED_STATS','ACS_STATS');

 
-- stats collect 

EXEC DBMS_STATS.GATHER_DICTIONARY_STATS;
EXECUTE DBMS_STATS.GATHER_FIXED_OBJECTS_STATS;

 
@/u02/shared/app/oracle_acs/scripts/bug_25286819_stats_gather.sql


set serveroutput on 
set time on timing on
set line 400
col OPERATION for a30
col TARGET for a30
col USERNAME for a30
col END_TIME for a40
select operation, target, end_time from dba_optstat_operations
where ( (operation = 'gather_fixed_objects_stats')
or (operation = 'gather_dictionary_stats' and (target is null or target in ('SYS', 'SYSTEM'))) or (operation = 'gather_schema_stats' and target in ('SYS', 'SYSTEM'))) and end_time > sysdate - 7 order by  end_time;

select tablespace_name,autoextensible,sum(bytes/1024/1024/1024) "Allocated_GB",sum(maxbytes/1024/1024/1024) "Maxsize_GB" from dba_data_files where tablespace_name='USERS' group by tablespace_name,autoextensible order by 1;

select tablespace_name,sum(bytes/1024/1024/1024) "Free_GB" from dba_free_space where tablespace_name='USERS' group by tablespace_name order by 1;
select USERNAME,DEFAULT_TABLESPACE,TEMPORARY_TABLESPACE from dba_users where username='ACS_STATS';

spool off;
