require 'rubygems'
require 'opentox-ruby'
require 'test/unit'
require 'validate-owl'

class FeatureTest < Test::Unit::TestCase

  def setup
    @features = [
      @@classification_training_dataset.features.keys.first,
      "http://apps.ideaconsult.net:8080/ambit2/feature/35796",
      File.join(OpenTox::Model::Lazar.all.last,"predicted","value")

    ]
  end

  def test_feature
    
    @features.each do |uri|
      
      puts uri
      f = OpenTox::Feature.new(uri)
      f.load_metadata(@@subjectid)
      assert_not_nil f.metadata[DC.title]
      #assert_not_nil f.metadata[OT.hasSource]
    end
  end

  def test_owl
    #@features.each do |uri|
      validate_owl @features.first, @@subjectid unless CONFIG[:services]["opentox-dataset"].match(/localhost/)
      validate_owl @features.last, @@subjectid unless CONFIG[:services]["opentox-dataset"].match(/localhost/)
      # Ambit does not validate
    #end
  end


end
