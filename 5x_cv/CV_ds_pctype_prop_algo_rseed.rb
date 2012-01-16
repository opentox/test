# Do a 10-fold crossvalidation
# # Author: Andreas Maunz, David Vorgrimmler
# # @params: Dataset_name(see dataset_nestle.yaml), pc_type(electronic,cpsa or constitutional ...), prop(true or false), prediction_algorithm(local_mlr_prop or local_svm_regression ...)

if ARGV.size != 5 
  puts "Args: ds_name, pc_type, prop, algo, random_seed"
  puts ARGV.size
  exit
end

ds_file = "datasets_nestle.yaml"
pwd=`pwd`
path = "#{pwd.chop}/#{ds_file}"
if File.exists?(path)
  puts "#{ds_file} exists"
else
  puts "#{ds_file} does not exist."
  exit
end

require 'rubygems'
require 'opentox-ruby'
require 'yaml'

subjectid = nil

ds_name = ARGV[0] # e.g. MOU
pc_type = ARGV[1] # e.g. electronic,cpsa
prop = ARGV[2]    # true or false
algo = ARGV[3]    # e.g. local_svm_regression, local_mlr_prop
r_seed = ARGV[4]  # 1, 2, ..., 10

ds = YAML::load_file("datasets_nestle.yaml")
ds_uri = ds[ds_name]["dataset"]
pc_ds_uri = ds[ds_name][pc_type]

algo_params = "pc_type=#{pc_type}";
algo_params += ";feature_dataset_uri=#{pc_ds_uri}"
algo_params += ";propositionalized=#{prop}"
algo_params += ";prediction_algorithm=#{algo}"
puts algo_params.to_yaml

prediction_feature = OpenTox::Dataset.find(ds_uri).features.keys.first


# Ready
cv_args = {}
cv_args[:dataset_uri] = ds_uri
cv_args[:prediction_feature] = prediction_feature
cv_args[:algorithm_uri] = "http://toxcreate3.in-silico.ch:8087/algorithm/lazar"
cv_args[:algorithm_params] = algo_params
cv_args[:stratified] = false
cv_args[:random_seed] = r_seed
puts cv_args.to_yaml

cv = OpenTox::Crossvalidation.create(cv_args).uri
puts cv

cvr = OpenTox::CrossvalidationReport.create( cv , subjectid).uri
puts cvr
