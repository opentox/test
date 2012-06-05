# Do a 10-fold crossvalidation
# # Author: Andreas Maunz, David Vorgrimmler
# # @params: Dataset_name(see dataset_nestle.yaml), pc_type(electronic,cpsa or constitutional ... or nil to disable), prediction_algorithm(local_mlr_prop or local_svm_regression ...)

if ARGV.size != 4 
  puts "Args: ds_name, pc_type, algo, random_seed"
  puts ARGV.size
  exit
end

ds_file = "datasets.yaml"
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
pc_type = ARGV[1] # e.g. electronic,cpsa or nil to disable
algo = ARGV[2]    # e.g. local_svm_regression, local_mlr_prop
r_seed = ARGV[3]  # 1, 2, ..., 10

ds = YAML::load_file("datasets.yaml")
#ds_uri = ds[ds_name]["dataset"]
#ds_test_target_uri = ds[ds_name]["dataset"]
ds_test_uri = ds[ds_name]["test"]
ds_training_uri = ds[ds_name]["training"]
pc_ds_uri = ds[ds_name][pc_type]

algo_params = "prediction_algorithm=#{algo}"
algo_params += ";pc_type=#{pc_type}" unless pc_type == "nil" 
algo_params += ";feature_dataset_uri=#{pc_ds_uri}" unless pc_type == "nil" 
algo_params += ";lib=cdk"
#algo_params += ";min_sim=0.3"
#algo_params += ";min_chisq_significance=0.9"
#algo_params += ";min_frequency=6"
#algo_params += ";feature_type=trees"

puts algo_params.to_yaml

prediction_feature = OpenTox::Dataset.find(ds_training_uri).features.keys.first


# Ready
cv_args = {}
#cv_args[:dataset_uri] = ds_uri
cv_args[:test_dataset_uri] = ds_test_uri
cv_args[:training_dataset_uri] = ds_training_uri
#cv_args[:test_target_dataset_uri] = ds_test_target_uri
cv_args[:prediction_feature] = prediction_feature
cv_args[:algorithm_uri] = File.join(CONFIG[:services]["opentox-algorithm"],"lazar")
cv_args[:algorithm_params] = algo_params
#cv_args[:stratified] = false
#cv_args[:random_seed] = r_seed
puts cv_args.to_yaml

ttv = OpenTox::RestClientWrapper.post( File.join(CONFIG[:services]["opentox-validation"],"training_test_validation"), cv_args )
puts ttv

vr = OpenTox::ValidationReport.create( ttv , subjectid).uri
puts vr
