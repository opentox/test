#!/bin/bash
# Wrapper Skript 
# Creates selected feature ds from datasets.yaml
# David Vorgrimmler,  2012

PWD=`pwd`
echo $PWD
if [ ! -f $PWD/../datasets.yaml ] 
then
  echo "datasets.yaml does not exist."
  exit
fi

# Configure basics
source $HOME/.bash_aliases
otconfig
THIS_DATE=`date +%Y%m%d_%H_`
SFD="create_selected_feature_ds.rb"

# Don't start when running
while ps x | grep $SFD | grep -v grep >/dev/null 2>&1; do sleep 5; done

for i in 1 2 3
do
  otreload
  sleep 5
  LOGFILE=""$THIS_DATE""$i"_boot_150_sfd.log"
  #rm "$LOGFILE" >/dev/null 2>&1
  echo "Start "$i""
  echo "ruby $SFD" >> $LOGFILE 2>&1
  ruby $SFD >> $LOGFILE 2>&1
done
