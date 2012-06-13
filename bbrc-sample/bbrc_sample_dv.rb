# # Author: Andreas Maunz, David Vorgrimmler

require 'rubygems'
require 'opentox-ruby'
require 'yaml'

if ARGV.size != 6 
  puts "Args: path/to/dataset.yaml ds_name num_boots backbone min_frequency method"
  puts ARGV.size
  exit
end

path = ARGV[0]
ds_file = path.split("/").last

if File.exists?(path)
  puts "[#{Time.now.iso8601(4).to_s}] #{ds_file} exists."
else
  puts "#{ds_file} does not exist."
  exit
end

subjectid = nil

ds_name = ARGV[1] # e.g. MOU
num_boots = ARGV[2] # e.g. electronic,cpsa or nil to disable
backbone = ARGV[3] # true/false
min_freq = ARGV[4] # [100, 90, ..., 10]
method = ARGV[5] # MLE, MEAN, BBRC
hits = false

ds = YAML::load_file("#{path}")
ds_uri = ds[ds_name]["dataset"]

result1 = []
result2 = []
metadata = []

for i in 1..50
  puts
  puts "--------------------------- Round: #{i} ---------------------------"

  # SPLIT
  puts "                       ----- split ds -----"
  split_params = {}
  split_params["dataset_uri"] = ds_uri
  split_params["prediction_feature"] = (ds_uri.to_s + "/feature/1")
  split_params["stratified"] = true 
  split_params["split_ratio"] = 0.5
  split_params["random_seed"] = i
  puts "[#{Time.now.iso8601(4).to_s}] Split params: #{split_params.to_yaml}"

  split_result = OpenTox::RestClientWrapper.post( File.join(CONFIG[:services]["opentox-validation"],"plain_training_test_split"), split_params)
  datasets = {}
  datasets[:training_ds] = split_result.inspect.gsub(/"/,'').split("\\n")[0]
  datasets[:test_ds] = split_result.inspect.gsub(/"/,'').split("\\n")[1]
  puts "[#{Time.now.iso8601(4).to_s}] Split result: #{datasets.to_yaml}"
  puts

  # BBRC sample
  puts "                ----- bbrc feature calulation -----"
  algo_params = {}
  algo_params["dataset_uri"] = datasets[:training_ds]
  algo_params["backbone"] = backbone
  algo_params["min_frequency"] = min_freq
  algo_params["nr_hits"] = hits
  algo_params["method"] = method

  t = Time.now
  if method == "bbrc"
    puts "[#{Time.now.iso8601(4).to_s}] BBRC params: #{algo_params.to_yaml}"
    feature_dataset_uri = OpenTox::RestClientWrapper.post( File.join(CONFIG[:services]["opentox-algorithm"],"fminer/bbrc"), algo_params )
  else
    algo_params["num_boots"] = num_boots
    algo_params["random_seed"] = i
    puts "[#{Time.now.iso8601(4).to_s}] BBRC params: #{algo_params.to_yaml}"
    feature_dataset_uri = OpenTox::RestClientWrapper.post( File.join(CONFIG[:services]["opentox-algorithm"],"fminer/bbrc/sample"), algo_params )
  end
  duration = Time.now - t
  puts "[#{Time.now.iso8601(4).to_s}] BBRC duration: #{duration}"
  puts "[#{Time.now.iso8601(4).to_s}] BBRC result: #{feature_dataset_uri}"
  puts

  # Match
  puts "                      ----- bbrc match -----"
  match_params = {}
  match_params["feature_dataset_uri"] = "#{feature_dataset_uri}"
  match_params["dataset_uri"] = datasets[:test_ds]
  match_params["min_frequency"] = min_freq
  match_params["nr_hits"] = hits
  puts "[#{Time.now.iso8601(4).to_s}] Match params: #{match_params.to_yaml}"

  matched_dataset_uri = OpenTox::RestClientWrapper.post(File.join(CONFIG[:services]["opentox-algorithm"],"fminer","bbrc","match"),match_params)
  puts "[#{Time.now.iso8601(4).to_s}] BBRC match result: #{matched_dataset_uri}"
  puts

  # Compare pValues
  puts "                 ----- pValue comparision -----"
  bbrc_ds = OpenTox::Dataset.find(feature_dataset_uri)
  bbrc_smarts_pValues = {}
  bbrc_ds.features.each do |f, values|
    if values[RDF::type].include?(OT.Substructure)
      bbrc_smarts_pValues[values[OT::smarts]] =  values[OT::pValue]
    end
  end 

  match_ds = OpenTox::Dataset.find(matched_dataset_uri)
  matched_smarts_pValues = {}
  match_ds.features.each do |f, values|
    if values[RDF::type].include?(OT.Substructure)
      matched_smarts_pValues[values[OT::smarts]] =  values[OT::pValue]
    end
  end

  sum_E1 = 0.0
  sum_E2 = 0.0
  bbrc_smarts_pValues.each do |s, p|
    if matched_smarts_pValues.include?(s)
      dif = (p.to_f - matched_smarts_pValues[s].to_f).abs
      sum_E1 = sum_E1 + dif 
      sum_E2 = sum_E1 + dif**2
    end
  end 
  puts "[#{Time.now.iso8601(4).to_s}] Sum pValue difference (E1): #{sum_E1}"
  puts "[#{Time.now.iso8601(4).to_s}] Squared sum pValue difference (E2): #{sum_E2}"
 
  # Save data 
  result1 << sum_E1
  result2 << sum_E2
  
  info = []
  info << { :ds_name => ds_name, :nr_features => bbrc_ds.features.size} 
  info << split_params
  info << algo_params
  info << match_params
  
  metadata << info

  #  ds = OpenTox::Dataset.find(datasets[:training_ds])
  #  ds_nr_de = ds.data_entries.size
  #  ds_nr_com = ds.compounds.size
  #
  #  ds_result = OpenTox::Dataset.find(result_uri)
  #  ds_result_nr_de = ds_result.data_entries.size
  #  ds_result_nr_com = ds_result.compounds.size
  #  ds_result_nr_f = ds_result.features.size
  #
  #  min_sampling_support = ds_result.metadata[OT::parameters][2][OT::paramValue]
  #  num_boots = ds_result.metadata[OT::parameters][3][OT::paramValue] 
  #  min_frequency_per_sample = ds_result.metadata[OT::parameters][4][OT::paramValue]
  #  nr_hits = ds_result.metadata[OT::parameters][5][OT::paramValue]
  #  merge_time = ds_result.metadata[OT::parameters][6][OT::paramValue]
  #  n_stripped_mss = ds_result.metadata[OT::parameters][7][OT::paramValue]
  #  n_stripped_cst = ds_result.metadata[OT::parameters][8][OT::paramValue]
  #  random_seed = ds_result.metadata[OT::parameters][9][OT::paramValue]
  #
  #  puts "[#{Time.now.iso8601(4).to_s}] nr dataentries: #{ds_result_nr_de} , (of #{ds_nr_de} )"
  #  puts "[#{Time.now.iso8601(4).to_s}] nr dataentries: #{ds_result_nr_com} , (of #{ds_nr_com} )"
  #  puts "[#{Time.now.iso8601(4).to_s}] nr features: #{ds_result_nr_f}"
  #  puts "[#{Time.now.iso8601(4).to_s}] Merge time: #{merge_time}"
  #
  #  puts "=hyperlink(\"#{ds_uri}\";\"#{ds_name}\"),#{num_boots},#{min_sampling_support},#{min_frequency_per_sample},#{nr_hits},=hyperlink(\"#{result_uri}\";\"bbrc_result\"),#{ds_result_nr_com},#{ds_nr_com},#{ds_result_nr_f},#{duration},#{merge_time},#{n_stripped_mss},#{n_stripped_cst},#{random_seed}"

  puts

end

puts "############################################"
puts "############# FINAL RESULTS ################"
puts "############################################"
puts
puts "[#{Time.now.iso8601(4).to_s}] metadata: #{metadata.to_yaml}"
puts
puts "[#{Time.now.iso8601(4).to_s}] result1: #{result1.to_yaml}"
puts
puts "[#{Time.now.iso8601(4).to_s}] result2: #{result2.to_yaml}"
