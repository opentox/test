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
    assert_equal 41, @dataset.features.size # 32 bit
    #assert_equal 52, @dataset.features.size
    cleanup
  end

  def test_regression_bbrc
    feature = File.join @@regression_training_dataset.uri,"feature/LC50_mmol" 
    @dataset_uri = OpenTox::Algorithm::Fminer::BBRC.new.run({:dataset_uri => @@regression_training_dataset.uri, :prediction_feature => feature, :subjectid => @@subjectid, :feature_type=>"paths"}).to_s
    dump
    assert_equal 207, @dataset.features.size # 32 bit
    #assert_equal 219, @dataset.features.size
    cleanup
  end

  def test_last
    feature = @@classification_training_dataset.features.keys.first
    @dataset_uri = OpenTox::Algorithm::Fminer::LAST.new.run({:dataset_uri => @@classification_training_dataset.uri, :prediction_feature => feature, :subjectid => @@subjectid}).to_s
    dump
    #assert_equal 23, @dataset.features.size
    assert_equal 21, @dataset.features.size # 32 bit
    cleanup
  end

  def test_bbrc_rest_parameters
    feature = @@classification_training_dataset.features.keys.first
    @dataset_uri = OpenTox::RestClientWrapper.post(File.join(CONFIG[:services]["opentox-algorithm"],"fminer","bbrc"),{
      "dataset_uri" => @@classification_training_dataset.uri,
      "prediction_feature" => feature,
      "backbone" => true,
      "min_frequency" => 2,
      "nr_hits" => true,
       :subjectid => @@subjectid })
    dump
    assert_equal 41, @dataset.features.size # 32 bit
    #assert_equal 52, @dataset.features.size
    @dataset.data_entries.each { |c,e|
      if c.to_s.scan('InChI=1S/C14H19N3S.ClH/c1-16(2)9-10-17(12-13-6-5-11-18-13)14-7-3-4-8-15-14;/h3-8,11H,9-10,12H2,1-2H3;1H').size > 0
        e.each { |p,h|
          if p.to_s.scan('39').size>0
            assert_equal 6, h[0]
          end
          if p.to_s.scan('18').size>0
            assert_equal 5, h[0]
          end
          if p.to_s.scan('38').size>0
            assert_equal 14, h[0]
          end
        }
      end
    }
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
