#!/bin/bash
# Wrapper Skript for CV
# Reads factors_config, ../data/datasets.yaml and performs cv's
# Andreas Maunz, David Vorgrimmler,  2012

if [ $# -lt 2 ]; then
  echo "Usage: $0 factors path/to/dataset.yaml"
  exit
fi

#PWD=`pwd`
#echo $PWD
#if [ ! -f $PWD/../data/datasets.yaml ] 
if [ ! -f $2 ] 
then
  echo "datasets.yaml does not exist."
  exit
fi

# Configure basics
source $HOME/.bash_aliases
otconfig
THIS_DATE=`date +%Y%m%d_%H_`
CV="CV_ds_pctype_algo_rseed_LOAEL_loo_dv.rb"
FACTORS="$1"

# Don't start when running
while ps x | grep $CV | grep -v grep >/dev/null 2>&1; do sleep 30; done

LOGFILE="$THIS_DATE""$USER""_wrapper_pc_cv_LOAEL_loo.log"
#rm "$LOGFILE" >/dev/null 2>&1
if [ -f $LOGFILE ]
then
  LOGFILE="$LOGFILE`date +%M%S`"
fi


cat $FACTORS | while read factor; do
  if ! [[ "$factor" =~ "#" ]]; then # allow comments
    for r_seed in 1 #2 3 4 5
    do
      factor="$factor $r_seed"
      echo "${THIS_DATE}: $factor" >> $LOGFILE>&1
      echo "ruby $CV $factor $2" >> $LOGFILE 2>&1
      ruby $CV $factor $2>> $LOGFILE 2>&1
      echo >> $LOGFILE 2>&1
    done
  fi
done

