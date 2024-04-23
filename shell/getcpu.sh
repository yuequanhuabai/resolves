#!/bin/sh
#
##脚本功能描述：依据/proc/stat文件获取并计算CPU使用率
#
##CPU时间计算公式：CPU_TIME= user+system+nice+idle+iowait+irq+softirq
##cpu使用率计算公式：cpu_usage=(idle2-idle1)/(cpu2-cpu1)*100
#
#TIME_INTERVAL=5
#
#time=$(date "+%Y-%m-%d %H:%M:%S")
#LAST_CPU_INFO=$(cat /proc/stat | grep -w cpu | awk '{print $2,$3,$4,$5,$6,$7,$8}')
#LAST_SYS_IDLE=$(echo $LAST_CPU_INFO | awk '{print $4}')
#
#echo " LAST_CPU_INFO is "$LAST_CPU_INFO
#echo   " LAST_SYS_IDLE is "$LAST_SYS_IDLE





#
#脚本功能描述：依据/proc/stat文件获取并计算CPU使用率
#
#CPU时间计算公式：CPU_TIME=user+system+nice+idle+iowait+irq+softirq
#CPU使用率计算公式：cpu_usage=(idle2-idle1)/(cpu2-cpu1)*100
#默认时间间隔
TIME_INTERVAL=5
time=$(date "+%Y-%m-%d %H:%M:%S")
LAST_CPU_INFO=$(cat /proc/stat | grep -w cpu | awk '{print $2,$3,$4,$5,$6,$7,$8}')
LAST_SYS_IDLE=$(echo $LAST_CPU_INFO | awk '{print $4}')
LAST_TOTAL_CPU_T=$(echo $LAST_CPU_INFO | awk '{print $1+$2+$3+$4+$5+$6+$7}')
sleep ${TIME_INTERVAL}
NEXT_CPU_INFO=$(cat /proc/stat | grep -w cpu | awk '{print $2,$3,$4,$5,$6,$7,$8}')
NEXT_SYS_IDLE=$(echo $NEXT_CPU_INFO | awk '{print $4}')
NEXT_TOTAL_CPU_T=$(echo $NEXT_CPU_INFO | awk '{print $1+$2+$3+$4+$5+$6+$7}')

#系统空闲时间
SYSTEM_IDLE=`echo ${NEXT_SYS_IDLE} ${LAST_SYS_IDLE} | awk '{print $1-$2}'`
#CPU总时间
TOTAL_TIME=`echo ${NEXT_TOTAL_CPU_T} ${LAST_TOTAL_CPU_T} | awk '{print $1-$2}'`
CPU_USAGE=`echo ${SYSTEM_IDLE} ${TOTAL_TIME} | awk '{printf "%.2f", 100-$1/$2*100}'`
echo "CPU Usage:${CPU_USAGE}%"$time

cpu=`echo "$CPU_USAGE" | cut -d "." -f 1`
if [ $cpu -gt 80 ]
then
    echo "警告，您当前CPU使用率${CPU_USAGE}%，已严重超标"$time | mail -s "Title" yuequanhuabai@qq.com  #此处为发送邮件地址
else
  echo  echo "好消息，您当前CPU使用率${CPU_USAGE}%，正常"$time | mail -s "Title" yuequanhuabai@qq.com  #此处为发送邮件地址
