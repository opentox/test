# Do a 10-fold crossvalidation
# # Author: Andreas Maunz, David Vorgrimmler
# # @params: Dataset_name(see dataset.yaml), pc_type(electronic,cpsa or constitutional ... or nil to disable), prediction_algorithm(local_mlr_prop or local_svm_regression ...), algo_params (e.g. ;param_name1=param_value1;param_name2=param_value2 or nil), random_seed (1, 2, ... or 10), path (e.g. ../data/dataset.yaml)

require 'rubygems'
require 'opentox-ruby'
require 'yaml'

if ARGV.size != 3 
  puts "Args: path/to/dataset.yaml ds_name num_boots"
  puts ARGV.size
  exit
end

path = ARGV[0]
ds_file = path.split("/").last

if File.exists?(path)
  puts "[#{Time.now.utc.iso8601(4).to_s}] #{ds_file} exists."
else
  puts "#{ds_file} does not exist."
  exit
end

subjectid = nil

ds_name = ARGV[1] # e.g. MOU
num_boots = ARGV[2] # e.g. electronic,cpsa or nil to disable

ds = YAML::load_file("#{path}")
ds_uri = ds[ds_name]["dataset"]

algo_params = {}
algo_params["dataset_uri"] = ds_uri
algo_params["num_boots"] = num_boots

puts "[#{Time.now.utc.iso8601(4).to_s}] #{algo_params.to_yaml}"

ds = OpenTox::Dataset.find(ds_uri)
ds_nr_de = ds.data_entries.size
ds_nr_com = ds.compounds.size
t = Time.now
result_uri = OpenTox::RestClientWrapper.post( File.join(CONFIG[:services]["opentox-algorithm"],"fminer/bbrc/sample"), algo_params )
duration = Time.now - t
ds_result = OpenTox::Dataset.find(result_uri)
ds_result_nr_de = ds_result.data_entries.size
ds_result_nr_com = ds_result.compounds.size
ds_result_nr_f = ds_result.features.size

min_sampling_support = ds_result.metadata[OT::parameters][2][OT::paramValue]
num_boots = ds_result.metadata[OT::parameters][3][OT::paramValue] 
min_frequency_per_sample = ds_result.metadata[OT::parameters][4][OT::paramValue]
nr_hits = ds_result.metadata[OT::parameters][5][OT::paramValue]
merge_time = ds_result.metadata[OT::parameters][6][OT::paramValue]
n_stripped_mss = ds_result.metadata[OT::parameters][7][OT::paramValue]
n_stripped_cst = ds_result.metadata[OT::parameters][8][OT::paramValue]
random_seed = ds_result.metadata[OT::parameters][9][OT::paramValue]

puts
puts "[#{Time.now.utc.iso8601(4).to_s}] Bbrc result: #{result_uri}"
puts "[#{Time.now.utc.iso8601(4).to_s}] nr dataentries: #{ds_result_nr_de} , (of #{ds_nr_de} )"
puts "[#{Time.now.utc.iso8601(4).to_s}] nr dataentries: #{ds_result_nr_com} , (of #{ds_nr_com} )"
puts "[#{Time.now.utc.iso8601(4).to_s}] nr features: #{ds_result_nr_f}"
puts "[#{Time.now.utc.iso8601(4).to_s}] Merge time: #{merge_time}"
puts "[#{Time.now.utc.iso8601(4).to_s}] Duration: #{duration}"

puts "=hyperlink(\"#{ds_uri}\";\"#{ds_name}\"),#{num_boots},#{min_sampling_support},#{min_frequency_per_sample},#{nr_hits},=hyperlink(\"#{result_uri}\";\"bbrc_result\"),#{ds_result_nr_com},#{ds_nr_com},#{ds_result_nr_f},#{duration},#{merge_time},#{n_stripped_mss},#{n_stripped_cst},#{random_seed}"

puts "------------------------"
puts

