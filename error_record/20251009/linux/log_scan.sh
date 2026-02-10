#!/bin/bash

LOGPATH=/opt/project/SMP/log/
LOG=smpEeeorMonotor.log
SPJOB_SQLPATH=/opt/project/SMP/specialJob/dataRetrieval/
SPJOB_LOGPATH=/opt/project/SMP/log/specialJob/
SPJOB_SQL=
REMOTEPATH=/home/smp/prdlog/

Date=`date +%Y/%m/%d`
Time=`date +%H:%M`
Time=`expr substr $Time 1 4`
min=`expr substr $Time 3 4`
DatePrint=`date +%Y%m%d_%H%M`
ECCLOG="smp#CC.log.${DatePrint}"

echo "Check Error Period" $Date ${Time}0 - $Date ${Time}-9
echo "Sleep 65 seconds"
sleep 65

#================================MINNOR ECC Call===========================================

#grep ERR $LOGPATH$LOG |

grep "$Date $Time" $LOGPATH$LOG |
grep -vn 'Role does not exist in SMP'
grep -vn 'RECORD NOT FOUND' |
grep -vn 'Error of get wts code' |
grep -vn 'BypassLoginAction'|
grep -vn 'INVALID CIF NO' |
grep -vn 'Stp Txn Cache Object not found' |
grep -vn 'WARN' |
grep -vn 'The number of host variable' |
grep -vn 'BNDFINQM HOST MSG\: \[APPL UNIT < MIN UNIT]' |
grep -vn 'BNDFINQM HOST MSG\: \[APPL UNIT > MAX UNIT]' |
grep -vn 'INVALID HAND CHG'
grep -vn 'findUserRight' |
grep -vn 'exception.UserNo' |
grep -vn 'exception.RecordNotF' |
tee $LOGPATH$ECCLOG

lines_all=`grep -ci ERR "$LOGPATH$ECCLOG"`
lines_sessionout=`grep ERR "$LOGPATH$ECCLOG" | grep -ci "l_stpHistoryOid is null, probably due to session timeout"`
lines=`expr $lines_all - $lines_sessionout`

ERR_SOURCE=`grep ERR "$LOGPATH$ECCLOG" | grep -v "session timeout" | awk -F '\] \[\-?[0-9]+ ' '{print "["$2}' | tr "\n" " "`

if [ $lines -gt 0 ]; then
  /opt/Tivoli/tecad_stdapp/bin/postemsg -f /opt/Tivoli/tecad_stdapp/etc/tecad_logfile.conf -r MINOR -m "Warning message detected ${ERR_SOURCE}, please check," hostname=[@SMP,ECC.HOSTNAME@] sub_source="B-SMP-SMP-APP" HEalth_Check UNX0000C

#echo "excel" > eccCheck.sftp
#echo "cd ${REMOTEPATH}">> eccCheck.sftp
#echo "put $LOGPATH$ECCLOG" >> eccCheck.sftp
#echo "bye" >> eccCheck.sftp
#sftp -b eccCheck.sftp smp@10.102.222.231
#rm eccCheck.sftp

else
  rm $LOGPATH$ECCLOG
fi


#================================MINNOR EWP ECC Call===========================================
EWPLOG=ewpECC.log
EWPEccLog="smpECC_EWP.log.${DatePrint}"

grep "$Date $Time" $LOGPATH$EWPLOG |
grep "ERR" > $LOGPATH$EWPEccLog

lines=`grep -ci ERR "$LOGPATH$EWPEccLog"`

if [ $lines -gt 0 ]; then
  /opt/Tivoli/tecad_stdapp/bin/postemsg -f /opt/Tivoli/tecad_stdapp/etc/tecad_logfile.conf -r MINOR -m "EWP Warning message detected, please check $EWPEccLog." hostname=[@SMP.ECC.HOSTNAME] sub_source="B-SMP-SMP-APP" Health_Check UNX0000C
else
  rm $LOGPATH$EWPEccLog
fi

echo "Check Error Period End"