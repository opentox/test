# # Author: Andreas Maunz, David Vorgrimmler

require 'rubygems'
require 'opentox-ruby'
require 'yaml'

if ARGV.size != 2 
  puts "Args: path/to/dataset.yaml ds_name"
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

ds = YAML::load_file("#{path}")
ds_uri = ds[ds_name]["dataset"]

algo_params = {}
algo_params["dataset_uri"] = ds_uri


ds = OpenTox::Dataset.find(ds_uri)
ds_nr_de = ds.data_entries.size
ds_nr_com = ds.compounds.size

[true,false].each do |bb|
  min_freq = 110
  duration = 0.0
  while duration < 60.0 && min_freq > 10 do
    min_freq = min_freq - 10
    algo_params["min_frequency"] = min_freq.to_s + "pm"
    algo_params["backbone"] = bb
    #algo_params["nr_hits"] = false
    #algo_params["feature_type"] = true
    
    
    puts "[#{Time.now.iso8601(4).to_s}] #{algo_params.to_yaml}"
    t = Time.now
    result_uri = OpenTox::RestClientWrapper.post( File.join(CONFIG[:services]["opentox-algorithm"],"fminer/bbrc/"), algo_params )
    duration = Time.now - t
    ds_result = OpenTox::Dataset.find(result_uri)
    ds_result_nr_de = ds_result.data_entries.size
    ds_result_nr_com = ds_result.compounds.size
    ds_result_nr_f = ds_result.features.size
    
    puts
    puts "[#{Time.now.iso8601(4).to_s}] Bbrc result: #{result_uri}"
    puts "[#{Time.now.iso8601(4).to_s}] nr dataentries: #{ds_result_nr_de} , (of #{ds_nr_de} ), #{(ds_result_nr_de/(ds_nr_de/100)).to_f.round}%"
    puts "[#{Time.now.iso8601(4).to_s}] nr compounds: #{ds_result_nr_com} , (of #{ds_nr_com} ), #{(ds_result_nr_com/(ds_nr_com/100)).to_f.round}%"
    puts "[#{Time.now.iso8601(4).to_s}] nr features: #{ds_result_nr_f}, , #{(ds_result_nr_f/(ds_nr_de/100)).to_f.round}%"
    puts "[#{Time.now.iso8601(4).to_s}] Duration: #{duration}"
    puts "------------------------"
    puts
  end
  puts
end
