set line 400
set pages 999
col OWNER for a20
col TRIGGERING_EVENT for a30
col TRIGGER_NAME for  a30
col WRL_PARAMETER for a90
col PARAMETER for a20
col VALUE for a20
col KEY_ID for a40
col ACTIVATING_PDBNAME for a10
col CREATOR_PDBNAME for a10
col inst_id for 9999 head INST
col instance_name for a10 head INST_NAME
col tag for a32
col USED_SPACE_GB for 9,999,999,999
col ALLOC_SPACE_GB for 9,999,999,999
col MAX_SPACE_GB for 9,999,999,999
col file_name for a80
col OBJECT_NAME for a30
col TABLE_NAME for a30
col TABLESPACE_NAME for a30
col PROPERTY_NAME for a35
col property_value for a20
col db_link for a18
col username for a20
col host for a50
col OWNER for a30
col NAME for a30
COL comp_name FOR a44 HEA 'Component'
COL version FOR a17 HEA 'Version'
COL VERSION_FULL FOR a17 HEA 'VERSION_FULL'
COL status FOR a17 HEA 'Status'
col OPERATION for a30
col TARGET for a30
col END_TIME for a40

prompt ###########################################################
prompt Database  status
prompt ###########################################################

SELECT name,db_unique_name,VERSION,open_mode,logins,INSTANCE_NAME,host_name,dbid,TO_CHAR(STARTUP_TIME,'DD-MON-YYYY HH24:MI:SS'),STATUS,database_role,log_mode FROM v$database,gv$INSTANCE;

prompt ###########################################################
prompt Database Size 
prompt ###########################################################

select	round(sum(used.bytes) / 1024 / 1024 / 1024 ) || ' GB' "Database Size"
		,	round(sum(used.bytes) / 1024 / 1024 / 1024 ) - 
			round(free.p / 1024 / 1024 / 1024) || ' GB' "Used space"
		,	round(free.p / 1024 / 1024 / 1024) || ' GB' "Free space"
		from    (select	bytes
			from	v$datafile
			union	all
			select	bytes
			from 	v$tempfile
			union 	all
			select 	bytes
			from 	v$log) used
		,	(select sum(bytes) as p
			from dba_free_space) free
		group by free.p;
		

prompt ###########################################################
prompt Verify encryption status
prompt ###########################################################

select a.inst_id, b.instance_name,  key_id, a.tag
from v$encryption_keys a ,v$instance b
where a.inst_id(+)=b.inst_id
order by 1;

 select * from v$encryption_wallet;
 
 select TABLESPACE_NAME,ENCRYPTED,STATUS from dba_tablespaces;

prompt ###########################################################
prompt Check block size of TBS
prompt ###########################################################

select distinct BLOCK_SIZE from dba_tablespaces ;
sho parameter db_%k_cache_size

prompt ###########################################################
prompt  Check Component status
prompt ###########################################################

SELECT comp_name, version, status FROM dba_registry;

prompt ###########################################################
prompt  Ensure all objects owned by SYS are VALID
prompt ###########################################################

select substr(object_name,1,40) object_name,substr(owner,1,15) owner,object_type from dba_objects where status='INVALID' and owner like '%SYS%' order by owner,object_type;


prompt ###########################################################
prompt  List of  all INVALID  objects
prompt ###########################################################

select substr(object_name,1,40) object_name,substr(owner,1,15) owner,object_type from dba_objects where status='INVALID' order by owner,object_type;

prompt ###########################################################
prompt Ensure sufficient space available in source PDB SYSTEM, SYSAUX , UNDO tablespaces
prompt ###########################################################

select
a.tablespace_name,round(sum(a.bytes)/(1024*1024*1024),2) "USED_SPACE_GB",
(select sum(b.bytes)/(1024*1024*1024)
from dba_data_files b
where a.tablespace_name=b.tablespace_name
group by b.tablespace_name) "ALLOC_SPACE_GB",
(select
sum(greatest(b.bytes/(1024*1024*1024),b.maxbytes/(1024*1024*1024)))
from dba_data_files b
where a.tablespace_name=b.tablespace_name
group by b.tablespace_name) "MAX_SPACE_GB",
round((
(select sum(c.bytes)/(1024*1024*1024)
from dba_segments c,dba_tablespaces d
where c.tablespace_name=d.tablespace_name and a.tablespace_name=d.tablespace_name
group by d.tablespace_name)*100/
(select sum(greatest(b.bytes/(1024*1024*1024),b.maxbytes/(1024*1024*1024)))
from dba_data_files b
where a.tablespace_name=b.tablespace_name
group by b.tablespace_name)
),0) "PCT USED"
from dba_segments a
group by a.tablespace_name
order by a.tablespace_name;

prompt ###########################################################
prompt  Check Temporary tablespace usage
prompt ###########################################################

select d.TABLESPACE_NAME, d.FILE_NAME, d.BYTES/1024/1024 SIZE_MB, d.AUTOEXTENSIBLE, d.MAXBYTES/1024/1024 MAXSIZE_MB, d.INCREMENT_BY*(v.BLOCK_SIZE/1024)/1024 INCREMENT_BY_MB
from dba_temp_files d,
 v$tempfile v
where d.FILE_ID = v.FILE#
order by d.TABLESPACE_NAME, d.FILE_NAME;

select tablespace_name,file_name,AUTOEXTENSIBLE from dba_data_files where tablespace_name like '%SYS%';

prompt ###########################################################
prompt Check Character set at source DB
prompt ###########################################################

select * from nls_database_parameters where parameter='NLS_CHARACTERSET' ;

prompt ###########################################################
prompt  Ensure that you do not have duplicate objects in the SYS and SYSTEM schema.
prompt ###########################################################

select object_name, object_type from  dba_objects where 
object_name||object_type in (select object_name||object_type from dba_objects where owner = 'SYS') and owner = 'SYSTEM'; 

prompt ###########################################################
prompt Count of recyclebin : Check if count is huge , 60K entires took 2 hours to purge , advised to purge before upgrade window 
prompt ###########################################################

 select count(1) from DBA_RECYCLEBIN;

prompt ###########################################################
prompt Check if indoubt transaction
prompt ###########################################################

select * from dba_2pc_pending;
select * from dba_2pc_neighbors;
select * from sys.pending_trans$;
select * from sys.pending_sessions$;
select * from sys.pending_sub_sessions$;


prompt ###########################################################
prompt Check and Verify AUD$ table not exists on the encrypted tablespace,if exists Please decrypt the tablespace on source PDB before performing remote clone:
prompt ###########################################################

SELECT tablespace_name, encrypted FROM dba_tablespaces;
SELECT table_name, tablespace_name FROM dba_tables WHERE table_name='AUD$';
SELECT table_name, tablespace_name FROM dba_tables WHERE table_name='FGA_LOG$';
SELECT table_name, tablespace_name FROM dba_tables WHERE table_name='AUD$UNIFIED';
select t.name,e.ENCRYPTIONALG,e.ENCRYPTEDTS from V$ENCRYPTED_TABLESPACES e, v$tablespace t where t.ts#=e.ts#(+) and t.name in (SELECT tablespace_name FROM dba_tables WHERE table_name in ('AUD$','FGA_LOG$','AUD$UNIFIED'));

prompt ###########################################################
prompt Check AUD$ count
prompt ###########################################################
select count(1) from sys.aud$;
sho parameter audit;

prompt ###########################################################
prompt  Checking Time zone settings source DB
prompt ###########################################################

SELECT PROPERTY_NAME, property_value
FROM DATABASE_PROPERTIES
WHERE PROPERTY_NAME LIKE '%DST%';

prompt ###########################################################
prompt DBLINKs
prompt ###########################################################

select owner,db_link,username,host,created from dba_db_links;


sho parameter job_queue_processes
sho parameter optimizer_capture_sql_plan_baselines
sho parameter optimizer_use_sql_plan_baselines
sho parameter SGA_MAX_SIZE                   
sho parameter SGA_TARGET                     
sho parameter PGA_AGGREGATE_LIMIT            
sho parameter PGA_AGGREGATE_TARGET           
sho parameter MEMORY_TARGET
sho parameter CACHE_SIZE              
sho parameter STREAMS_POOL_SIZE 
sho parameter cpu
sho parameter parallel_max_server
sho parameter parallel_min_server
sho parameter local
sho parameter optimizer
sho parameter compatible

prompt ###########################################################
prompt  Check materialized views
prompt ###########################################################

SELECT o.name FROM sys.obj$ o, sys.user$ u, sys.sum$ s WHERE o.type# = 42 AND bitand(s.mflags, 8) =8;

prompt ###########################################################
prompt  Check  Stats refresh done past 7 days or not 
prompt ###########################################################

select  operation, target, end_time from dba_optstat_operations
where ( (operation = 'gather_fixed_objects_stats')
or (operation = 'gather_dictionary_stats' and (target is null or target in ('SYS', 'SYSTEM'))) or (operation = 'gather_schema_stats' and target in ('SYS', 'SYSTEM'))) and end_time > sysdate - 7 order by  end_time;


prompt ###########################################################
prompt  Check datafile details
prompt ###########################################################
set lines 200 pages 1235
col name for a120
select name,status,sum(bytes/1024/1024/1024) Size_GB from v$datafile group by name,status order by 3 desc;

prompt ###########################################################
prompt  Confirm application are down and no active connections
prompt ###########################################################

 select sid,serial#,username from v$session where username not in ('SYS','SYSTEM');


prompt ###########################################################
prompt  verify that no files need media recovery and that no files are in backup mode
prompt ###########################################################

SELECT * FROM v$recover_file;
SELECT * FROM v$backup WHERE status != 'NOT ACTIVE';


prompt ###########################################################
prompt  Create Password file  not required if remote_login_passwordfile = NONE 
prompt ###########################################################

show parameter password 
select * from v$pwfile_users;

prompt ###########################################################
prompt Check user password_version is 10G
prompt ###########################################################

select USERNAME,ACCOUNT_STATUS,PASSWORD_VERSIONS from DBA_USERS where ( PASSWORD_VERSIONS = '10G ' or PASSWORD_VERSIONS = '10G HTTP ') and USERNAME <> 'ANONYMOUS';


prompt ###########################################################
prompt  Get current SCN
prompt ###########################################################

select to_char(current_scn) from v$database;
select systimestamp from dual;

prompt ###########################################################
--prompt  Reset diag location to 19c and create pfile for upgrade
prompt ###########################################################

show parameter audit_file_dest
show parameter diagnostic_dest

--alter system set audit_file_dest='&2admin/&1/adump' scope=spfile;
--alter system set diagnostic_dest='&2' scope=spfile ;
--alter system set db_recovery_file_dest_size=50G scope=spfile;
--alter system set db_recovery_file_dest='/b01/tst/odbs504_zfs02b/oradata/doax/backup/rman_fra' scope=spfile ;
--create pfile='&3/init&1_19c.ora' from spfile;


prompt ###########################################################
prompt  Check Verify flashback enabled
prompt ###########################################################

select flashback_on from v$database;
sho parameter db_recovery_file_dest_size
sho parameter db_recovery_file_dest


prompt ###########################################################
prompt Check any custom triggers that would get executed before / after DDL statements. Re-enable them after the upgrade
prompt ###########################################################

select owner,trigger_name,triggering_event,trigger_type,status from dba_triggers where triggering_event like '%DDL%';

prompt ###########################################################
prompt  Capture triggers which needs to be enabled post upgrade review and run enable_trigger.sql
prompt ###########################################################


set lines 300 pages 9999
set heading off
spool &3/enable_trigger.sql
SELECT 'ALTER TRIGGER ' ||owner||  '.' ||trigger_name||' ENABLE;' "ALTER Statement"  FROM dba_triggers WHERE triggering_event like '%DDL%' and STATUS='ENABLED';
spool off;

prompt ###########################################################
prompt Capture triggeres which needs to be disabled now , review and run disable_trigger.sql
prompt ###########################################################

set lines 300 pages 9999
set heading off
spool &3/disable_trigger.sql
SELECT 'ALTER TRIGGER ' ||owner||  '.' ||trigger_name||' DISABLE;' "ALTER Statement"  FROM dba_triggers WHERE triggering_event like '%DDL%' and STATUS='ENABLED';
spool off;

