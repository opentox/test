# Do a 10-fold crossvalidation
# # Author: Andreas Maunz, David Vorgrimmler
# # @params: Dataset_name(see dataset.yaml), pc_type(electronic,cpsa or constitutional ... or nil to disable), prediction_algorithm(local_mlr_prop or local_svm_regression ...), algo_params (e.g. ;param_name1=param_value1;param_name2=param_value2 or nil), random_seed (1, 2, ... or 10), path (e.g. ../data/dataset.yaml)

require 'rubygems'
require 'opentox-ruby'
require 'yaml'

if ARGV.size != 6 
  puts "Args: ds_name, pc_type, algo, algo_params, random_seed, path/to/dataset.yaml"
  puts ARGV.size
  exit
end

#ds_file = "datasets.yaml"
#pwd=`pwd`
#path = "#{pwd.chop}/../data/#{ds_file}"
path = ARGV[5]
ds_file = path.split("/").last

if File.exists?(path)
  puts "[#{Time.now.utc.iso8601(4).to_s}] #{ds_file} exists."
else
  puts "#{ds_file} does not exist."
  exit
end

subjectid = nil

ds_name = ARGV[0] # e.g. MOU
pc_type = ARGV[1] # e.g. electronic,cpsa or nil to disable
algo = ARGV[2]    # e.g. local_svm_regression, local_mlr_prop
user_algo_params = ARGV[3] #e.g. ;param_name1=param_value1;param_name2=param_value2
r_seed = ARGV[4]  # 1, 2, ..., 10

ds = YAML::load_file("#{path}")
ds_uri = ds[ds_name]["dataset"]
pc_ds_uri = ds[ds_name][pc_type]

algo_params = "prediction_algorithm=#{algo}"
algo_params += ";pc_type=#{pc_type}" unless (pc_type == "nil") || (pc_ds_uri.include? 'pc_type') 
algo_params += ";feature_dataset_uri=#{pc_ds_uri}" unless (pc_type == "nil") || (pc_ds_uri.include? 'feature_dataset_uri') 
algo_params += "#{user_algo_params}" unless user_algo_params == "nil"
#algo_params += ";min_chisq_significance=0.9"
#algo_params += ";min_frequency=6"
#algo_params += ";feature_type=trees"

puts "[#{Time.now.utc.iso8601(4).to_s}] #{algo_params.to_yaml}"

prediction_feature = OpenTox::Dataset.find(ds_uri).features.keys.first


# Ready
cv_args = {}
cv_args[:dataset_uri] = ds_uri
cv_args[:prediction_feature] = prediction_feature
cv_args[:algorithm_uri] = "http://toxcreate3.in-silico.ch:8085/algorithm/lazar"
cv_args[:algorithm_params] = algo_params
cv_args[:loo] = true
puts "[#{Time.now.utc.iso8601(4).to_s}] #{cv_args.to_yaml}"

loo = OpenTox::RestClientWrapper.post( File.join(CONFIG[:services]["opentox-validation"],"crossvalidation/loo"), cv_args )
puts "[#{Time.now.utc.iso8601(4).to_s}] #{loo}"

cvr = OpenTox::CrossvalidationReport.create( loo , subjectid).uri
puts "[#{Time.now.utc.iso8601(4).to_s}] #{cvr}"
