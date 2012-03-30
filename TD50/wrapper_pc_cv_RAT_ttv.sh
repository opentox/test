#!/bin/bash
# Wrapper Skript for CV
# Reads factors_config, ../data/datasets.yaml and performs cv's
# Andreas Maunz, David Vorgrimmler,  2012

if [ $# -lt 1 ]; then
  echo "Usage: $0 factors"
  exit
fi

PWD=`pwd`
echo $PWD
if [ ! -f $PWD/datasets.yaml ] 
then
  echo "datasets.yaml does not exist."
  exit
fi

# Configure basics
source $HOME/.bash_aliases
otconfig
THIS_DATE=`date +%Y%m%d_%H_`
CV="CV_ds_pctype_algo_rseed_RAT_ttv.rb"
FACTORS="$1"

# Don't start when running
while ps x | grep $CV | grep -v grep >/dev/null 2>&1; do sleep 3; done

LOGFILE="$THIS_DATE""$USER""_wrapper_pc_cv_RAT_ttv.log"
rm "$LOGFILE" >/dev/null 2>&1


cat $FACTORS | while read factor; do
  if ! [[ "$factor" =~ "#" ]]; then # allow comments
    for r_seed in 1 #2 3 4 5
    do
      factor="$factor $r_seed"
      echo "${THIS_DATE}: $factor" >> $LOGFILE>&1
      echo "ruby $CV $factor" >> $LOGFILE 2>&1
      ruby $CV $factor >> $LOGFILE 2>&1
      echo >> $LOGFILE 2>&1
    done
  fi
done

