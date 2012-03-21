require 'rubygems'
require 'opentox-ruby'
require 'yaml'

@subjectid = nil

if ARGV.size != 1
  puts "Args: path/to/dataset.yaml"
  puts ARGV.size
  exit
end

def count_features(ds_uri)
  puts ds_uri

  dataset = OpenTox::Dataset.find(ds_uri, @subjectid)

  features = dataset.features.keys
  puts "# all features: #{features.size}"
  feature_names = []
  delete_features = []
  features.each{ |fn|
    feature_names << fn.split("\/feature\/").last
    dataset.features[fn][RDF.type].each { |typestr|
      if typestr.include? "MissingFeature"
        delete_features << fn 
        @missing_features << dataset.features[fn][DC.title]
      end
    }
  }
  @all_feature_names << feature_names.sort
  @all_feature_names << "" 

  puts "# Missingfeatures: #{delete_features.size}"
  features = features - delete_features
  puts "# numeric features: #{features.size}"
  puts "-----"
end


@missing_features = []
@all_feature_names = []
path = ARGV[0]
puts path
ds = YAML::load_file("#{path}")
#ds = YAML::load_file("../datasets.yaml")
ds.keys.each { |dataset|
  puts "----------"
  puts dataset
  @all_feature_names << "" 
  @all_feature_names << "------ new dataset ------" 
  @all_feature_names << "-------- #{dataset} --------"
  ds[dataset].keys.each { |pc|
    if !(pc == "dataset") || (pc == "test") || (pc == "training")
      puts pc
      @all_feature_names << "--- new feature: #{pc} ---" 
      count_features(ds[dataset][pc])
    end
  }
  puts "----------"
  puts
}
puts
puts "Missing features over all datasets:"
puts @missing_features.uniq!.to_yaml
puts 
puts "All feature names:"
puts @all_feature_names
