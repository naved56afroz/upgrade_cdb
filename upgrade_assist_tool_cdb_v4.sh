#!/bin/bash
#set -x
##############################################################################################################################################
#  Description : Scripts to troubleshoot performance of the database.
#
#  SCRIPT NAME : upgrade_tool_v4.sh
#  Version : 3.0
#  Scripted By : Naved Afroz  email : naved.afroz@oracle.com
#  Phase : Beta Version
#  Other files used in the script :
#
#  flags used : Explicit_Call
#
#
#
#  USAGE : sh upgrade_tool_v4.sh CDB_NAME PDB_NAME
#  Date  : 17/09/2021
#
#  features  :
#                       v1.1 : Remote Clone Precheck
#                       v1.2 : Inplace Precheck
#                       v1.3 : Email notification  and additional parameters collect
#                       v1.4 : preupgrade.jar and minor query addition 
#                       v1.5 :
#                       v1.6 :
#                       v1.7 :
#                       v1.8 :
#                       v1.9 :
#                       v1.10 :
#                       v1.11 :
#                       v1.12 :
#                       v1.12 :
#                       v1.13 :
#
############################################################################################################################################

send_mail ()
{
cd $LOG_DIR/$dt
sub1=$(echo " ""$cdb_name"" impact_analysis Log ($pdb_name) | ")
sub2=$(echo "$varhost" " | ")
sub=$(echo "$sub1" "$sub2" "$dt")
MAIL_RECIPIENTS=naved.afroz@aig.com
CC_List=naved.afroz@aig.com
mailx -s "$sub" -a ACS_UPGRADE_IMPACT_ANALYSIS*.html $MAIL_RECIPIENTS -c $CC_List < $1
}

set_env ()
{
# Local .env
cd /home/oracle
if [ -f $cdb_name.env ]; then
    # Load Environment Variables
    . ./$cdb_name.env
    echo $ORACLE_SID
else
    echo "No $cdb_name.env file found" 1>&2
    return 1
fi
}

pdb_count ()
{
pdb_list=`sqlplus -S "/ as sysdba" <<EOF
SET FEEDBACK OFF
SET VERIFY OFF HEAD OFF PAGES 0
@$SCRIPTS_DIR/$1
EXIT;
EOF`
count=`echo $pdb_list | sed 's/ *$//g'`
}

logfile_check ()
{
#Logfile used by preheck
logname=$LOG_DIR/$dt/prechecks_$1.log

if [ -f "$logname" ]
          then
            mv "$logname" "$LOG_DIR"/"$dt"/prechecks"${1}"_"${ts}".log
fi
}


sql_execution_cdb ()
{
sqlplus -S "/ as sysdba" <<EOF
set timing on
set trimspool on
spool $LOG_DIR/$dt/$cdb_name.txt
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt                    $cdb_name
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt ###########################################################
prompt Take backup of prameter file - Backup source CDB spfile
prompt ###########################################################
create pfile='$LOG_DIR/$dt/init$cdb_name_bkp_$dt$ts.ora' from spfile;
@$SCRIPTS_DIR/$1 $2
Spool off
EOF
}

sql_execution_pdb ()
{
sqlplus -S "/ as sysdba" <<EOF
set timing on
set trimspool on
spool $LOG_DIR/$dt/$pdbname.txt
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt                    $pdbname
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@$SCRIPTS_DIR/$1 $2
Spool off
EOF
}

health_check ()
{
echo "***********************************************************************"
echo $pdbname
echo "***********************************************************************"
sqlplus -S "/ as sysdba" <<EOF
set timing on
set trimspool on
set escchar $
spool $LOG_DIR/$dt/hccheck_$pdbname.txt
set escchar OFF
alter session set container=$pdbname;
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt                    $pdbname
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@$SCRIPTS_DIR/$1
Spool off
EOF
}

impact_analysis ()
{
cd $LOG_DIR/$dt
echo "***********************************************************************"
echo $pdbname
echo "***********************************************************************"
sqlplus -S "/ as sysdba" <<EOF
set timing on
set trimspool on
alter session set container=$pdbname;
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt                    impact_analysis_report
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@$SCRIPTS_DIR/$1
Spool off
EOF
send_mail $logname
}

db_upgrade_diagnostics ()
{
cd $LOG_DIR/$dt
sqlplus -S "/ as sysdba" <<EOF
set timing on
set trimspool on
alter session set container=$pdbname;
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt                    impact_analysis_report
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

@$SCRIPTS_DIR/$1 $2 $3
EOF

}

db_preupgrade_diagnostics ()
{


cat /etc/oratab |grep 19
echo "***********************************************************************"
echo "			enter target 19C home"
echo "***********************************************************************"
read ORACLE_HOME19C
echo " ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  "
echo "                     Initiating preupgrade.jar          "
echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ "

if [ "$Explicit_Call" == 4  ] 
  then
        logfile_check "$pdb_name"
	set_env
	pdb_count show_pdbs.sql
	pdb_list=`echo $pdb_list|xargs -n 1 printf "%s "`
	echo "***********************************************************************"
	echo " preupgrade.jar will be attempted for $pdb_list"
	echo "***********************************************************************"

	$ORACLE_HOME/jdk/bin/java -jar $ORACLE_HOME19C/rdbms/admin/preupgrade.jar -c "$pdb_list" FILE TEXT DIR $LOG_DIR_PREUPGRADE	
  else
	$ORACLE_HOME/jdk/bin/java -jar $ORACLE_HOME19C/rdbms/admin/preupgrade.jar -c "$pdb_name" FILE TEXT DIR $LOG_DIR_PREUPGRADE
fi
}

Precheck_1_2_Weeks_Prior()
{
logfile_check "$pdb_name"
set_env
pdb_count show_pdbs.sql
#OS
{

echo "***********************************************************************"
echo "CPU Count"
echo "***********************************************************************"
lscpu

echo "***********************************************************************"
echo "Available Memory"
echo "***********************************************************************"
free -g


echo "***********************************************************************"
echo "Total Count of Databases running on CDB => "$count""
echo "***********************************************************************"

echo "***********************************************************************"
echo "srvctl status database -d "$cdb_name""
echo "***********************************************************************"
srvctl status database -d "$cdb_name"

echo "***********************************************************************"
echo "srvctl config database -d "$cdb_name""
echo "***********************************************************************"
srvctl config database -d "$cdb_name"

echo "***********************************************************************"
echo "srvctl status database -d "$cdb_name" -v"
echo "***********************************************************************"
srvctl status database -d "$cdb_name" -v


echo "***********************************************************************"
echo "srvctl status service  -d "$cdb_name" -pdb "$pdb_name""
echo "***********************************************************************"
#12.2,18C it will work
srvctl status service  -d "$cdb_name" -pdb "$pdb_name"


echo "***********************************************************************"
echo "srvctl config service  -d "$pdb_name"|egrep -i 'Service name|Preferred instances|Available instances|Service role'"
echo "***********************************************************************"
srvctl config service  -d "$cdb_name" |egrep -i 'Service name|Preferred instances|Available instances|Service role'


echo "***********************************************************************"
echo "lsnrctl status LISTENER"
echo "***********************************************************************"
lsnrctl status LISTENER

echo "***********************************************************************"
echo "Patch details from source home"
echo "***********************************************************************"
opatch lspatches

} >> "$logname"

sql_execution_cdb cdb_query.sql "$pdb_name"

 if [ "$Explicit_Call" == 3  ]
        then
                                        pdbname="CDB\$ROOT"
                                        echo "***********************************************************************"
                                        echo $pdbname
                                        echo "***********************************************************************"
                                        impact_analysis ACS_19cUpgrade_Data_collect.sql
                                        #db_upgrade_diagnostics dbupgdiag.sql "$LOG_DIR/$dt" "$pdbname"
                                        health_check hccheck.sql
                    for pdbname in ${pdb_list}
                                do
                                        sql_execution_pdb pdb_query.sql "$pdbname"
                                        health_check hccheck.sql
                                        db_upgrade_diagnostics dbupgdiag.sql "$LOG_DIR/$dt" "$pdbname"
				 	#db_preupgrade_diagnostics  "$pdbname" "$LOG_DIR_PREUPGRADE"
							done

pdb_list=`echo $pdb_list|xargs -n 1 printf "%s "`
echo "***********************************************************************"
echo " preupgrade.jar will be attempted for $pdb_list"
echo "***********************************************************************"

cat /etc/oratab |grep 19
echo "***********************************************************************"
echo "                  enter target 19C home"
echo "***********************************************************************"
read ORACLE_HOME19C
echo " ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  "
echo "                     Initiating preupgrade.jar          "
echo "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ "

$ORACLE_HOME/jdk/bin/java -jar $ORACLE_HOME19C/rdbms/admin/preupgrade.jar -c "$pdb_list" FILE TEXT DIR $LOG_DIR_PREUPGRADE

        else
                     pdbname=$pdb_name
                     sql_execution_pdb pdb_query.sql "$pdbname"
                     health_check hccheck.sql
                     impact_analysis ACS_19cUpgrade_Data_collect.sql
                     db_upgrade_diagnostics dbupgdiag.sql "$LOG_DIR/$dt" "$pdbname"
					db_preupgrade_diagnostics "$pdbname" "$LOG_DIR_PREUPGRADE"


 fi

show_main_menu
}

Precheck_1_Day_Prior() ## Work IN Progress ##
{

$VAR_1_Day_Prior.sh 
$VAR_1_Day_Prior.sh 
$VAR_1_Day_Prior.sh 

}

Precheck_1_Hour_Prior()  ## Work IN Progress ##
{
$VAR_1_Hour_Prior.sh
$VAR_1_Hour_Prior.sh
$VAR_1_Hour_Prior.sh

}

Precheck_During_Change_Window() ## Work IN Progress ##
{

$VAR_During_Change_Window.sh
$VAR_During_Change_Window.sh
$VAR_During_Change_Window.sh

}

directory_exists ()
{


         if [ -d "/mount/shared/cifs/housekeeping/oracle_acs" ]
            then
                                SCRIPTS_DIR=/mount/shared/cifs/housekeeping/oracle_acs/upgrade19c/scripts/acs_upgrade_tool
                                mkdir -p /mount/shared/cifs/housekeeping/oracle_acs/upg_tool_logs/"$pdb_name"_"$cdb_name"_"$dt"
                                UPG_TOOL_LOGS=/mount/shared/cifs/housekeeping/oracle_acs/upg_tool_logs/"$pdb_name"_"$cdb_name"_"$dt"


                                if [ "${cdb_name:0:2}" == "LF" ] || [ "${cdb_name:0:2}" == "LR" ]
                                        then
                                                LOG_DIR=/mount/shared/cifs/housekeeping/oracle_acs/upgrade19c/upgrade_logs/life/"$pdb_name"_"$cdb_name"
                                elif [ "${cdb_name:0:2}" == "IR" ] || [ "${cdb_name:0:2}" == "IM" ]
                                        then
                                                LOG_DIR=/mount/shared/cifs/housekeeping/oracle_acs/upgrade19c/upgrade_logs/ir-im/"$pdb_name"_"$cdb_name"
                                elif [ "${cdb_name:0:2}" == "GR" ]
                                        then
                                                LOG_DIR=/mount/shared/cifs/housekeeping/oracle_acs/upgrade19c/upgrade_logs/rs-gr/"$pdb_name"_"$cdb_name"
                                else
                                                LOG_DIR=/mount/shared/cifs/housekeeping/oracle_acs/upgrade19c/upgrade_logs/others/"$pdb_name"_"$cdb_name"
                                fi

                                                                                        mkdir -p "$LOG_DIR"/"$dt"

                                if [ ! -d "$LOG_DIR"/preupgrade_"$dt" ]
                                        then
                                                mkdir -p "$LOG_DIR"/preupgrade_"$dt"
                                                LOG_DIR_PREUPGRADE="$LOG_DIR"/preupgrade_"$dt"
                                else
                                                LOG_DIR_PREUPGRADE="$LOG_DIR"/preupgrade_"$dt"
                                fi

                                if [ ! -d "$LOG_DIR"/upgrade_"$dt" ]
                                        then
                                                mkdir -p "$LOG_DIR"/upgrade_"$dt"
                                                LOG_DIR_UPGRADE="$LOG_DIR"/upgrade_"$dt"
                                        else
                                                LOG_DIR_UPGRADE="$LOG_DIR"/upgrade_"$dt"
                                fi

                                if [ ! -d /mount/shared/cifs/housekeeping/oracle_acs/upg_tool_logs/"$pdb_name"_"$cdb_name"_"$dt" ]
                                        then
                                                mkdir -p /mount/shared/cifs/housekeeping/oracle_acs/upg_tool_logs/"$pdb_name"_"$cdb_name"_"$dt"
                                                UPG_TOOL_LOGS=/mount/shared/cifs/housekeeping/oracle_acs/upg_tool_logs/"$pdb_name"_"$cdb_name"_"$dt"

                                 else
                                                UPG_TOOL_LOGS=/mount/shared/cifs/housekeeping/oracle_acs/upg_tool_logs/"$pdb_name"_"$cdb_name"_"$dt"
                                fi

                                                cd "$UPG_TOOL_LOGS" || exit
                                                cd "$LOG_DIR_UPGRADE" || exit
                                                cd "$LOG_DIR_PREUPGRADE" || exit
                                                                                                cd "$LOG_DIR" || exit

                        else
                         echo "${bred} cannot detect cifs directory check oracle_acs location exist in cifs  ${normal}"
         fi

}


################################## MAIN MENU Function ######################################################
show_main_menu()
{
    NORMAL=$(echo "\033[m")
    MENU=$(echo "\033[36m") #Blue
    NUMBER=$(echo "\033[33m") #yellow
    FGRED=$(echo "\033[41m")
    RED_TEXT=$(echo "\033[31m")
    ENTER_LINE=$(echo "\033[33m")
        #user=`ps -ef|grep  pmon|grep -v +ASM|awk '{print $1}'|head -1`
        user=$(ps -ef|grep  pmon_|grep -v grep|grep -v +ASM |awk '{print $1}'|head -1)
echo -e "${MENU}                                                            ${bgred}[UPGT]${NORMAL}                        ${NORMAL}"
echo -e "${MENU}                                                  ${bgred}DATABASE UPGRADE TOOL${NORMAL}                   ${NORMAL}"
echo ""
echo -e "${MENU}********************************************************************* MENU *******************************************${NORMAL}"
echo -e "${MENU}**${NUMBER} 1)${MENU} Remote Clone                  ${NORMAL}"
echo -e "${MENU}**${NUMBER} 2)${MENU} Unplug Plug                   ${NORMAL}"
echo -e "${MENU}**${NUMBER} 3)${MENU} In Place Autoupgrade          ${NORMAL}"
echo -e "${MENU}**${NUMBER} 4)${MENU} Run preupgrade.jar only for all PDB          ${NORMAL}"
echo -e "${MENU}**${NUMBER} 0)${MENU} EXIT ${NORMAL}"
echo -e "${MENU}**********************************************************************************************************************${NORMAL}"
echo -e "${ENTER_LINE}Please select an upgrade method ..enter a menu option and enter OR  ${RED_TEXT} just Press enter to exit. ${NORMAL}"
read -r opt
        main_menu_options
}
function option_picked() {
    COLOR='\033[01;31m' # bold red
    RESET='\033[00;00m' # normal white
    MESSAGE=${*:-"${RESET}Error: No message passed"}
    echo -e "${COLOR}${MESSAGE}${RESET}"
}

################################## SUB MENU Function ######################################################
show_sub_menu()
{
    NORMAL=$(echo "\033[m")
    MENU=$(echo "\033[36m") #Blue
    NUMBER=$(echo "\033[33m") #yellow
    FGRED=$(echo "\033[41m")
    RED_TEXT=$(echo "\033[31m")
    ENTER_LINE=$(echo "\033[33m")
        #user=`ps -ef|grep  pmon|grep -v +ASM|awk '{print $1}'|head -1`
        user=$(ps -ef|grep  pmon_|grep -v grep|grep -v +ASM |awk '{print $1}'|head -1)
echo -e "${MENU}                                                             ${bgred}[UPGT]${NORMAL}                        ${NORMAL}"
echo -e "${MENU}                                                   ${bgred}DATABASE UPGRADE TOOL${NORMAL}                   ${NORMAL}"
echo -e "${MENU}                                               ${bgred}UPGRADE METHOD : REMOTE CLONE${NORMAL}                   ${NORMAL}"
echo ""
echo -e "${MENU}********************************************************************* MENU *******************************************${NORMAL}"
echo -e "${MENU}**${NUMBER} 1)${MENU} Precheck 1-2 Weeks Prior          ${NORMAL}"
echo -e "${MENU}**${NUMBER} 2)${MENU} Precheck 1       Week  Prior          ${NORMAL}"
echo -e "${MENU}**${NUMBER} 3)${MENU} Precheck 1       Day   Prior          ${NORMAL}"
echo -e "${MENU}**${NUMBER} 4)${MENU} Precheck 1   Hour  Prior          ${NORMAL}"
echo -e "${MENU}**${NUMBER} 5)${MENU} Precheck During Change Window     ${NORMAL}"
echo -e "${MENU}**${NUMBER} 0)${MENU} EXIT ${NORMAL}"
echo -e "${MENU}**********************************************************************************************************************${NORMAL}"
echo -e "${ENTER_LINE}Please select an upgrade method ..enter a menu option and enter OR  ${RED_TEXT} just Press enter to exit. ${NORMAL}"
echo -e "${ENTER_LINE}  ${RED_TEXT} select 0 and enter to jump to main menu. ${NORMAL}"

read -r opt
        sub_menu_options
}
function option_picked() {
    COLOR='\033[01;31m' # bold red
    RESET='\033[00;00m' # normal white
    MESSAGE=${*:-"${RESET}Error: No message passed"}
    echo -e "${COLOR}${MESSAGE}${RESET}"
}

################################## SUB MENU Option ######################################################
sub_menu_options ()
        {
                if [[ $opt = "" ]]; then
                         exit;
                else
                        case $opt in
                                1) clear;
                                        option_picked "Option 1 Picked  --> Precheck 1-2 Weeks Prior   ";
                                       echo ""
                                        #Explicit_Call=1
                                        Precheck_1_2_Weeks_Prior $cdb_name $pdb_name
                                        ;;
                                2) clear;
                                        option_picked "Option 2 Picked  --> Precheck 1  Week Prior   ";
                                        echo ""
                                        #Explicit_Call=1
                                        Precheck_1_Week_Prior
                                        ;;
                                3) clear;
                                        option_picked "Option 3 Picked  --> Precheck 1  Day Prior  ";
                                        echo ""
                                        #Explicit_Call=1
                                        Precheck_1_Day_Prior
                                        ;;
                                4) clear;
                                        option_picked "Option 2 Picked  --> Precheck 1   Hour Prior ";
                                        echo ""
                                        #Explicit_Call=1
                                        Precheck_1_Hour_Prior
                                        ;;
                                5) clear;
                                        option_picked "Option 3 Picked  --> Precheck During Change Window ";
                                        echo ""
                                        #Explicit_Call=1
                                        Precheck_During_Change_Window
                                        ;;

                                0) clear;
                                        option_picked "Pick an option from the menu";
                                        show_main_menu;
                                        ;;
                                '\n') exit;
                                        ;;
                                *) clear;
                                        option_picked "Pick an option from the menu";
                                        show_sub_menu;
                                        ;;
                        esac
                fi
}

################################## Menu MENU Option ######################################################
main_menu_options ()
        {
                if [[ $opt = "" ]]; then
                         exit;
                else
                        case $opt in
                                1) clear;
                                        option_picked "Option 1 Picked  --> Remote Clone   ";
                                        echo ""
                                        Explicit_Call=$opt
                                        show_sub_menu
                                        ;;
                                2) clear;
                                        option_picked "Option 2 Picked  --> Unplug Plug ";
                                        echo ""
                                        Explicit_Call=$opt
                                        show_sub_menu
                                        ;;
                                3) clear;
                                        option_picked "Option 3 Picked  --> In Place Autoupgrade ";
                                        echo ""
                                        Explicit_Call=$opt
                                        show_sub_menu
                                        ;;
								4) clear;
                                        option_picked "Option 4 Picked  --> Run Preupgrade.jar only for all PDB ";
                                        echo ""
                                        Explicit_Call=$opt
										db_preupgrade_diagnostics
                                        ;;
	
                                0) exit ;;
                                '\n') exit;
                                        ;;
                                *) clear;
                                        option_picked "Pick an option from the menu";
                                        show_main_menu;
                                        ;;
                        esac
                fi
}

##############################################  MAIN #######################################################################
        normal=$(echo "\033[m")
        blue=$(echo "\033[36m") #Blue
        yellow=$(echo "\033[33m") #yellow
        white=$(echo "\033[00;00m") # normal white
        bred=$(echo "\033[01;31m") # bold red
        lyellow=$(echo "\e[103m") #background light yellow
        black=$(echo "\e[30m") #black
        byellow=$(echo "\e[43m") #background yellow \e[1m
        bnb=$(echo "\e[1m") # bold and bright
        blink=$(echo "\e[5m") # \e[42m
        blink=$(echo "\e[42m") #bgreen
        bdgray=$(echo "\e[100m") # background dark gray
        bgred=$(echo "\e[41m") # background red


                #Flag menu breakup function call
                Explicit_Call=0
                #input database name
                cdb_name=$1
                pdb_name=$2
                user=`ps -ef|grep  pmon_|grep $cdb_name|awk '{print $1}'|head -1`
                #Today's Date
                dt=$(/bin/date +%d%m%Y)
                ts=$(/bin/date +%H%M%S)
                varhost=$(hostname|cut -d"." -f1)
                #Checking If script Directory Exists
                directory_exists
        clear
                echo -e "${bred} Logged in as $user and running the upgrade assist tool ${normal}"
        show_main_menu
#********************************************END****************************************************************#


