set timing on
set trimspool on
spool &1/purge_dba_recyclebin_&2
SELECT name from v$database ;

PROMPT##################################################
PROMPT Recyclebin count prior purge
PROMPT##################################################
select count(1) from dba_recyclebin;

purge dba_recyclebin;

PROMPT##################################################
PROMPT Recyclebin count after purge
PROMPT##################################################

select count(1) from dba_recyclebin;

spool off;
