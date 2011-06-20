require 'rubygems'
require 'opentox-ruby'
require 'test/unit'
require 'validate-owl.rb'

class FminerTest < Test::Unit::TestCase

  def setup
    @dump_dir = FileUtils.mkdir_p File.join(File.dirname(__FILE__),"dump",File.basename(__FILE__,".rb"))
    FileUtils.mkdir_p File.join(File.dirname(__FILE__),"reference",File.basename(__FILE__,".rb"))
  end

  def cleanup # executed only when assertions succeed (teardown is called even when assertions fail)
    FileUtils.cp @dumpfile, @dumpfile.sub(/dump/,"reference")
    FileUtils.rm @dumpfile
    @dataset.delete(@@subjectid)
  end

  def dump
    @dataset = OpenTox::Dataset.find @dataset_uri, @@subjectid
    @dumpfile = File.join(@dump_dir,caller[0][/`.*'/][1..-2])+".yaml"
    File.open(@dumpfile,"w+"){|f| f.puts @dataset.to_yaml}
  end

  def test_bbrc
    feature = @@classification_training_dataset.features.keys.first
    @dataset_uri = OpenTox::Algorithm::Fminer::BBRC.new.run({:dataset_uri => @@classification_training_dataset.uri, :prediction_feature => feature, :subjectid => @@subjectid}).to_s
    dump 
    assert_equal 52, @dataset.features.size
    cleanup
  end

  def test_regression_bbrc
    feature = File.join @@regression_training_dataset.uri,"feature/LC50_mmol" 
    @dataset_uri = OpenTox::Algorithm::Fminer::BBRC.new.run({:dataset_uri => @@regression_training_dataset.uri, :prediction_feature => feature, :subjectid => @@subjectid, :feature_type=>"paths"}).to_s
    dump
    assert_equal 219, @dataset.features.size
    cleanup
  end

  def test_last
    feature = @@classification_training_dataset.features.keys.first
    @dataset_uri = OpenTox::Algorithm::Fminer::LAST.new.run({:dataset_uri => @@classification_training_dataset.uri, :prediction_feature => feature, :subjectid => @@subjectid}).to_s
    dump
    assert_equal 23, @dataset.features.size
    cleanup
  end

  def test_bbrc_rest_parameters
    feature = @@classification_training_dataset.features.keys.first
    @dataset_uri = OpenTox::RestClientWrapper.post(File.join(CONFIG[:services]["opentox-algorithm"],"fminer","bbrc"),{
      "dataset_uri" => @@classification_training_dataset.uri,
      "prediction_feature" => feature,
      "backbone" => true,
      "min_frequency" => 2,
       :subjectid => @@subjectid })
    dump
    assert_equal 52, @dataset.features.size
    cleanup
  end

# Deactivated by AM because of efficiency problems (does not return)
#  def test_regression_last
#    feature = File.join @@regression_training_dataset.uri,"feature/LC50_mmol" 
#    @dataset_uri = OpenTox::Algorithm::Fminer::LAST.new.run({:dataset_uri => @@regression_training_dataset.uri, :prediction_feature => feature, :subjectid => @@subjectid}).to_s
#    dump
#    assert_equal 4, d.features.size
#    cleanup
#  end

end
