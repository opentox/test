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
    assert_equal 185, d.features.size
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
