require 'rubygems'
require 'opentox-ruby-api-wrapper'
require 'test/unit'
require 'validate-owl'

class FeatureTest < Test::Unit::TestCase

  def setup
    @features = [
      "http://localhost/dataset/1/feature/Hamster%20Carcinogenicity",
      "http://apps.ideaconsult.net:8080/ambit2/feature/35796"
    ]
  end

  def test_feature
    
    @features.each do |uri|
      
      f = OpenTox::Feature.new(uri)
      f.load_metadata
      assert_not_nil f.metadata[DC.title]
      assert_not_nil f.metadata[OT.hasSource]
    end
  end

  def test_owl
    #@features.each do |uri|
      validate_owl @features.first
      # Ambit does not validate
    #end
  end


end
