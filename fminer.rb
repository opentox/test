require 'rubygems'
require 'opentox-ruby'
require 'test/unit'
require 'validate-owl.rb'

class FminerTest < Test::Unit::TestCase

  def test_bbrc
    feature = @@classification_training_dataset.features.keys.first
    dataset_uri = OpenTox::Algorithm::Fminer::BBRC.new.run({:dataset_uri => @@classification_training_dataset.uri, :prediction_feature => feature, :subjectid => @@subjectid}).to_s
    d =OpenTox::Dataset.new dataset_uri, @@subjectid
    d.load_features(@@subjectid)
    assert_equal 52, d.features.size
    d.delete(@@subjectid)
  end

  def test_regression_bbrc
    feature = File.join @@regression_training_dataset.uri,"feature/LC50_mmol" 
    dataset_uri = OpenTox::Algorithm::Fminer::BBRC.new.run({:dataset_uri => @@regression_training_dataset.uri, :prediction_feature => feature, :subjectid => @@subjectid, :feature_type=>"paths"}).to_s
    d =OpenTox::Dataset.new dataset_uri, @@subjectid
    d.load_features(@@subjectid)
    #assert_equal 185, d.features.size
    assert_equal 219, d.features.size
    d.delete(@@subjectid)
  end

  def test_last
    feature = @@classification_training_dataset.features.keys.first
    dataset_uri = OpenTox::Algorithm::Fminer::LAST.new.run({:dataset_uri => @@classification_training_dataset.uri, :prediction_feature => feature, :subjectid => @@subjectid}).to_s
    d =OpenTox::Dataset.new dataset_uri, @@subjectid
    d.load_features(@@subjectid)
    assert_equal 23, d.features.size
    d.delete(@@subjectid)
  end

  def test_bbrc_rest_parameters
    feature = @@classification_training_dataset.features.keys.first
    #call = "curl -X POST #{File.join CONFIG[:services]["opentox-algorithm"],"fminer","bbrc"} -d \"dataset_uri=#{CGI.escape @@classification_training_dataset.uri}\" -d \"prediction_feature=#{CGI.escape feature}\" -d \"backbone=true\" -d \"min_frequency=2\""
    dataset_uri = OpenTox::RestClientWrapper.post(File.join(CONFIG[:services]["opentox-algorithm"],"fminer","bbrc"),{
      "dataset_uri" => @@classification_training_dataset.uri,
      "prediction_feature" => feature,
      "backbone" => true,
      "min_frequency" => 2,
       :subjectid => @@subjectid })
    d =OpenTox::Dataset.new dataset_uri, @@subjectid
    d.load_features(@@subjectid)
    assert_equal 52, d.features.size

  end

# Deactivated by AM because of efficiency problems (does not return)
#  def test_regression_last
#    feature = File.join @@regression_training_dataset.uri,"feature/LC50_mmol" 
#    dataset_uri = OpenTox::Algorithm::Fminer::LAST.new.run({:dataset_uri => @@regression_training_dataset.uri, :prediction_feature => feature, :subjectid => @@subjectid}).to_s
#    d =OpenTox::Dataset.new dataset_uri, @@subjectid
#    d.load_features(@@subjectid)
#    assert_equal 4, d.features.size
#    d.delete(@@subjectid)
#  end

end
