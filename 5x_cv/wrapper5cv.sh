#!/bin/bash
# Wrapper Skript for CV
# Set Factors, Datasets, Exceptions in the respective config_files
# AM, 2011

if [ $# -lt 2 ]; then
  echo "Usage: $0 factors datasets"
  exit
fi

# Configure basics
source $HOME/.bash_aliases
otconfig
THIS_DATE=`date +%Y%m%d_%H_`
FACTORS="$1"
DATASETS="$2"

# Don't start when running
while ps x | grep 5x | grep -v grep >/dev/null 2>&1; do sleep 3; done

LOGFILE="$THIS_DATE""$USER""_wrapper5cv.log"
rm "$LOGFILE" >/dev/null 2>&1

cat $DATASETS | while read dataset_uri; do
  if ! [[ "$dataset_uri" =~ "#" ]]; then # allow comments
    cat $FACTORS | while read factor; do
      if ! [[ "$factor" =~ "#" ]]; then # allow comments
        echo "${THIS_DATE}: $factor" >> $LOGFILE>&1
        factor="$factor;dataset_uri=$dataset_uri"
        echo "ruby 5x_crossvalidation.rb $factor" >> $LOGFILE 2>&1
        ruby 5x_crossvalidation.rb $factor >> $LOGFILE 2>&1
      fi
    done
  else
   echo >> $LOGFILE 2>&1
   echo $dataset_uri >> $LOGFILE 2>&1
  fi
done
