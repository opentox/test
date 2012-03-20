require 'rubygems'
require 'opentox-ruby'
require 'yaml'

@subjectid = nil



def create_f_ds(t_ds_uri, f_ds_uri, del)

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

  result = OpenTox::RestClientWrapper.post( feature_selection_algo_uri, params)
  puts "--- Feature dataset is: ---"
  puts result
  
  puts
end




ds = YAML::load_file("../datasets.yaml")
ds.keys.each { |dataset|
  puts "----------------- next dataset -----------------"
  ds[dataset].keys.each { |pc|
    puts pc unless pc == "dataset"
    [false, true].each { |del_missing|
      begin
        create_f_ds(ds[dataset]["dataset"], ds[dataset][pc], del_missing) unless pc == "dataset"
      rescue
      end
    }
    puts "-----------------" unless pc == "dataset"
  }
}
