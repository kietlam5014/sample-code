#!/bin/bash
#
# Author: Kiet Lam
#
# Run by cron job: run daily to check for copyright violation
#


## Set Environment
#
export PATH=/usr2/c_kietl/bin:/usr/local/bin:/usr/bin:/bin:/usr/bin/X11:/usr/games:/pkg/icetools/bin:/pkg/hwtools/bin:/pkg/netscape/bin:/pkg/gnu/bin:/sbin
export PYTHONPATH=/usr2/c_kietl/dist-packages/lib/python2.6/site-packages
export USER=c_kietl
export CMAILS=c_kietl,pdhavali,c_akashp,snandini,c_vpitan,c_yangw,

## Defined variables
#
BDATE=$(date)
HOST=$(hostname)
WSP=/prj/qct/asw/engbuilds/scl/users04/$USER
SCL=/prj/qca/swcbi/santaclara/dev01/sw_build/Engineering/workspace/LA/PRIMA/cron
STATUS=0
BRANCH=kk
AU=AU_LINUX_ANDROID_KK_3.5.04.04.02.003.292
SCRIPTS=$SCL/scripts
MASTER=$SCL/master
MASTER_WLAN=$MASTER/vendor/qcom/proprietary/wlan-noship
CAF=$SCL/cafstaging
CAF_WLAN=$CAF/vendor/qcom/proprietary/wlan-noship
export KK35WLAN=$SCL/$AU


## Build Info
#
echo '<html>'
echo '<body>'
echo '<pre>'

echo "INFO: Build info"
echo "================"
echo "Date: $BDATE"
echo "Path: $PATH"
echo "Host: $HOST"
echo 'scripts path : \\wallace\scl_swcbi\sw_build\Engineering\workspace\LA\PRIMA\cron\scripts'
echo 'cafstage path: \\wallace\scl_swcbi\sw_build\Engineering\workspace\LA\PRIMA\cron\cafstaging'
echo 


## Get list of approved gerrits
#
echo "INFO: Get list of approved gerrits"
echo "=================================="
pushd $SCRIPTS
  echo -n>Input_gerritlist.txt
  echo -n>Input_gerritlist.temp
  python getAllApprovedGerrits.py -b $BRANCH -i Input_gerritlist.txt -p platform/vendor/qcom-proprietary/wlan -t apq8084 &>/dev/null
  if [ $? -ne 0 ]; then
      exit 1
  fi
  n=$(cat Input_gerritlist.txt | wc -l)
  if [ $n -eq 1 ]; then
      echo "INFO: No new gerrits. Exit"
      exit 1
  fi
  python dependencyOrder.py -f Input_gerritlist.txt &>/dev/null
  cat Input_gerritlist.txt | xargs
  rm -f ~/temp/Input_gerritlist.txt
  cp -fp Input_gerritlist.txt ~/temp
popd


## Sync to tip of caf
#
#echo "INFO: Sync to tip of caf"
#echo "==========================="
pushd $CAF_WLAN &>/dev/null
  git fetch quic &>/dev/null
  git reset --hard quic/cafstaging &>/dev/null
popd &>/dev/null


## Cherry pick gerrits onto caf
#
echo "INFO: Cherry pick gerrits onto tip of caf"
echo "========================================="
pushd $CAF
  if [ ! -f cherrypickle_orgin.py ]; then
      cp -p $SCRIPTS/cherrypickle_orgin.py .
  fi
  python cherrypickle_orgin.py apply `cat $SCRIPTS/Input_gerritlist.txt`
  echo "cherry-pick done"
popd


## Scan for copyright/prprietary violations
#
echo "INFO: Scan for copyright violations"
echo "==================================="
pushd $CAF_WLAN
  bash $SCRIPTS/cr-search.sh -s caf -t apq8084
  STATUS=$?
popd

echo '</pre>'
echo '</body>'
echo '</html>'

## Send Email
#
if [ $STATUS -ne 0 ]; then
  echo "Subject: ERROR: CR Check Fail" > ~/temp/subject
else
  echo "Subject: INFO: CR Check Pass" > ~/temp/subject
fi
cat $SCRIPTS/mailheader ~/temp/subject ~/cron-checkCR.log | /usr/lib/sendmail -t
