# Do a five times 10-fold crossvalidation
# # Author: Andreas Maunz, David Vorgrimmler
# # @params: CSV-File, Method (LAST, BBRC), Minimum Frequency

require 'rubygems'
require 'opentox-ruby'
require 'lib/cv_am.rb'

subjectid = nil

if ARGV.size != 1
  puts
  puts "Error! Arguments: <algorithm_params> in the form p1=v1;p2=v2;...;pn=vn"
  exit 1
end

# Arguments for lib/cv.rb: file_or_dataset_uri feature_generation min_frequency min_chisq_significance backbone stratified random_seed prediction_algorithm local_svm_kernel nr_hits conf_stdev pc_type
position_mapper={
  "dataset_uri" => 0, 
  "feature_generation_uri" => 1,
  "min_frequency" => 2,
  "min_chisq_significance" => 3,
  "backbone" => 4,
  "stratified" => 5,
  "random_seed" => 6,
  "prediction_algorithm" => 7,
  "local_svm_kernel" => 8,
  "nr_hits" => 9,
  "conf_stdev" => 10,
  "pc_type" => 11
}

param_str=$ARGV[0]
puts param_str
params = Array.new(position_mapper.size,"")
param_str.split(";").each { |param|
  k,v = param.split("=")
  params[position_mapper[k]] = v
}
params[5]="false" # stratified 

exception_config = YAML.load_file("exceptions_config.yaml")
if ! exception_config[params[0]].nil?
  exception_config[params[0]].each { |k,v|
    puts "Setting exception: #{k} => #{v}"
    params[position_mapper[k]] = v
  }
end

i=1
#for i in 1..5
  begin
    puts
    puts "Round #{i.to_s}."
    params[6]=i # random seed
    cv(params)
  rescue Exception => e
    puts "Error in 5xCV: #{e.message}: #{e.backtrace}"
  end
#end
