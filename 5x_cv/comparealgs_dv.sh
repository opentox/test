#!/bin/bash

if [ $# -ne 4 ]; then
  echo "\"validation_uri1,validation_uri2,...\" \"identifier1,identifier2,...\" \"significance [0.95-0.6]\" \"attributes: weighted_r_square,weighted_root_mean_squared_error,weighted_mean_absolute_error,r_square,root_mean_squared_error,sample_correlation_coefficient\""
  exit 1
fi

uris="$1"
iden="$2"
signi="$3" #default 0.9; 0.95 - 0.6
attri="$4" #weighted_r_square,weighted_root_mean_squared_error,weighted_mean_absolute_error,r_square,root_mean_squared_error,sample_correlation_coefficient
host="toxcreate3.in-silico.ch:8080"

curl -X POST -d "validation_uris=$uris" -d "identifier=$iden" -d "ttest_significance=$signi" -d "ttest_attributes=$attri" http://$host/validation/report/algorithm_comparison
