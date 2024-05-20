------Script is to collect the information from the database which will be used to perform the impact analysis
------Database Upgrade Impact Analysis Report
------Version Control
------Version 1.0 Manish Madhukar, Guruprasad Ramamurthy And Venu Venkataramana
------Version 2.0 Manish Madhukar And Varun Selot
------Version 3.0 Naved Afroz
------Include server hostname, database name, date and time in name of spool file
set feedback off
set echo off
set verify off
set linesize 180
set pagesize 9999
set pages 999
set trim
set heading on
col hostname new_value host noprint
select sys_context('USERENV','SERVER_HOST',15) hostname from dual;
col dbase new_value db noprint
select sys_context('USERENV','DB_NAME',15) dbase from dual;
col datetime new_value dt noprint
select to_char(sysdate, 'YYYYMMDD-HH24MISS') datetime from dual;
define _spool_file="ACS_UPGRADE_IMPACT_ANALYSIS_&host._&db._&dt..html"
spool &_spool_file
prompt </head> <body> <br> <br> <a href="http://www.oracle.com" target="_blank"><img src="https://www.oracle.com/a/ocom/img/oracle-signature.png" alt="Oracle" width="150" height="35" border="0"></a><br>
prompt <font color="#312D2A" size="5" face="Oracle Sans, Veranda, Arial, Helvetica, sans-serif">Oracle Advanced Customer Support (ACS)<br>
prompt <h1 style="font-size:28px;background-color:SANDYBROWN;">Database Upgrade Impact Analysis Report</h1>
prompt <html>
prompt <head>
prompt <style>
prompt table, th, td {
prompt   border: 1px solid black;
prompt }
prompt </style>
prompt </head>
prompt <body>
prompt </body>
prompt </html>
SET MARKUP HTML ON  PREFORMAT OFF ENTMAP OFF HEAD "<TITLE>DB Info</TITLE> <STYLE type='text/css'> <!-- BODY {background: #FFFFC6} --> </STYLE>" BODY "TEXT='#FF00Ff'" TABLE "WIDTH='90%' BORDER='5'"
set echo off
set feed off
set time on
set head on
set pages 100
set timing off
column name new_value mydbname
set serverout on
alter session set nls_date_format='dd-mon-yyyy hh24:mi:ss';
select name,sysdate as "Script Start Time" from v$database;
set ECHO OFF
set TERMOUT ON
set TAB OFF
set TRIMOUT ON
set PAGESIZE 50000
set LINESIZE 500
set FEEDBACK OFF
set VERIFY OFF
set COLSEP '|'

break on CON_NAME skip page duplicates

CLEAR COLUMNS
col HOST_NAME              format a40 wrap
col INSTANCE_NAME          format a16 wrap
col DATABASE_NAME          format a14 wrap
col OPEN_MODE              format a16 wrap
col RESTRICTED             format a10 wrap
col DATABASE_ROLE          format a16 wrap
col BANNER                 format a80 wrap
col CONNECTED_TO           format a12 wrap
col CON_ID                 format 99999 wrap
col LAST_DBA_FUS_VERSION   format a17 wrap
col PRODUCT                format a51 wrap
col FEATURE_BEING_USED     format a56 wrap
col USAGE                  format a24 wrap
col EXTRA_FEATURE_INFO     format a80 wrap
col CURRENTLY_USED         format a14 wrap
col CURRENT_CONTAINER_NAME format a30 wrap
col CURRENT_CONTAINER_ID   format a20 wrap
col PARAMETER              format a30 wrap
col VALUE                  format a20 wrap
col NAME                                   format a70 wrap
col MEMBER                                 format a70 wrap
col KEY_ID                                 format a50 wrap
col FILE_NAME                      format a70 wrap



Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 1 Database Details</i>
select i.HOST_NAME,
       i.INSTANCE_NAME,
       d.NAME as database_name,
       d.OPEN_MODE,
       d.DATABASE_ROLE,
       d.CREATED,
       d.DBID,
       i.VERSION,
       v.BANNER
  from  V$INSTANCE i, V$DATABASE d, V$VERSION v
  where v.BANNER LIKE 'Oracle%' or v.BANNER like 'Personal Oracle%'
;
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">Database Properties</i>
select * from database_properties order by 1;

Prompt <i style="font-size:20px;background-color:POWDERBLUE;">Controlfile Information</i>
select NAME from v$controlfile;

Prompt <i style="font-size:20px;background-color:POWDERBLUE;">Datafiles Information</i>
select file_name from dba_data_files;

Prompt <i style="font-size:20px;background-color:POWDERBLUE;">Tempfile Information</i>
select NAME from v$tempfile;

Prompt <i style="font-size:20px;background-color:POWDERBLUE;">Logfile Information</i>
select * from v$logfile;

Prompt <i style="font-size:20px;background-color:POWDERBLUE;">Spfile and other parameters Information</i>
show parameter spfile
show parameter name

Prompt <i style="font-size:20px;background-color:POWDERBLUE;">Encryption Keys Information</i>
select con_id,KEY_ID from v$encryption_keys order by 1;

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 2 Component Usage</i>
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">Output from V$option</i>
select * from v$option where value='TRUE' order by 1;

Prompt <i style="font-size:18px;background-color:POWDERBLUE;">MULTITENANT INFORMATION (Please ignore errors in pre 12.1 databases)</i>
col NAME format a30 wrap

select c.CON_ID, c.NAME, c.OPEN_MODE, c.RESTRICTED,
    case when c.OPEN_MODE not like 'READ%' and c.CON_ID = sys_context('USERENV', 'CON_ID') and c.CON_ID != 0 then
              'NOT OPEN! DBA_FEATURE_USAGE_STATISTICS is not accessible. *CURRENT CONTAINER'
         when c.OPEN_MODE not like 'READ%' then
              'NOT OPEN! DBA_FEATURE_USAGE_STATISTICS is not accessible.'
         when c.CON_ID = sys_context('USERENV', 'CON_ID') and d.CDB='YES' and c.CON_ID not in (0, 1) then
              '*CURRENT CONTAINER. Only data for this PDB will be listed.'
         when c.CON_ID = sys_context('USERENV', 'CON_ID') and d.CDB='YES' and c.CON_ID = 1 then
              '*CURRENT CONTAINER is CDB$ROOT. Information for all open PDBs will be listed.'
         else ''
    end as REMARKS
    from V$CONTAINERS c, V$DATABASE d
    order by CON_ID;
prompt
prompt <i style="font-size:14px;">The multitenant architecture with one user-created pluggable database (single tenant) is available in all editions without the Multitenant Option.</i>
prompt <i style="font-size:14px;">If more than one PDB containers are created, then Multitenant Option licensing is needed.</i>

col NAME clear

-- Prepare settings for pre 12c databases
define DFUS=DBA_
col DFUS_ new_val DFUS noprint

define DCOL1=CON_ID
col DCOL1_ new_val DCOL1 noprint
define DCID=-1
col DCID_ new_val DCID noprint

col CON_NAME format a30 wrap
define DCOL2=CON_NAME
col DCOL2_ new_val DCOL2 noprint
define DCNA=to_char(NULL)
col DCNA_ new_val DCNA noprint

select 'CDB_' as DFUS_, 'CON_ID' as DCID_, '(select NAME from V$CONTAINERS xz where xz.CON_ID=xy.CON_ID)' as DCNA_, 'XXXXXX' as DCOL1_, 'XXXXXX' as DCOL2_
  from CDB_FEATURE_USAGE_STATISTICS
  where exists (select 1 from V$DATABASE where CDB='YES')
    and rownum=1;

col GID     NOPRINT
-- Hide CON_NAME column for non-Container Databases:
col &&DCOL2 NOPRINT
col &&DCOL1 NOPRINT

-- Detect Oracle Cloud Service Packages
define OCS='N'
col OCS_ new_val OCS noprint
select 'Y' as OCS_ from V$VERSION where BANNER like 'Oracle %Perf%';

Prompt <i style="font-size:18px;background-color:POWDERBLUE;">DBA_FEATURE_USAGE_STATISTICS (DBA_FUS) INFORMATION - MOST RECENT SAMPLE BASED ON LAST_SAMPLE_DATE</i>


select distinct
       &&DCID as CON_ID,
       first_value (DBID            ) over (partition by &&DCID order by last_sample_date desc nulls last) as last_dba_fus_dbid,
       first_value (VERSION         ) over (partition by &&DCID order by last_sample_date desc nulls last) as last_dba_fus_version,
       first_value (LAST_SAMPLE_DATE) over (partition by &&DCID order by last_sample_date desc nulls last) as last_dba_fus_sample_date,
       sysdate,
       case when (select trim(max(LAST_SAMPLE_DATE) || max(TOTAL_SAMPLES)) from &&DFUS.FEATURE_USAGE_STATISTICS) = '0'
            then 'NEVER SAMPLED !!!'
            else ''
       end as REMARKS
from &&DFUS.FEATURE_USAGE_STATISTICS
order by CON_ID
;

col CON_ID  NOPRINT

Prompt <i style="font-size:18px;background-color:POWDERBLUE;">PRODUCT USAGE</i>
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">O/P from dba_feature_usage_statistics detected_usages > 0</i>
select name,version,detected_usages "Usages>0",currently_used "Used",to_char(last_usage_date,'YYYY-MM-DD') "Last used"
from dba_feature_usage_statistics
where version = (select version from V$INSTANCE) and detected_usages > 0
order by 1,currently_used;

Prompt <i style="font-size:18px;background-color:POWDERBLUE;">Other Usage Statistics for Database Options, Management Packs</i>
with
MAP as (
-- mapping between features tracked by DBA_FUS and their corresponding database products (options or packs)
select '' PRODUCT, '' feature, '' MVERSION, '' CONDITION from dual union all
SELECT 'Active Data Guard'                                   , 'Active Data Guard - Real-Time Query on Physical Standby' , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Active Data Guard'                                   , 'Global Data Services'                                    , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Active Data Guard or Real Application Clusters'      , 'Application Continuity'                                  , '^1[89]\.|^2[0-9]\.'                           , ' '       from dual union all
SELECT 'Advanced Analytics'                                  , 'Data Mining'                                             , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'ADVANCED Index Compression'                              , '^12\.'                                        , 'BUG'     from dual union all
SELECT 'Advanced Compression'                                , 'Advanced Index Compression'                              , '^12\.'                                        , 'BUG'     from dual union all
SELECT 'Advanced Compression'                                , 'Advanced Index Compression'                              , '^1[89]\.|^2[0-9]\.'                           , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup HIGH Compression'                                 , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup LOW Compression'                                  , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup MEDIUM Compression'                               , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup ZLIB Compression'                                 , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Data Guard'                                              , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'Flashback Data Archive'                                  , '^11\.2\.0\.[1-3]\.'                           , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Flashback Data Archive'                                  , '^(11\.2\.0\.[4-9]\.|1[289]\.|2[0-9]\.)'       , 'INVALID' from dual union all -- licensing required by Optimization for Flashback Data Archive
SELECT 'Advanced Compression'                                , 'HeapCompression'                                         , '^11\.2|^12\.1'                                , 'BUG'     from dual union all
SELECT 'Advanced Compression'                                , 'HeapCompression'                                         , '^12\.[2-9]|^1[89]\.|^2[0-9]\.'                , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Heat Map'                                                , '^12\.1'                                       , 'BUG'     from dual union all
SELECT 'Advanced Compression'                                , 'Heat Map'                                                , '^12\.[2-9]|^1[89]\.|^2[0-9]\.'                , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Hybrid Columnar Compression Row Level Locking'           , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Information Lifecycle Management'                        , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Advanced Network Compression Service'             , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Utility Datapump (Export)'                        , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Utility Datapump (Import)'                        , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'SecureFile Compression (user)'                           , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'SecureFile Deduplication (user)'                         , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'ASO native encryption and checksumming'                  , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'INVALID' from dual union all -- no longer part of Advanced Security
SELECT 'Advanced Security'                                   , 'Backup Encryption'                                       , '^11\.2'                                       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Backup Encryption'                                       , '^1[289]\.|^2[0-9]\.'                          , 'INVALID' from dual union all -- licensing required only by encryption to disk
SELECT 'Advanced Security'                                   , 'Data Redaction'                                          , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Encrypted Tablespaces'                                   , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Oracle Utility Datapump (Export)'                        , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C002'    from dual union all
SELECT 'Advanced Security'                                   , 'Oracle Utility Datapump (Import)'                        , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C002'    from dual union all
SELECT 'Advanced Security'                                   , 'SecureFile Encryption (user)'                            , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Transparent Data Encryption'                             , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Change Management Pack'                              , 'Change Management Pack'                                  , '^11\.2'                                       , ' '       from dual union all
SELECT 'Configuration Management Pack for Oracle Database'   , 'EM Config Management Pack'                               , '^11\.2'                                       , ' '       from dual union all
SELECT 'Data Masking Pack'                                   , 'Data Masking Pack'                                       , '^11\.2'                                       , ' '       from dual union all
SELECT '.Database Gateway'                                   , 'Gateways'                                                , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.Database Gateway'                                   , 'Transparent Gateway'                                     , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Database In-Memory'                                  , 'In-Memory ADO Policies'                                  , '^1[89]\.|^2[0-9]\.'                           , ' '       from dual union all -- part of In-Memory Column Store
SELECT 'Database In-Memory'                                  , 'In-Memory Aggregation'                                   , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Database In-Memory'                                  , 'In-Memory Column Store'                                  , '^12\.1\.0\.2\.'                               , 'BUG'     from dual union all
SELECT 'Database In-Memory'                                  , 'In-Memory Column Store'                                  , '^12\.1\.0\.[3-9]\.|^12\.2|^1[89]\.|^2[0-9]\.' , ' '       from dual union all
SELECT 'Database In-Memory'                                  , 'In-Memory Distribute For Service (User Defined)'         , '^1[89]\.|^2[0-9]\.'                           , ' '       from dual union all -- part of In-Memory Column Store
SELECT 'Database In-Memory'                                  , 'In-Memory Expressions'                                   , '^1[89]\.|^2[0-9]\.'                           , ' '       from dual union all -- part of In-Memory Column Store
SELECT 'Database In-Memory'                                  , 'In-Memory FastStart'                                     , '^1[89]\.|^2[0-9]\.'                           , ' '       from dual union all -- part of In-Memory Column Store
SELECT 'Database In-Memory'                                  , 'In-Memory Join Groups'                                   , '^1[89]\.|^2[0-9]\.'                           , ' '       from dual union all -- part of In-Memory Column Store
SELECT 'Database Vault'                                      , 'Oracle Database Vault'                                   , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Database Vault'                                      , 'Privilege Capture'                                       , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'ADDM'                                                    , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Baseline'                                            , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Baseline Template'                                   , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Report'                                              , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Automatic Workload Repository'                           , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Baseline Adaptive Thresholds'                            , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Baseline Static Computations'                            , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Diagnostic Pack'                                         , '^11\.2'                                       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'EM Performance Page'                                     , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.Exadata'                                            , 'Cloud DB with EHCC'                                      , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT '.Exadata'                                            , 'Exadata'                                                 , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT '.GoldenGate'                                         , 'GoldenGate'                                              , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.HW'                                                 , 'Hybrid Columnar Compression'                             , '^12\.1'                                       , 'BUG'     from dual union all
SELECT '.HW'                                                 , 'Hybrid Columnar Compression'                             , '^12\.[2-9]|^1[89]\.|^2[0-9]\.'                , ' '       from dual union all
SELECT '.HW'                                                 , 'Hybrid Columnar Compression Conventional Load'           , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.HW'                                                 , 'Hybrid Columnar Compression Row Level Locking'           , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.HW'                                                 , 'Sun ZFS with EHCC'                                       , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.HW'                                                 , 'ZFS Storage'                                             , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.HW'                                                 , 'Zone maps'                                               , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Label Security'                                      , 'Label Security'                                          , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Multitenant'                                         , 'Oracle Multitenant'                                      , '^1[289]\.|^2[0-9]\.'                          , 'C003'    from dual union all -- licensing required only when more than one PDB containers are created
SELECT 'Multitenant'                                         , 'Oracle Pluggable Databases'                              , '^1[289]\.|^2[0-9]\.'                          , 'C003'    from dual union all -- licensing required only when more than one PDB containers are created
SELECT 'OLAP'                                                , 'OLAP - Analytic Workspaces'                              , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'OLAP'                                                , 'OLAP - Cubes'                                            , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Partitioning'                                        , 'Partitioning (user)'                                     , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Partitioning'                                        , 'Zone maps'                                               , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.Pillar Storage'                                     , 'Pillar Storage'                                          , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.Pillar Storage'                                     , 'Pillar Storage with EHCC'                                , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.Provisioning and Patch Automation Pack'             , 'EM Standalone Provisioning and Patch Automation Pack'    , '^11\.2'                                       , ' '       from dual union all
SELECT 'Provisioning and Patch Automation Pack for Database' , 'EM Database Provisioning and Patch Automation Pack'      , '^11\.2'                                       , ' '       from dual union all
SELECT 'RAC or RAC One Node'                                 , 'Quality of Service Management'                           , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Real Application Clusters'                           , 'Real Application Clusters (RAC)'                         , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Real Application Clusters One Node'                  , 'Real Application Cluster One Node'                       , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Real Application Testing'                            , 'Database Replay: Workload Capture'                       , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C004'    from dual union all
SELECT 'Real Application Testing'                            , 'Database Replay: Workload Replay'                        , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C004'    from dual union all
SELECT 'Real Application Testing'                            , 'SQL Performance Analyzer'                                , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C004'    from dual union all
SELECT '.Secure Backup'                                      , 'Oracle Secure Backup'                                    , '^1[289]\.|^2[0-9]\.'                          , 'INVALID' from dual union all  -- does not differentiate usage of Oracle Secure Backup Express, which is free
SELECT 'Spatial and Graph'                                   , 'Spatial'                                                 , '^11\.2'                                       , 'INVALID' from dual union all  -- does not differentiate usage of Locator, which is free
SELECT 'Spatial and Graph'                                   , 'Spatial'                                                 , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Automatic Maintenance - SQL Tuning Advisor'              , '^1[289]\.|^2[0-9]\.'                          , 'INVALID' from dual union all  -- system usage in the maintenance window
SELECT 'Tuning Pack'                                         , 'Automatic SQL Tuning Advisor'                            , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'INVALID' from dual union all  -- system usage in the maintenance window
SELECT 'Tuning Pack'                                         , 'Real-Time SQL Monitoring'                                , '^11\.2'                                       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Real-Time SQL Monitoring'                                , '^1[289]\.|^2[0-9]\.'                          , 'INVALID' from dual union all  -- default
SELECT 'Tuning Pack'                                         , 'SQL Access Advisor'                                      , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Monitoring and Tuning pages'                         , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Profile'                                             , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Tuning Advisor'                                      , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Tuning Set (user)'                                   , '^1[289]\.|^2[0-9]\.'                          , 'INVALID' from dual union all -- no longer part of Tuning Pack
SELECT 'Tuning Pack'                                         , 'Tuning Pack'                                             , '^11\.2'                                       , ' '       from dual union all
SELECT '.WebLogic Server Management Pack Enterprise Edition' , 'EM AS Provisioning and Patch Automation Pack'            , '^11\.2'                                       , ' '       from dual union all
select '' PRODUCT, '' FEATURE, '' MVERSION, '' CONDITION from dual
),
FUS as (
-- the current data set to be used: DBA_FEATURE_USAGE_STATISTICS or CDB_FEATURE_USAGE_STATISTICS for Container Databases(CDBs)
select
    &&DCID as CON_ID,
    &&DCNA as CON_NAME,
    -- Detect and mark with Y the current DBA_FUS data set = Most Recent Sample based on LAST_SAMPLE_DATE
      case when DBID || '#' || VERSION || '#' || to_char(LAST_SAMPLE_DATE, 'YYYYMMDDHH24MISS') =
                first_value (DBID    )         over (partition by &&DCID order by LAST_SAMPLE_DATE desc nulls last, DBID desc) || '#' ||
                first_value (VERSION )         over (partition by &&DCID order by LAST_SAMPLE_DATE desc nulls last, DBID desc) || '#' ||
                first_value (to_char(LAST_SAMPLE_DATE, 'YYYYMMDDHH24MISS'))
                                               over (partition by &&DCID order by LAST_SAMPLE_DATE desc nulls last, DBID desc)
           then 'Y'
           else 'N'
    end as CURRENT_ENTRY,
    NAME            ,
    LAST_SAMPLE_DATE,
    DBID            ,
    VERSION         ,
    DETECTED_USAGES ,
    TOTAL_SAMPLES   ,
    CURRENTLY_USED  ,
    FIRST_USAGE_DATE,
    LAST_USAGE_DATE ,
    AUX_COUNT       ,
    FEATURE_INFO
from &&DFUS.FEATURE_USAGE_STATISTICS xy
),
PFUS as (
-- Product-Feature Usage Statitsics = DBA_FUS entries mapped to their corresponding database products
select
    CON_ID,
    CON_NAME,
    PRODUCT,
    NAME as FEATURE_BEING_USED,
    case  when CONDITION = 'BUG'
               --suppressed due to exceptions/defects
               then '3.SUPPRESSED_DUE_TO_BUG'
          when     detected_usages > 0                 -- some usage detection - current or past
               and CURRENTLY_USED = 'TRUE'             -- usage at LAST_SAMPLE_DATE
               and CURRENT_ENTRY  = 'Y'                -- current record set
               and (    trim(CONDITION) is null        -- no extra conditions
                     or CONDITION_MET     = 'TRUE'     -- extra condition is met
                    and CONDITION_COUNTER = 'FALSE' )  -- extra condition is not based on counter
               then '6.CURRENT_USAGE'
          when     detected_usages > 0                 -- some usage detection - current or past
               and CURRENTLY_USED = 'TRUE'             -- usage at LAST_SAMPLE_DATE
               and CURRENT_ENTRY  = 'Y'                -- current record set
               and (    CONDITION_MET     = 'TRUE'     -- extra condition is met
                    and CONDITION_COUNTER = 'TRUE'  )  -- extra condition is     based on counter
               then '5.PAST_OR_CURRENT_USAGE'          -- FEATURE_INFO counters indicate current or past usage
          when     detected_usages > 0                 -- some usage detection - current or past
               and (    trim(CONDITION) is null        -- no extra conditions
                     or CONDITION_MET     = 'TRUE'  )  -- extra condition is met
               then '4.PAST_USAGE'
          when CURRENT_ENTRY = 'Y'
               then '2.NO_CURRENT_USAGE'   -- detectable feature shows no current usage
          else '1.NO_PAST_USAGE'
    end as USAGE,
    LAST_SAMPLE_DATE,
    DBID            ,
    VERSION         ,
    DETECTED_USAGES ,
    TOTAL_SAMPLES   ,
    CURRENTLY_USED  ,
    case  when CONDITION like 'C___' and CONDITION_MET = 'FALSE'
               then to_date('')
          else FIRST_USAGE_DATE
    end as FIRST_USAGE_DATE,
    case  when CONDITION like 'C___' and CONDITION_MET = 'FALSE'
               then to_date('')
          else LAST_USAGE_DATE
    end as LAST_USAGE_DATE,
    EXTRA_FEATURE_INFO
from (
select m.PRODUCT, m.CONDITION, m.MVERSION,
       -- if extra conditions (coded on the MAP.CONDITION column) are required, check if entries satisfy the condition
       case
             when CONDITION = 'C001' and (   regexp_like(to_char(FEATURE_INFO), 'compression[ -]used:[ 0-9]*[1-9][ 0-9]*time', 'i')
                                         and FEATURE_INFO not like '%(BASIC algorithm used: 0 times, LOW algorithm used: 0 times, MEDIUM algorithm used: 0 times, HIGH algorithm used: 0 times)%' -- 12.1 bug - Doc ID 1993134.1
                                          or regexp_like(to_char(FEATURE_INFO), 'compression[ -]used: *TRUE', 'i')                 )
                  then 'TRUE'  -- compression has been used
             when CONDITION = 'C002' and (   regexp_like(to_char(FEATURE_INFO), 'encryption used:[ 0-9]*[1-9][ 0-9]*time', 'i')
                                          or regexp_like(to_char(FEATURE_INFO), 'encryption used: *TRUE', 'i')                  )
                  then 'TRUE'  -- encryption has been used
             when CONDITION = 'C003' and CON_ID=1 and AUX_COUNT > 1
                  then 'TRUE'  -- more than one PDB are created
             when CONDITION = 'C004' and '&&OCS'= 'N'
                  then 'TRUE'  -- not in oracle cloud
             else 'FALSE'
       end as CONDITION_MET,
       -- check if the extra conditions are based on FEATURE_INFO counters. They indicate current or past usage.
       case
             when CONDITION = 'C001' and     regexp_like(to_char(FEATURE_INFO), 'compression[ -]used:[ 0-9]*[1-9][ 0-9]*time', 'i')
                                         and FEATURE_INFO not like '%(BASIC algorithm used: 0 times, LOW algorithm used: 0 times, MEDIUM algorithm used: 0 times, HIGH algorithm used: 0 times)%' -- 12.1 bug - Doc ID 1993134.1
                  then 'TRUE'  -- compression counter > 0
             when CONDITION = 'C002' and     regexp_like(to_char(FEATURE_INFO), 'encryption used:[ 0-9]*[1-9][ 0-9]*time', 'i')
                  then 'TRUE'  -- encryption counter > 0
             else 'FALSE'
       end as CONDITION_COUNTER,
       case when CONDITION = 'C001'
                 then   regexp_substr(to_char(FEATURE_INFO), 'compression[ -]used:(.*?)(times|TRUE|FALSE)', 1, 1, 'i')
            when CONDITION = 'C002'
                 then   regexp_substr(to_char(FEATURE_INFO), 'encryption used:(.*?)(times|TRUE|FALSE)', 1, 1, 'i')
            when CONDITION = 'C003'
                 then   'AUX_COUNT=' || AUX_COUNT
            when CONDITION = 'C004' and '&&OCS'= 'Y'
                 then   'feature included in Oracle Cloud Services Package'
            else ''
       end as EXTRA_FEATURE_INFO,
       f.CON_ID          ,
       f.CON_NAME        ,
       f.CURRENT_ENTRY   ,
       f.NAME            ,
       f.LAST_SAMPLE_DATE,
       f.DBID            ,
       f.VERSION         ,
       f.DETECTED_USAGES ,
       f.TOTAL_SAMPLES   ,
       f.CURRENTLY_USED  ,
       f.FIRST_USAGE_DATE,
       f.LAST_USAGE_DATE ,
       f.AUX_COUNT       ,
       f.FEATURE_INFO
  from MAP m
  join FUS f on m.FEATURE = f.NAME and regexp_like(f.VERSION, m.MVERSION)
  where nvl(f.TOTAL_SAMPLES, 0) > 0                        -- ignore features that have never been sampled
)
  where nvl(CONDITION, '-') != 'INVALID'                   -- ignore features for which licensing is not required without further conditions
    and not (CONDITION = 'C003' and CON_ID not in (0, 1))  -- multiple PDBs are visible only in CDB$ROOT; PDB level view is not relevant
)
select
    grouping_id(CON_ID) as gid,
    CON_ID   ,
    decode(grouping_id(CON_ID), 1, '--ALL--', max(CON_NAME)) as CON_NAME,
    PRODUCT  ,
    decode(max(USAGE),
          '1.NO_PAST_USAGE'        , 'NO_USAGE'             ,
          '2.NO_CURRENT_USAGE'     , 'NO_USAGE'             ,
          '3.SUPPRESSED_DUE_TO_BUG', 'SUPPRESSED_DUE_TO_BUG',
          '4.PAST_USAGE'           , 'PAST_USAGE'           ,
          '5.PAST_OR_CURRENT_USAGE', 'PAST_OR_CURRENT_USAGE',
          '6.CURRENT_USAGE'        , 'CURRENT_USAGE'        ,
          'UNKNOWN') as USAGE,
    max(LAST_SAMPLE_DATE) as LAST_SAMPLE_DATE,
    min(FIRST_USAGE_DATE) as FIRST_USAGE_DATE,
    max(LAST_USAGE_DATE)  as LAST_USAGE_DATE
  from PFUS
  where USAGE in ('2.NO_CURRENT_USAGE', '4.PAST_USAGE', '5.PAST_OR_CURRENT_USAGE', '6.CURRENT_USAGE')   -- ignore '1.NO_PAST_USAGE', '3.SUPPRESSED_DUE_TO_BUG'
  group by rollup(CON_ID), PRODUCT
  having not (max(CON_ID) in (-1, 0) and grouping_id(CON_ID) = 1)            -- aggregation not needed for non-container databases
order by GID desc, CON_ID, decode(substr(PRODUCT, 1, 1), '.', 2, 1), PRODUCT
;


Prompt <i style="font-size:18px;background-color:POWDERBLUE;">FEATURE USAGE DETAILS</i>

with
MAP as (
-- mapping between features tracked by DBA_FUS and their corresponding database products (options or packs)
select '' PRODUCT, '' feature, '' MVERSION, '' CONDITION from dual union all
SELECT 'Active Data Guard'                                   , 'Active Data Guard - Real-Time Query on Physical Standby' , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Active Data Guard'                                   , 'Global Data Services'                                    , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Active Data Guard or Real Application Clusters'      , 'Application Continuity'                                  , '^1[89]\.|^2[0-9]\.'                           , ' '       from dual union all
SELECT 'Advanced Analytics'                                  , 'Data Mining'                                             , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'ADVANCED Index Compression'                              , '^12\.'                                        , 'BUG'     from dual union all
SELECT 'Advanced Compression'                                , 'Advanced Index Compression'                              , '^12\.'                                        , 'BUG'     from dual union all
SELECT 'Advanced Compression'                                , 'Advanced Index Compression'                              , '^1[89]\.|^2[0-9]\.'                           , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup HIGH Compression'                                 , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup LOW Compression'                                  , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup MEDIUM Compression'                               , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup ZLIB Compression'                                 , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Data Guard'                                              , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'Flashback Data Archive'                                  , '^11\.2\.0\.[1-3]\.'                           , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Flashback Data Archive'                                  , '^(11\.2\.0\.[4-9]\.|1[289]\.|2[0-9]\.)'       , 'INVALID' from dual union all -- licensing required by Optimization for Flashback Data Archive
SELECT 'Advanced Compression'                                , 'HeapCompression'                                         , '^11\.2|^12\.1'                                , 'BUG'     from dual union all
SELECT 'Advanced Compression'                                , 'HeapCompression'                                         , '^12\.[2-9]|^1[89]\.|^2[0-9]\.'                , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Heat Map'                                                , '^12\.1'                                       , 'BUG'     from dual union all
SELECT 'Advanced Compression'                                , 'Heat Map'                                                , '^12\.[2-9]|^1[89]\.|^2[0-9]\.'                , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Hybrid Columnar Compression Row Level Locking'           , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Information Lifecycle Management'                        , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Advanced Network Compression Service'             , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Utility Datapump (Export)'                        , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Utility Datapump (Import)'                        , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'SecureFile Compression (user)'                           , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'SecureFile Deduplication (user)'                         , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'ASO native encryption and checksumming'                  , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'INVALID' from dual union all -- no longer part of Advanced Security
SELECT 'Advanced Security'                                   , 'Backup Encryption'                                       , '^11\.2'                                       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Backup Encryption'                                       , '^1[289]\.|^2[0-9]\.'                          , 'INVALID' from dual union all -- licensing required only by encryption to disk
SELECT 'Advanced Security'                                   , 'Data Redaction'                                          , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Encrypted Tablespaces'                                   , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Oracle Utility Datapump (Export)'                        , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C002'    from dual union all
SELECT 'Advanced Security'                                   , 'Oracle Utility Datapump (Import)'                        , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C002'    from dual union all
SELECT 'Advanced Security'                                   , 'SecureFile Encryption (user)'                            , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Transparent Data Encryption'                             , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Change Management Pack'                              , 'Change Management Pack'                                  , '^11\.2'                                       , ' '       from dual union all
SELECT 'Configuration Management Pack for Oracle Database'   , 'EM Config Management Pack'                               , '^11\.2'                                       , ' '       from dual union all
SELECT 'Data Masking Pack'                                   , 'Data Masking Pack'                                       , '^11\.2'                                       , ' '       from dual union all
SELECT '.Database Gateway'                                   , 'Gateways'                                                , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.Database Gateway'                                   , 'Transparent Gateway'                                     , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Database In-Memory'                                  , 'In-Memory ADO Policies'                                  , '^1[89]\.|^2[0-9]\.'                           , ' '       from dual union all -- part of In-Memory Column Store
SELECT 'Database In-Memory'                                  , 'In-Memory Aggregation'                                   , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Database In-Memory'                                  , 'In-Memory Column Store'                                  , '^12\.1\.0\.2\.'                               , 'BUG'     from dual union all
SELECT 'Database In-Memory'                                  , 'In-Memory Column Store'                                  , '^12\.1\.0\.[3-9]\.|^12\.2|^1[89]\.|^2[0-9]\.' , ' '       from dual union all
SELECT 'Database In-Memory'                                  , 'In-Memory Distribute For Service (User Defined)'         , '^1[89]\.|^2[0-9]\.'                           , ' '       from dual union all -- part of In-Memory Column Store
SELECT 'Database In-Memory'                                  , 'In-Memory Expressions'                                   , '^1[89]\.|^2[0-9]\.'                           , ' '       from dual union all -- part of In-Memory Column Store
SELECT 'Database In-Memory'                                  , 'In-Memory FastStart'                                     , '^1[89]\.|^2[0-9]\.'                           , ' '       from dual union all -- part of In-Memory Column Store
SELECT 'Database In-Memory'                                  , 'In-Memory Join Groups'                                   , '^1[89]\.|^2[0-9]\.'                           , ' '       from dual union all -- part of In-Memory Column Store
SELECT 'Database Vault'                                      , 'Oracle Database Vault'                                   , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Database Vault'                                      , 'Privilege Capture'                                       , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'ADDM'                                                    , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Baseline'                                            , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Baseline Template'                                   , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Report'                                              , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Automatic Workload Repository'                           , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Baseline Adaptive Thresholds'                            , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Baseline Static Computations'                            , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Diagnostic Pack'                                         , '^11\.2'                                       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'EM Performance Page'                                     , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.Exadata'                                            , 'Cloud DB with EHCC'                                      , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT '.Exadata'                                            , 'Exadata'                                                 , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT '.GoldenGate'                                         , 'GoldenGate'                                              , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.HW'                                                 , 'Hybrid Columnar Compression'                             , '^12\.1'                                       , 'BUG'     from dual union all
SELECT '.HW'                                                 , 'Hybrid Columnar Compression'                             , '^12\.[2-9]|^1[89]\.|^2[0-9]\.'                , ' '       from dual union all
SELECT '.HW'                                                 , 'Hybrid Columnar Compression Conventional Load'           , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.HW'                                                 , 'Hybrid Columnar Compression Row Level Locking'           , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.HW'                                                 , 'Sun ZFS with EHCC'                                       , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.HW'                                                 , 'ZFS Storage'                                             , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.HW'                                                 , 'Zone maps'                                               , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Label Security'                                      , 'Label Security'                                          , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Multitenant'                                         , 'Oracle Multitenant'                                      , '^1[289]\.|^2[0-9]\.'                          , 'C003'    from dual union all -- licensing required only when more than one PDB containers are created
SELECT 'Multitenant'                                         , 'Oracle Pluggable Databases'                              , '^1[289]\.|^2[0-9]\.'                          , 'C003'    from dual union all -- licensing required only when more than one PDB containers are created
SELECT 'OLAP'                                                , 'OLAP - Analytic Workspaces'                              , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'OLAP'                                                , 'OLAP - Cubes'                                            , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Partitioning'                                        , 'Partitioning (user)'                                     , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Partitioning'                                        , 'Zone maps'                                               , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.Pillar Storage'                                     , 'Pillar Storage'                                          , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.Pillar Storage'                                     , 'Pillar Storage with EHCC'                                , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT '.Provisioning and Patch Automation Pack'             , 'EM Standalone Provisioning and Patch Automation Pack'    , '^11\.2'                                       , ' '       from dual union all
SELECT 'Provisioning and Patch Automation Pack for Database' , 'EM Database Provisioning and Patch Automation Pack'      , '^11\.2'                                       , ' '       from dual union all
SELECT 'RAC or RAC One Node'                                 , 'Quality of Service Management'                           , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Real Application Clusters'                           , 'Real Application Clusters (RAC)'                         , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Real Application Clusters One Node'                  , 'Real Application Cluster One Node'                       , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Real Application Testing'                            , 'Database Replay: Workload Capture'                       , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C004'    from dual union all
SELECT 'Real Application Testing'                            , 'Database Replay: Workload Replay'                        , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C004'    from dual union all
SELECT 'Real Application Testing'                            , 'SQL Performance Analyzer'                                , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'C004'    from dual union all
SELECT '.Secure Backup'                                      , 'Oracle Secure Backup'                                    , '^1[289]\.|^2[0-9]\.'                          , 'INVALID' from dual union all  -- does not differentiate usage of Oracle Secure Backup Express, which is free
SELECT 'Spatial and Graph'                                   , 'Spatial'                                                 , '^11\.2'                                       , 'INVALID' from dual union all  -- does not differentiate usage of Locator, which is free
SELECT 'Spatial and Graph'                                   , 'Spatial'                                                 , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Automatic Maintenance - SQL Tuning Advisor'              , '^1[289]\.|^2[0-9]\.'                          , 'INVALID' from dual union all  -- system usage in the maintenance window
SELECT 'Tuning Pack'                                         , 'Automatic SQL Tuning Advisor'                            , '^11\.2|^1[289]\.|^2[0-9]\.'                   , 'INVALID' from dual union all  -- system usage in the maintenance window
SELECT 'Tuning Pack'                                         , 'Real-Time SQL Monitoring'                                , '^11\.2'                                       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Real-Time SQL Monitoring'                                , '^1[289]\.|^2[0-9]\.'                          , 'INVALID' from dual union all  -- default
SELECT 'Tuning Pack'                                         , 'SQL Access Advisor'                                      , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Monitoring and Tuning pages'                         , '^1[289]\.|^2[0-9]\.'                          , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Profile'                                             , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Tuning Advisor'                                      , '^11\.2|^1[289]\.|^2[0-9]\.'                   , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Tuning Set (user)'                                   , '^1[289]\.|^2[0-9]\.'                          , 'INVALID' from dual union all -- no longer part of Tuning Pack
SELECT 'Tuning Pack'                                         , 'Tuning Pack'                                             , '^11\.2'                                       , ' '       from dual union all
SELECT '.WebLogic Server Management Pack Enterprise Edition' , 'EM AS Provisioning and Patch Automation Pack'            , '^11\.2'                                       , ' '       from dual union all
select '' PRODUCT, '' FEATURE, '' MVERSION, '' CONDITION from dual
),
FUS as (
-- the current data set to be used: DBA_FEATURE_USAGE_STATISTICS or CDB_FEATURE_USAGE_STATISTICS for Container Databases(CDBs)
select
    &&DCID as CON_ID,
    &&DCNA as CON_NAME,
    -- Detect and mark with Y the current DBA_FUS data set = Most Recent Sample based on LAST_SAMPLE_DATE
      case when DBID || '#' || VERSION || '#' || to_char(LAST_SAMPLE_DATE, 'YYYYMMDDHH24MISS') =
                first_value (DBID    )         over (partition by &&DCID order by LAST_SAMPLE_DATE desc nulls last, DBID desc) || '#' ||
                first_value (VERSION )         over (partition by &&DCID order by LAST_SAMPLE_DATE desc nulls last, DBID desc) || '#' ||
                first_value (to_char(LAST_SAMPLE_DATE, 'YYYYMMDDHH24MISS'))
                                               over (partition by &&DCID order by LAST_SAMPLE_DATE desc nulls last, DBID desc)
           then 'Y'
           else 'N'
    end as CURRENT_ENTRY,
    NAME            ,
    LAST_SAMPLE_DATE,
    DBID            ,
    VERSION         ,
    DETECTED_USAGES ,
    TOTAL_SAMPLES   ,
    CURRENTLY_USED  ,
    FIRST_USAGE_DATE,
    LAST_USAGE_DATE ,
    AUX_COUNT       ,
    FEATURE_INFO
from &&DFUS.FEATURE_USAGE_STATISTICS xy
),
PFUS as (
-- Product-Feature Usage Statitsics = DBA_FUS entries mapped to their corresponding database products
select
    CON_ID,
    CON_NAME,
    PRODUCT,
    NAME as FEATURE_BEING_USED,
    case  when CONDITION = 'BUG'
               --suppressed due to exceptions/defects
               then '3.SUPPRESSED_DUE_TO_BUG'
          when     detected_usages > 0                 -- some usage detection - current or past
               and CURRENTLY_USED = 'TRUE'             -- usage at LAST_SAMPLE_DATE
               and CURRENT_ENTRY  = 'Y'                -- current record set
               and (    trim(CONDITION) is null        -- no extra conditions
                     or CONDITION_MET     = 'TRUE'     -- extra condition is met
                    and CONDITION_COUNTER = 'FALSE' )  -- extra condition is not based on counter
               then '6.CURRENT_USAGE'
          when     detected_usages > 0                 -- some usage detection - current or past
               and CURRENTLY_USED = 'TRUE'             -- usage at LAST_SAMPLE_DATE
               and CURRENT_ENTRY  = 'Y'                -- current record set
               and (    CONDITION_MET     = 'TRUE'     -- extra condition is met
                    and CONDITION_COUNTER = 'TRUE'  )  -- extra condition is     based on counter
               then '5.PAST_OR_CURRENT_USAGE'          -- FEATURE_INFO counters indicate current or past usage
          when     detected_usages > 0                 -- some usage detection - current or past
               and (    trim(CONDITION) is null        -- no extra conditions
                     or CONDITION_MET     = 'TRUE'  )  -- extra condition is met
               then '4.PAST_USAGE'
          when CURRENT_ENTRY = 'Y'
               then '2.NO_CURRENT_USAGE'   -- detectable feature shows no current usage
          else '1.NO_PAST_USAGE'
    end as USAGE,
    LAST_SAMPLE_DATE,
    DBID            ,
    VERSION         ,
    DETECTED_USAGES ,
    TOTAL_SAMPLES   ,
    CURRENTLY_USED  ,
    FIRST_USAGE_DATE,
    LAST_USAGE_DATE,
    EXTRA_FEATURE_INFO
from (
select m.PRODUCT, m.CONDITION, m.MVERSION,
       -- if extra conditions (coded on the MAP.CONDITION column) are required, check if entries satisfy the condition
       case
             when CONDITION = 'C001' and (   regexp_like(to_char(FEATURE_INFO), 'compression[ -]used:[ 0-9]*[1-9][ 0-9]*time', 'i')
                                         and FEATURE_INFO not like '%(BASIC algorithm used: 0 times, LOW algorithm used: 0 times, MEDIUM algorithm used: 0 times, HIGH algorithm used: 0 times)%' -- 12.1 bug - Doc ID 1993134.1
                                          or regexp_like(to_char(FEATURE_INFO), 'compression[ -]used: *TRUE', 'i')                 )
                  then 'TRUE'  -- compression has been used
             when CONDITION = 'C002' and (   regexp_like(to_char(FEATURE_INFO), 'encryption used:[ 0-9]*[1-9][ 0-9]*time', 'i')
                                          or regexp_like(to_char(FEATURE_INFO), 'encryption used: *TRUE', 'i')                  )
                  then 'TRUE'  -- encryption has been used
             when CONDITION = 'C003' and CON_ID=1 and AUX_COUNT > 1
                  then 'TRUE'  -- more than one PDB are created
             when CONDITION = 'C004' and '&&OCS'= 'N'
                  then 'TRUE'  -- not in oracle cloud
             else 'FALSE'
       end as CONDITION_MET,
       -- check if the extra conditions are based on FEATURE_INFO counters. They indicate current or past usage.
       case
             when CONDITION = 'C001' and     regexp_like(to_char(FEATURE_INFO), 'compression[ -]used:[ 0-9]*[1-9][ 0-9]*time', 'i')
                                         and FEATURE_INFO not like '%(BASIC algorithm used: 0 times, LOW algorithm used: 0 times, MEDIUM algorithm used: 0 times, HIGH algorithm used: 0 times)%' -- 12.1 bug - Doc ID 1993134.1
                  then 'TRUE'  -- compression counter > 0
             when CONDITION = 'C002' and     regexp_like(to_char(FEATURE_INFO), 'encryption used:[ 0-9]*[1-9][ 0-9]*time', 'i')
                  then 'TRUE'  -- encryption counter > 0
             else 'FALSE'
       end as CONDITION_COUNTER,
       case when CONDITION = 'C001'
                 then   regexp_substr(to_char(FEATURE_INFO), 'compression[ -]used:(.*?)(times|TRUE|FALSE)', 1, 1, 'i')
            when CONDITION = 'C002'
                 then   regexp_substr(to_char(FEATURE_INFO), 'encryption used:(.*?)(times|TRUE|FALSE)', 1, 1, 'i')
            when CONDITION = 'C003'
                 then   'AUX_COUNT=' || AUX_COUNT
            when CONDITION = 'C004' and '&&OCS'= 'Y'
                 then   'feature included in Oracle Cloud Services Package'
            else ''
       end as EXTRA_FEATURE_INFO,
       f.CON_ID          ,
       f.CON_NAME        ,
       f.CURRENT_ENTRY   ,
       f.NAME            ,
       f.LAST_SAMPLE_DATE,
       f.DBID            ,
       f.VERSION         ,
       f.DETECTED_USAGES ,
       f.TOTAL_SAMPLES   ,
       f.CURRENTLY_USED  ,
       f.FIRST_USAGE_DATE,
       f.LAST_USAGE_DATE ,
       f.AUX_COUNT       ,
       f.FEATURE_INFO
  from MAP m
  join FUS f on m.FEATURE = f.NAME and regexp_like(f.VERSION, m.MVERSION)
  where nvl(f.TOTAL_SAMPLES, 0) > 0                        -- ignore features that have never been sampled
)
  where nvl(CONDITION, '-') != 'INVALID'                   -- ignore features for which licensing is not required without further conditions
    and not (CONDITION = 'C003' and CON_ID not in (0, 1))  -- multiple PDBs are visible only in CDB$ROOT; PDB level view is not relevant
)
select
    CON_ID            ,
    CON_NAME          ,
    PRODUCT           ,
    FEATURE_BEING_USED,
    decode(USAGE,
          '1.NO_PAST_USAGE'        , 'NO_PAST_USAGE'        ,
          '2.NO_CURRENT_USAGE'     , 'NO_CURRENT_USAGE'     ,
          '3.SUPPRESSED_DUE_TO_BUG', 'SUPPRESSED_DUE_TO_BUG',
          '4.PAST_USAGE'           , 'PAST_USAGE'           ,
          '5.PAST_OR_CURRENT_USAGE', 'PAST_OR_CURRENT_USAGE',
          '6.CURRENT_USAGE'        , 'CURRENT_USAGE'        ,
          'UNKNOWN') as USAGE,
    LAST_SAMPLE_DATE  ,
    DBID              ,
    VERSION           ,
    DETECTED_USAGES   ,
    TOTAL_SAMPLES     ,
    CURRENTLY_USED    ,
    FIRST_USAGE_DATE  ,
    LAST_USAGE_DATE   ,
    EXTRA_FEATURE_INFO
  from PFUS
  where USAGE in ('2.NO_CURRENT_USAGE', '3.SUPPRESSED_DUE_TO_BUG', '4.PAST_USAGE', '5.PAST_OR_CURRENT_USAGE', '6.CURRENT_USAGE')  -- ignore '1.NO_PAST_USAGE'
order by CON_ID, decode(substr(PRODUCT, 1, 1), '.', 2, 1), PRODUCT, FEATURE_BEING_USED, LAST_SAMPLE_DATE desc, PFUS.USAGE
;



Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 3a. Top peak time interval info based on DB Time</i>
select * from (
SELECT INSTANCE_NUMBER,BEGIN_SNAP_ID,end_snap_id,SNAP_BEGIN_TIME,SNAP_END_TIME,sum(DB_TIME) "DB_TIME in Min" FROM
(
SELECT
A.INSTANCE_NUMBER INSTANCE_NUMBER,
LAG(A.SNAP_ID) OVER (ORDER BY A.SNAP_ID) BEGIN_SNAP_ID,
A.SNAP_ID END_SNAP_ID,
TO_CHAR(B.BEGIN_INTERVAL_TIME,'DD-MON-YY HH24:MI') SNAP_BEGIN_TIME,
TO_CHAR(B.END_INTERVAL_TIME ,'DD-MON-YY HH24:MI') SNAP_END_TIME,
ROUND((A.VALUE-LAG(A.VALUE) OVER (ORDER BY A.SNAP_ID ))/1000000/60,2) DB_TIME
FROM
   DBA_HIST_SYS_TIME_MODEL A,
   DBA_HIST_SNAPSHOT       B
WHERE
A.SNAP_ID = B.SNAP_ID AND
A.INSTANCE_NUMBER = B.INSTANCE_NUMBER AND
A.STAT_NAME = 'DB time' AND
B.BEGIN_INTERVAL_TIME > sysdate-30
)
group by INSTANCE_NUMBER,BEGIN_SNAP_ID,end_snap_id,SNAP_BEGIN_TIME,SNAP_END_TIME ORDER BY 6 DESC)
WHERE "DB_TIME in Min" > 0
and rownum=1;


Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 3b. Top peak time interval info based on CPU Time</i>
select * from (
SELECT INSTANCE_NUMBER,BEGIN_SNAP_ID,end_snap_id,SNAP_BEGIN_TIME,SNAP_END_TIME,sum(CPU_TIME) "CPU_TIME in Min" FROM
(
SELECT
A.INSTANCE_NUMBER INSTANCE_NUMBER,
LAG(A.SNAP_ID) OVER (ORDER BY A.SNAP_ID) BEGIN_SNAP_ID,
A.SNAP_ID END_SNAP_ID,
TO_CHAR(B.BEGIN_INTERVAL_TIME,'DD-MON-YY HH24:MI') SNAP_BEGIN_TIME,
TO_CHAR(B.END_INTERVAL_TIME ,'DD-MON-YY HH24:MI') SNAP_END_TIME,
ROUND((A.VALUE-LAG(A.VALUE) OVER (ORDER BY A.SNAP_ID ))/1000000/60,2) CPU_TIME
FROM
   DBA_HIST_SYS_TIME_MODEL A,
   DBA_HIST_SNAPSHOT       B
WHERE
A.SNAP_ID = B.SNAP_ID AND
A.INSTANCE_NUMBER = B.INSTANCE_NUMBER AND
A.STAT_NAME = 'DB CPU' AND
B.BEGIN_INTERVAL_TIME > sysdate-30
)
group by INSTANCE_NUMBER,BEGIN_SNAP_ID,end_snap_id,SNAP_BEGIN_TIME,SNAP_END_TIME ORDER BY 6 DESC)
WHERE "CPU_TIME in Min" > 0
and rownum=1;


Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 4a. Average DB Time (in sec per min)</i>

select round(avg_db_time/(
select extract( day from snap_interval) *24*60+
       extract( hour from snap_interval) *60+
       extract( minute from snap_interval ) Snap_Interval
       from dba_hist_wr_control where dbid=(select dbid from v$database)),2) "AVG_DB_TIME in sec per min" from
(
select round(avg(db_time),2) avg_db_time from
(
SELECT
ROUND((A.VALUE-LAG(A.VALUE) OVER (ORDER BY A.SNAP_ID ))/1000000,2) DB_TIME
FROM
   DBA_HIST_SYS_TIME_MODEL A,
   DBA_HIST_SNAPSHOT       B
WHERE
A.SNAP_ID = B.SNAP_ID AND
A.INSTANCE_NUMBER = B.INSTANCE_NUMBER AND
A.STAT_NAME = 'DB time' AND
A.dbid=b.dbid AND
A.dbid=(select dbid from v$database) AND
B.dbid=(select dbid from v$database) AND
B.BEGIN_INTERVAL_TIME > sysdate-30)
);

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 4b. Average CPU Time (in sec per min)</i>
select round(avg_db_cpu/(
select extract( day from snap_interval) *24*60+
       extract( hour from snap_interval) *60+
       extract( minute from snap_interval ) Snap_Interval
       from dba_hist_wr_control where dbid=(select dbid from v$database)),2) "AVG_DB_CPU in sec per min" from
(
select round(avg(db_cpu),2) avg_db_cpu from
(
SELECT
ROUND((A.VALUE-LAG(A.VALUE) OVER (ORDER BY A.SNAP_ID ))/1000000,2) DB_CPU
FROM
   DBA_HIST_SYS_TIME_MODEL A,
   DBA_HIST_SNAPSHOT       B
WHERE
A.SNAP_ID = B.SNAP_ID AND
A.INSTANCE_NUMBER = B.INSTANCE_NUMBER AND
A.STAT_NAME = 'DB CPU' AND
A.dbid=b.dbid AND
A.dbid=(select dbid from v$database) AND
B.dbid=(select dbid from v$database) AND
B.BEGIN_INTERVAL_TIME > sysdate-30)
);

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 5. Check For DDL Logging</i>
select distinct NAME as PARAMETER, VALUE from GV$PARAMETER where lower(NAME) in ('enable_ddl_logging') order by 1;

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 6a. Deprecated Parameters in 19c</i>
select inst_id,name,value from gv$parameter where upper(name) in ('SEC_CASE_SENSITIVE_LOGON','CLUSTER_DATABASE_INSTANCES','SERVICE_NAMES','EXAFUSION_ENABLED','O7_DICTIONARY_ACCESSIBILITY','STANDBY_ARCHIVE_DEST','UTL_FILE_DIR');

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 6b. MAX_CONNECTIONS - the Deprecated Parameter of LOG_ARCHIVE_DEST_n in 19c</i>
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">In case of no output then MAX_CONNECTIONS is not being used in LOG_ARCHIVE_DEST_n</i>
select inst_id,name,value from gv$parameter where upper(name) like '%LOG_ARCHIVE_DEST%' and upper(name) not like 'LOG_ARCHIVE_DEST_STATE_%' and lower(value) like '%max_connections%';
prompt
Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 7 Usage of Spatial</i>
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">If Count is 0 then Spatial is not in use</i>
col owner format a12
col table_name format a35
col column_name format a25
select count(*) from dba_tab_columns where data_type = 'SDO_GEOMETRY' and owner != 'MDSYS';
select owner, table_name, column_name
from dba_tab_columns
where data_type = 'SDO_GEOMETRY'
and owner != 'MDSYS';
prompt
Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 8. Top 5 Average Wait Event based on Wait time</i>
set head on
select * from
(select
     event "Event Name",
     waits "Waits",
     round(time,2) "Wait Time (s)",
     round(time*1000/waits,2) "Avg Wait (ms)",
     waitclass "Wait Class"
from
    (select e.event_name event
          , sum( e.total_waits - nvl(b.total_waits,0))  waits
          , sum( (e.time_waited_micro - nvl(b.time_waited_micro,0))/1000000)  time
          , e.wait_class waitclass
     from
        dba_hist_system_event b ,
        dba_hist_system_event e, (select dbid,max(snap_id) max_snap_id from dba_hist_snapshot group by dbid) m, (select dbid,min(snap_id) min_snap_id from dba_hist_snapshot group by dbid) n, (select  dbid from v$database) d
     where
                      b.snap_id             = n.min_snap_id
                  and e.snap_id             = m.max_snap_id
                  and b.event_id            = e.event_id
                  and b.dbid                = e.dbid
                  and e.dbid=d.dbid
                  and e.total_waits         > nvl(b.total_waits,0)
                  and e.wait_class          <> 'Idle'
                  and b.instance_number = e.instance_number
                  and m.dbid=d.dbid
                  and n.dbid=d.dbid
                   group by e.event_name, e.wait_class)
order by time desc, waits desc)
where rownum<6;

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 9. Top 5 Peak Time Wait Event</i>

select * from
(select
     event "Event Name",
     waits "Waits",
     round(time,2) "Wait Time (s)",
     round(time*1000/waits,2) "Avg Wait (ms)",
     waitclass "Wait Class"
from
    (select e.event_name event
          , sum( e.total_waits - nvl(b.total_waits,0))  waits
          , sum( (e.time_waited_micro - nvl(b.time_waited_micro,0))/1000000)  time
          , e.wait_class waitclass
     from
        dba_hist_system_event b ,
        dba_hist_system_event e,
                (select * from (
SELECT dbid,INSTANCE_NUMBER,BEGIN_SNAP_ID,end_snap_id,sum(DB_TIME) db_time FROM
(
SELECT
A.dbid,A.INSTANCE_NUMBER INSTANCE_NUMBER,
LAG(A.SNAP_ID) OVER (ORDER BY A.SNAP_ID) BEGIN_SNAP_ID,
A.SNAP_ID END_SNAP_ID,
TO_CHAR(B.BEGIN_INTERVAL_TIME,'DD-MON-YY HH24:MI') SNAP_BEGIN_TIME,
TO_CHAR(B.END_INTERVAL_TIME ,'DD-MON-YY HH24:MI') SNAP_END_TIME,
ROUND((A.VALUE-LAG(A.VALUE) OVER (ORDER BY A.SNAP_ID ))/1000000/60,2) DB_TIME
FROM
   DBA_HIST_SYS_TIME_MODEL A,
   DBA_HIST_SNAPSHOT       B
WHERE
A.SNAP_ID = B.SNAP_ID AND
A.INSTANCE_NUMBER = B.INSTANCE_NUMBER AND
A.STAT_NAME = 'DB time' AND
B.BEGIN_INTERVAL_TIME > sysdate-30
)
group by dbid,INSTANCE_NUMBER,BEGIN_SNAP_ID,end_snap_id ORDER BY 5 DESC)
WHERE DB_TIME > 0
and rownum=1) s,
                (select  dbid from v$database) d
     where
                      b.snap_id          = s.BEGIN_SNAP_ID
                  and e.snap_id             = s.end_snap_id
                  and b.event_id         = e.event_id
                  and b.dbid         = e.dbid
                  and e.dbid=d.dbid
                  and e.total_waits         > nvl(b.total_waits,0)
                  and e.wait_class          <> 'Idle'
                  and b.instance_number = s.instance_number
                  and s.dbid=d.dbid
                  group by e.event_name, e.wait_class)
order by time desc, waits desc)
where rownum<6;


Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 10. Top 60 SQL based on execution time and elapsed time</i>
set head on

select selsql.dbid,selsql.instance_number, selsql.EXECUTIONS_TOTAL, selsql.ELAPSED_SECONDS, substr(b.sql_text,1,500) "SQL", selsql.module, selsql.sql_id, selsql.parsing_schema_name  from
(select a.dbid,a.instance_number, a.sql_id, a.module,a.parsing_schema_name, max(EXECUTIONS_TOTAL)  EXECUTIONS_TOTAL, max(ELAPSED_TIME_TOTAL)/1000000 ELAPSED_SECONDS
from dba_hist_sqlstat a, (select exec_sql.sql_id, exec_sql.start_snap, exec_sql.end_snap from(
select hist.sql_id,min(hist.snap_id) start_snap,max(hist.snap_id) end_snap,max(hist.EXECUTIONS_total)
from dba_hist_sqlstat hist, v$database d
where hist.PARSING_SCHEMA_NAME not in (select schema from dba_registry) and hist.PARSING_SCHEMA_NAME not in('DBSNMP','ORACLE_OCM') and hist.dbid= d.dbid
group by hist.sql_id
order by 4 desc) exec_sql
where rownum<31
union
select elaps_sql.sql_id, elaps_sql.start_snap, elaps_sql.end_snap from(
select hist.sql_id,min(hist.snap_id) start_snap,max(hist.snap_id) end_snap,max(hist.ELAPSED_TIME_TOTAL)
from dba_hist_sqlstat hist, v$database d
where hist.PARSING_SCHEMA_NAME not in (select schema from dba_registry) and hist.PARSING_SCHEMA_NAME not in('DBSNMP','ORACLE_OCM') and hist.dbid= d.dbid
group by hist.sql_id
order by 4 desc) elaps_sql
where rownum<31) b
where a.sql_id=b.sql_id
and PARSING_SCHEMA_NAME not in (select schema from dba_registry) and PARSING_SCHEMA_NAME not in('DBSNMP','ORACLE_OCM')
group by a.dbid,a.instance_number, a.sql_id, a.module,a.parsing_schema_name) selsql, dba_hist_sqltext b, v$database c
where selsql.sql_id=b.sql_id
and selsql.dbid=c.dbid
and b.dbid=c.dbid;


Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 11. Time Zone</i>
set head on
SELECT PROPERTY_NAME, SUBSTR(PROPERTY_VALUE, 1, 30) VALUE
FROM DATABASE_PROPERTIES
WHERE PROPERTY_NAME LIKE 'DST_%'
ORDER BY PROPERTY_NAME;

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 12. User Details</i>
set head on

SELECT USERNAME,ACCOUNT_STATUS,AUTHENTICATION_TYPE,PASSWORD_VERSIONS FROM DBA_USERS;

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 13. Transparent Encryption Oracle Wallets</i>
SELECT * FROM GV$ENCRYPTION_WALLET;

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 14. Dependencies on Network Utility Packages</i>
set head on
SELECT * FROM DBA_DEPENDENCIES WHERE REFERENCED_NAME IN ('UTL_TCP','UTL_SMTP','UTL_MAIL','UTL_HTTP','UTL_INADDR','DBMS_LDAP') AND OWNER NOT IN ('SYS','PUBLIC','ORDPLUGINS');

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 15. Check the state of dictionary stats</i>
select to_char(max(END_TIME),'DD-MON-YYYY HH24:MI:SS') LATEST, OPERATION from DBA_OPTSTAT_OPERATIONS  group by operation;

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 16. Recycle Bin Status</i>
set head on
sho parameter recyclebin;
select count(*) as "Count In dba_recyclebin" from dba_recyclebin;


Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 17a. DBA Registry status</i>
set head on
set lines 300
col comp_name for a70
set pagesize 500
select comp_id,substr(comp_name,1,40) comp_name, status, substr(version,1,10) version from dba_registry order by comp_name;

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 17b. DBA Registry status in case of CDB env</i>
set line 200
set pages 1000
col COMP_ID format a8
col COMP_NAME format a34
col SCHEMA format a12
col STATUS format a10
col CON_ID format 99

select CON_ID, COMP_ID, comp_name, schema, status, version from CDB_REGISTRY order by 1,2;

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 17c. Component Details</i>
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">JAVAM</i>
Prompt <i style="font-size:16px;background-color:PEACHPUFF;">Schemas using Java Component</i>
select owner, status, count(*) from dba_objects  where object_type like '%JAVA%' group by owner, status;
select name, version,DETECTED_USAGES,TOTAL_SAMPLES,CURRENTLY_USED,LAST_USAGE_DATE,FEATURE_INFO,DESCRIPTION from dba_feature_usage_statistics where version = (select version from V$INSTANCE) and lower(name) like '%java%';

Prompt <i style="font-size:18px;background-color:POWDERBLUE;">Usage of CONTEXT</i>
select name, version,DETECTED_USAGES,TOTAL_SAMPLES,CURRENTLY_USED,LAST_USAGE_DATE,FEATURE_INFO,DESCRIPTION from dba_feature_usage_statistics where version = (select version from V$INSTANCE) and lower(name) like '%text%';
Prompt <i style="font-size:16px;background-color:PEACHPUFF;">If Oracle Text is in use then there will be entries other than just 1 owned by CTXSYS</i>
SELECT idx_owner, count(*) FROM ctxsys.ctx_indexes GROUP BY idx_owner;

Prompt <i style="font-size:18px;background-color:POWDERBLUE;">Usage of OWM</i>
Prompt <i style="font-size:16px;background-color:PEACHPUFF;">If there are no versioned tables, or the count in dba_wm_versioned_tables is 0, then OWM is not in use.</i>
select * from dba_wm_versioned_tables;
select count(*)  from dba_wm_versioned_tables;
Prompt <i style="font-size:16px;background-color:PEACHPUFF;">Output from dba_workspaces and ALL_VERSION_HVIEW</i>
select workspace, parent_workspace, owner, freeze_status, resolve_status from dba_workspaces;
select version, parent_version, workspace from ALL_VERSION_HVIEW;

Prompt <i style="font-size:18px;background-color:POWDERBLUE;">Oracle Multimedia</i>
Prompt <i style="font-size:16px;background-color:PEACHPUFF;">Check if Oracle Multimedia is in use</i>
Prompt <i style="font-size:16px;background-color:PEACHPUFF;">The script imremchk.sql is used to check the presence of Oracle Multimedia. The script is non-invasive</i>
Prompt <i style="font-size:16px;background-color:PEACHPUFF;">It displays a message indicating whether or not Oracle Multimedia is being used</i>
Prompt <i style="font-size:16px;background-color:PEACHPUFF;">It creates and drops the package body used for the detecting the usage of Oracle Multimedia</i>
set serveroutput on
@?/ord/im/admin/imremchk.sql
set serveroutput off
set feed off
Prompt <i style="font-size:16px;background-color:PEACHPUFF;">To determine if Oracle Multimedia objects types are used in any tables</i>
set head on
select count(u.table_name) from
    sys.dba_tab_columns u
    where u.table_name not in (select object_name from sys.dba_recyclebin)
       and u.data_type IN
            ('ORDIMAGE','ORDIMAGESIGNATURE','ORDAUDIO','ORDVIDEO',
             'ORDDOC','ORDSOURCE','ORDDICOM','ORDDATASOURCE',
             'SI_STILLIMAGE','SI_COLOR','SI_AVERAGECOLOR',
             'SI_POSITIONALCOLOR','SI_TEXTURE','SI_COLORHISTOGRAM',
             'SI_FEATURELIST')
         and (u.data_type_owner IN ('ORDSYS', 'PUBLIC'))
         and (u.owner <> 'PM');


Prompt <i style="font-size:18px;background-color:POWDERBLUE;">OLAP</i>
Prompt <i style="font-size:16px;background-color:PEACHPUFF;">Check if OLAP is in use</i>
col owner format a10
col aw_name format a20
select owner, aw_name from dba_aws;
select aw_name, aw_number from all_aws;
Prompt <i style="font-size:16px;background-color:PEACHPUFF;">AWREPORT,AWCREATE10G,AWXML,AWCREATE,AWMD,EXPRESS are the AWs that come with the OLAP option</i>
Prompt <i style="font-size:16px;background-color:PEACHPUFF;">User-defined AWs are owned by the user that created the AW (other than SYS)</i>
prompt
Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 18a. Invalid Objects</i>
set head on

SELECT COUNT ( * ) INVALID_OBJECTS FROM DBA_OBJECTS WHERE STATUS = 'INVALID';
SELECT COUNT ( * ) INVALID_OBJECTS,owner FROM DBA_OBJECTS WHERE STATUS = 'INVALID' group by owner;

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 18b. Invalid Sys Objects</i>
set head on
SELECT COUNT ( * ) INVALID_SYS_SYSTEM_OBJECTS FROM DBA_OBJECTS WHERE OWNER IN ('SYS','SYSTEM') AND STATUS = 'INVALID';
select OWNER,OBJECT_NAME,OBJECT_TYPE,CREATED,LAST_DDL_TIME from dba_objects where status!='VALID' and owner in ('SYS','SYSTEM');

COL C1 HEADING 'OWNER' FORMAT A15
COL C2 HEADING 'NAME' FORMAT A40
COL C3 HEADING 'TYPE' FORMAT A10
COL C4 HEADING 'STATUS' FORMAT A15
Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 18c. Invalid Objects details</i>
set pages 11000
SELECT
   OWNER       C1,
   OBJECT_TYPE C3,
   OBJECT_NAME C2,
   STATUS C4
FROM
   DBA_OBJECTS
WHERE
   STATUS != 'VALID'
ORDER BY
   OWNER,
   OBJECT_TYPE;

prompt
Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 19. Duplicate Objects</i>
set head on

COLUMN OBJECT_NAME FORMAT A30
SELECT owner, OBJECT_NAME, OBJECT_TYPE
FROM DBA_OBJECTS
WHERE OBJECT_NAME||OBJECT_TYPE IN
   (SELECT OBJECT_NAME||OBJECT_TYPE
    FROM DBA_OBJECTS
    WHERE OWNER = 'SYS')
AND OWNER = 'SYSTEM';

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 20. Materialized View</i>
set head on
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">Check if materialized view refresh is in process. Needs to be checked prior upgrade</i>
SELECT count(*) FROM sys.obj$ o, sys.user$ u, sys.sum$ s WHERE o.type# = 42 AND bitand(s.mflags, 8) =8;
SELECT u.name owner, o.name mview_name
FROM sys.obj$ o, sys.user$ u, sys.sum$
s WHERE o.type# = 42 AND o.owner# = u.user# and s.obj# = o.obj# and
bitand(s.mflags, 8) = 8;
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">Querying DBA_MVIEWS to get the list of MV's which are in an invalid or unusable state</i>
select owner, mview_name,staleness,compile_state,LAST_REFRESH_DATE from dba_mviews where staleness not in ('FRESH', 'STALE', 'UNKNOWN') or compile_state not in ('VALID');
select count(*) from dba_mviews where staleness not in ('FRESH', 'STALE', 'UNKNOWN') or compile_state not in ('VALID');

prompt

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 21. Hidden Parameter</i>
set head on
SELECT name, value from SYS.GV$PARAMETER WHERE name LIKE '\_%' ESCAPE '\' order by name;
prompt
Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 22. SYSAUX Occupancy</i>
set head on
 select OCCUPANT_NAME,OCCUPANT_DESC,SCHEMA_NAME,SPACE_USAGE_KBYTES/1024 as "SPACE_USAGE_MB" from V$SYSAUX_OCCUPANTS order by  4;


Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 24. Synopsis</i>
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">Count from SYS.WRI$_OPTSTAT_SYNOPSIS$</i>
select count(1) from SYS.WRI$_OPTSTAT_SYNOPSIS$;
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">Count from SYS.WRI$_OPTSTAT_SYNOPSIS_HEAD$</i>
select count(1) from SYS.WRI$_OPTSTAT_SYNOPSIS_HEAD$;

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 25. Check the presence of PRODUCT_USER_PROFILE </i>
select owner,object_name,object_type from dba_objects where object_name in ('SQLPLUS_PRODUCT_PROFILE','PRODUCT_USER_PROFILE');
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">Count from PRODUCT_USER_PROFILE</i>
select * from PRODUCT_USER_PROFILE;
select count(*) from PRODUCT_USER_PROFILE;


Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 26. Check the presence of symbolic links in UTL_FILE_DIR</i>
select * from dba_directories order by 1;


Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 27. Tablespace Utilization</i>
SELECT /*+ first_rows */ d.tablespace_name "TS NAME", NVL(a.bytes / 1024 / 1024, 0) "size MB", NVL(a.bytes - NVL(f.bytes, 0), 0)/1024/1024 "Used MB", NVL((a.bytes - NVL(f.bytes, 0)) / a.bytes * 100, 0) "Used %",
a.autoextensible "Autoextend", NVL(f.bytes, 0) / 1024 / 1024 "Free MB", d.status "STAT", a.count "# of datafiles", d.contents "TS type", d.extent_management "EXT MGMT", d.segment_space_management "Seg Space MGMT" FROM sys.dba_tablespaces d, (select tablespace_name,
sum(bytes) bytes, count(file_id) count, decode(sum(decode(autoextensible, 'NO', 0, 1)), 0, 'NO', 'YES') autoextensible from dba_data_files group by tablespace_name) a,
(select tablespace_name, sum(bytes) bytes from dba_free_space group by tablespace_name) f WHERE d.tablespace_name = a.tablespace_name(+) AND d.tablespace_name = f.tablespace_name(+)
AND NOT d.contents = 'UNDO' AND NOT (d.extent_management = 'LOCAL' AND d.contents = 'TEMPORARY') AND d.tablespace_name like '%%' UNION ALL SELECT d.tablespace_name, NVL(a.bytes / 1024 / 1024, 0),
NVL(t.bytes, 0)/1024/1024, NVL(t.bytes / a.bytes * 100, 0), a.autoext, (NVL(a.bytes ,0)/1024/1024 - NVL(t.bytes, 0)/1024/1024), d.status, a.count, d.contents, d.extent_management,
d.segment_space_management FROM sys.dba_tablespaces d, (select tablespace_name, sum(bytes) bytes, count(file_id) count, decode(sum(decode(autoextensible, 'NO', 0, 1)), 0, 'NO', 'YES') autoext
from dba_temp_files group by tablespace_name) a, (select ss.tablespace_name , sum((ss.used_blocks*ts.blocksize)) bytes from gv$sort_segment ss, sys.ts$ ts where ss.tablespace_name = ts.name
group by ss.tablespace_name) t WHERE d.tablespace_name = a.tablespace_name(+) AND d.tablespace_name = t.tablespace_name(+) AND d.extent_management = 'LOCAL' AND d.contents = 'TEMPORARY'
and d.tablespace_name like '%%' UNION ALL SELECT d.tablespace_name, NVL(a.bytes / 1024 / 1024, 0), NVL(u.bytes, 0) / 1024 / 1024, NVL(u.bytes / a.bytes * 100, 0), a.autoext, NVL(a.bytes - NVL(u.bytes, 0), 0)/1024/1024,
d.status, a.count, d.contents, d.extent_management, d.segment_space_management FROM sys.dba_tablespaces d, (SELECT tablespace_name, SUM(bytes) bytes, COUNT(file_id) count, decode(sum(decode(autoextensible, 'NO', 0, 1)),
0, 'NO', 'YES') autoext FROM dba_data_files GROUP BY tablespace_name) a, (SELECT tablespace_name, SUM(bytes) bytes FROM (SELECT tablespace_name,sum (bytes) bytes,status from dba_undo_extents WHERE status ='ACTIVE'
group by tablespace_name,status UNION ALL SELECT tablespace_name,sum(bytes) bytes,status from dba_undo_extents WHERE status ='UNEXPIRED' group by tablespace_name,status ) group by tablespace_name ) u
WHERE d.tablespace_name = a.tablespace_name(+) AND d.tablespace_name = u.tablespace_name(+) AND d.contents = 'UNDO' AND d.tablespace_name LIKE '%%' ORDER BY 1;

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 28. Count in Audit Tables</i>
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">Standard Auditing Under sys.aud$</i>
SELECT count(*) FROM sys.aud$;
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">Standard Auditing,when Oracle Label Security (OLS)/Database Vault (DV) is installed Under system.aud$</i>
SELECT count(*) FROM system.aud$;
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">Fine Grained Auditing from sys.fga_log$ </i>
SELECT count(*) FROM sys.fga_log$;
Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 29. Resource_limit parameter</i>
Prompt <i style="font-size:18px;background-color:POWDERBLUE;">If the value of ISDEFALUT is false then this implies that parameter is explicitly set in SPFILE</i>
select name,VALUE,ISDEFAULT,ISSYS_MODIFIABLE from v$parameter where lower(name)='resource_limit';

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 30. Index Information</i>
select owner,table_name,count(*) from dba_indexes where owner not in ('OJVMSYS','SCOTT','APEX_040200','AUDSYS','DVSYS','APEX_030200','PERFSTAT','APPQOSSYS','DMSYS','O2O_USR','APEX_PUBLIC_USER','DIP','FLOWS_30000','FLOWS_FILES','MDDATA','ORACLE_OCM','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR','XS$NULL','ANONYMOUS','CTXSYS','DBSNMP','EXFSYS','LBACSYS','MDSYS','MGMT_VIEW','OLAPSYS','OWBSYS','ORDPLUGINS','ORDSYS','OUTLN','SI_INFORMTN_SCHEMA','SYS','SYSMAN','SYSTEM','TSMSYS','WK_TEST','WKSYS','WKPROXY','WMSYS','XDB','OGG_USR','SQLTXPLAIN','ORDDATA','O2O','ACS_MIG') having count(*)>5 group  by owner,table_name order by 3 desc;

Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 31. Hints Used Within the Database</i>
select parsing_schema_name,count(distinct sql_id) from v$sql  where sql_text like '%/*+%' and parsing_schema_name not in ('OJVMSYS','SCOTT','APEX_040200','AUDSYS','DVSYS','APEX_030200','PERFSTAT','APPQOSSYS','DMSYS','O2O_USR','APEX_PUBLIC_USER','DIP','FLOWS_30000','FLOWS_FILES','MDDATA','ORACLE_OCM','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR','XS$NULL','ANONYMOUS','CTXSYS','DBSNMP','EXFSYS','LBACSYS','MDSYS','MGMT_VIEW','OLAPSYS','OWBSYS','ORDPLUGINS','ORDSYS','OUTLN','SI_INFORMTN_SCHEMA','SYS','SYSMAN','SYSTEM','TSMSYS','WK_TEST','WKSYS','WKPROXY','WMSYS','XDB','OGG_USR','SQLTXPLAIN','ORDDATA','O2O','ACS_MIG') group by parsing_schema_name order by 2 desc;


Prompt <i style="font-size:20px;background-color:LIGHTSALMON;">Section 32. Patch Information</i>
col action form a20 wrap
col namespace form a15 wrap
col version form a26 wrap
col comments form a58 wrap
select to_char(action_time, 'YYYY-MM-DD HH24:MI:SS') "Date",action,namespace,version,comments from dba_registry_history order by 1;



select sysdate as "Script End Time" from dual;
prompt <p style="text-align: center;font-size:25px;background-color:SANDYBROWN;">*******************End of Script*******************</p>

spool off
set markup html off
exit;


