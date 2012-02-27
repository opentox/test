require 'rubygems'
require 'opentox-ruby'
require 'yaml'

@subjectid = nil



def count_features(ds_uri)
  puts ds_uri

  dataset = OpenTox::Dataset.find(ds_uri, @subjectid)

  features = dataset.features.keys
  puts "# all features: #{features.size}"
  
  delete_features = []
  features.each{ |fn|
    dataset.features[fn][RDF.type].each { |typestr|
      if typestr.include? "MissingFeature"
        delete_features << fn 
        @missing_features << dataset.features[fn][DC.title]
      end
    }
  }
  puts "# Missingfeatures: #{delete_features.size}"
  features = features - delete_features
  puts "# numeric features: #{features.size}"
  puts "-----"
end


@missing_features = []

ds = YAML::load_file("../datasets.yaml")
ds.keys.each { |dataset|
  puts "----------"
  puts dataset
  ds[dataset].keys.each { |pc|
    puts pc unless (pc == "dataset") || (pc == "test") || (pc == "training")
    count_features(ds[dataset][pc]) unless (pc == "dataset") || (pc == "test") || (pc == "training") 
  }
  puts "----------"
  puts
}
puts
puts "Missing features over all datasets:"
puts @missing_features.uniq!.to_yaml 
