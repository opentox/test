require 'rubygems'
require 'opentox-ruby'
require 'yaml'

@subjectid = nil

@subjectid = nil

if ARGV.size != 1
  puts "Args: path/to/dataset.yaml"
  puts ARGV.size
  exit
end

@dataset = []

def create_f_ds(t_ds_uri, f_ds_uri, del)

  start_time = Time.new
  regression_training_dataset = OpenTox::Dataset.find(t_ds_uri, @subjectid)
  prediction_feature = regression_training_dataset.features.keys.first
  regression_feature_dataset = OpenTox::Dataset.find(f_ds_uri, @subjectid)

  params = {} 
  params[:dataset_uri] = regression_training_dataset.uri
  params[:prediction_feature_uri] = prediction_feature
  params[:feature_dataset_uri] = regression_feature_dataset.uri
  params[:del_missing] = del
  puts params.to_yaml
  feature_selection_algo_uri = File.join(CONFIG[:services]["opentox-algorithm"],"feature_selection/rfe")
  puts feature_selection_algo_uri
  puts "--- Feature dataset is: ---"

  result = OpenTox::RestClientWrapper.post( feature_selection_algo_uri, params)
  puts result
  stop_time = Time.new
  puts "Duration: #{stop_time - start_time}"
  puts
  result
end


path = ARGV[0]
puts path
ds = YAML::load_file("#{path}")

#ds.keys.each { |dataset|
["LOAEL"].each { |dataset|
  puts "----------------- next dataset -----------------"
  @dataset << "\"#{dataset}\": {" 
  ds[dataset].keys.each { |pc|
    if !((pc == "dataset") || (pc == "test") || (pc == "training") || (pc == "hybrid"))
      puts pc
      #[false, true].each { |del_missing| 
      [false].each { |del_missing| #false is default 
        begin
          result = create_f_ds(ds[dataset]["dataset"], ds[dataset][pc], del_missing) 
          @dataset << "  \"#{pc}\": \"#{result}\"," 
        rescue
        end
      }
    else
      @dataset << "  \"#{pc}\": \"#{ds[dataset][pc]}\"," 

    end
    puts "-----------------" unless pc == "dataset"
  }
  @dataset << "}," 
}

puts @dataset

