require 'rubygems'
require 'opentox-ruby'
require 'test/unit'
require 'validate-owl.rb'

class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end
end

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
    @dataset_uri = OpenTox::Algorithm::Fminer::BBRC.new.run({:dataset_uri => @@classification_training_dataset.uri, :prediction_feature => feature, :min_frequency => "10pm", :subjectid => @@subjectid}).to_s
    dump 
    assert_equal 53, @dataset.features.size # 32 bit
    
    # assert no hit counts present
    count=0
    @dataset.data_entries.each { |c,e|
      if c.to_s.scan('InChI=1S/C10H13N3O2/c1-13(12-15)7-3-5-10(14)9-4-2-6-11-8-9/h2,4,6,8H,3,5,7H2,1H3').size > 0
        e.each { |p,h|
          if p.to_s.scan('bbrc/26').size>0
            count += 1 if h[0] == 1
          end
          if p.to_s.scan('bbrc/49').size>0
            count += 1 if h[0] == 1
          end
          if p.to_s.scan('bbrc/27').size>0
            count += 1 if h[0] == 1
          end
        }
      end
    }
    assert_equal 3, count

    # assert some values
    @dataset.features.each { |c,e|
      if c.to_s.scan('feature/bbrc/31').size > 0
        assert_equal e['http://www.opentox.org/api/1.1#effect'], 1
        assert_equal e['http://www.opentox.org/api/1.1#pValue'].to_f.round_to(2), 0.98
        assert_equal e['http://www.opentox.org/api/1.1#smarts'], "[#6&a]:[#6&a](-[#6&A]-[#6&A])(:[#6&a]:[#6&a])"
      end
    }
    cleanup
  end

  def test_regression_bbrc
    feature = File.join @@regression_training_dataset.uri,"feature/LC50_mmol" 
    @dataset_uri = OpenTox::Algorithm::Fminer::BBRC.new.run({:dataset_uri => @@regression_training_dataset.uri, :prediction_feature => feature, :min_frequency => "10pm", :subjectid => @@subjectid, :feature_type=>"paths"}).to_s
    dump
    assert_equal 90, @dataset.features.size # 32 bit
    
    # assert no hit counts present
    count = 0
    @dataset.data_entries.each { |c,e|
      if c.to_s.scan('InChI=1S/C5H4ClNO/c6-4-1-2-5(8)7-3-4/h1-3H,(H,7,8)').size > 0
        e.each { |p,h|
          if p.to_s.scan('bbrc/81').size>0
            count += 1 if h[0] == 1
          end
          if p.to_s.scan('bbrc/5').size>0
            count += 1 if h[0] == 1
          end
          if p.to_s.scan('bbrc/82').size>0
            count += 1 if h[0] == 1
          end
        }
      end
    }
    assert_equal 3, count

    # assert some values
    @dataset.features.each { |c,e|
      if c.to_s.scan('feature/bbrc/83').size > 0
        assert_equal e['http://www.opentox.org/api/1.1#effect'], "activating"
        assert_equal e['http://www.opentox.org/api/1.1#pValue'].to_f.round_to(2), 1.0
        assert_equal e['http://www.opentox.org/api/1.1#smarts'], "[#17&A]-[#6&a]:[#6&a]:[#6&a]:[#6&a]"
      end
    }

    cleanup
  end

  def test_last

    feature = @@classification_training_dataset.features.keys.first
    @dataset_uri = OpenTox::Algorithm::Fminer::LAST.new.run({:dataset_uri => @@classification_training_dataset.uri, :prediction_feature => feature, :min_frequency => "75pm", :subjectid => @@subjectid}).to_s
    dump
    assert_in_delta 21, @dataset.features.size, 2 # 32 bit

    # assert no hit counts present
    count = 0
    @dataset.data_entries.each { |c,e|
      if c.to_s.scan('InChI=1S/C5H10N2O/c8-6-7-4-2-1-3-5-7/h1-5H2').size > 0
        e.each { |p,h|
          if p.to_s.scan('last/21').size>0
            count += 1 if h[0] == 1
          end
          if p.to_s.scan('last/10').size>0
            count += 1 if h[0] == 1
          end
          if p.to_s.scan('last/13').size>0
            count += 1 if h[0] == 1
          end
        }
      end
    }
    assert_equal 3, count

    # assert some values
    @dataset.features.each { |c,e|
      if c.to_s.scan('feature/last/3').size > 0
        assert_equal e['http://www.opentox.org/api/1.1#effect'], 1 
        assert_equal e['http://www.opentox.org/api/1.1#pValue'].to_f.round_to(3), 0.995
        assert_equal e['http://www.opentox.org/api/1.1#smarts'], "[#8&A]=[#6&A]-[#6&A]-[#6&A]"
      end
    }
    cleanup
  end


def test_regression_last
  feature = File.join @@regression_training_dataset.uri,"feature/LC50_mmol" 
  @dataset_uri = OpenTox::Algorithm::Fminer::LAST.new.run({:dataset_uri => @@regression_training_dataset.uri, :prediction_feature => feature, :min_frequency => "40", :subjectid => @@subjectid}).to_s
  dump
  assert_in_delta 16, @dataset.features.size, 8 

  
  # assert no hit counts present
  count=0
  @dataset.data_entries.each { |c,e|
    if c.to_s.scan('InChI=1S/C9H10O3/c1-2-12-9-5-7(6-10)3-4-8(9)11/h3-6,11H,2H2,1H3').size > 0
      e.each { |p,h|
        if p.to_s.scan('last/2').size>0
          count += 1 if h[0] == 1
        end
        if p.to_s.scan('last/3').size>0
          count += 1 if h[0] == 1
        end
        if p.to_s.scan('last/8').size>0
          count += 1 if h[0] == 1
        end
      }
    end
  }
  assert_in_delta 3, count, 2

  # assert some values
  @dataset.features.each { |c,e|
    if c.to_s.scan('feature/last/3').size > 0
      assert_equal e['http://www.opentox.org/api/1.1#effect'], "deactivating"
      assert_equal e['http://www.opentox.org/api/1.1#pValue'].to_f.round_to(2), 0.99
      assert_equal e['http://www.opentox.org/api/1.1#smarts'], "[#6&A]-[#6&a](:[#6&a]):[#6&a]"
    end
  }
  cleanup
end



  def test_bbrc_rest_parameters_nr_hits
    feature = @@classification_training_dataset.features.keys.first
    @dataset_uri = OpenTox::RestClientWrapper.post(File.join(CONFIG[:services]["opentox-algorithm"],"fminer","bbrc"),{
      "dataset_uri" => @@classification_training_dataset.uri,
      "prediction_feature" => feature,
      "min_frequency" => "10pm",
      "nr_hits" => true,
       :subjectid => @@subjectid })
    dump
    assert_equal 53, @dataset.features.size # 32 bit

    # assert hit counts present
    @dataset.data_entries.each { |c,e|
      if c.to_s.scan('InChI=1S/C14H19N3S.ClH/c1-16(2)9-10-17(12-13-6-5-11-18-13)14-7-3-4-8-15-14;/h3-8,11H,9-10,12H2,1-2H3;1H').size > 0
        e.each { |p,h|
          if p.to_s.scan('bbrc/39').size>0
            assert_equal 6, h[0]
          end
          if p.to_s.scan('bbrc/18').size>0
            assert_equal 5, h[0]
          end
          if p.to_s.scan('bbrc/38').size>0
            assert_equal 14, h[0]
          end
        }
      end
    }

    # assert some values
    @dataset.features.each { |c,e|
      if c.to_s.scan('feature/bbrc/31').size > 0
        assert_equal e['http://www.opentox.org/api/1.1#effect'], 1
        assert_equal e['http://www.opentox.org/api/1.1#pValue'].to_f.round_to(2), 0.98
        assert_equal e['http://www.opentox.org/api/1.1#smarts'], "[#6&a]:[#6&a](-[#6&A]-[#6&A])(:[#6&a]:[#6&a])"
      end
    }

    cleanup
  end

  def test_bbrc_rest_parameters_bb_false
    feature = @@classification_training_dataset.features.keys.first
    @dataset_uri = OpenTox::RestClientWrapper.post(File.join(CONFIG[:services]["opentox-algorithm"],"fminer","bbrc"),{
      "dataset_uri" => @@classification_training_dataset.uri,
      "prediction_feature" => feature,
      "backbone" => false,
      "min_frequency" => "10pm",
       :subjectid => @@subjectid })
    dump
    assert_equal 195, @dataset.features.size # 32 bit

    # assert no hit counts present
    count=0
    @dataset.data_entries.each { |c,e|
      if c.to_s.scan('InChI=1S/C10H13N3O2/c1-13(12-15)7-3-5-10(14)9-4-2-6-11-8-9/h2,4,6,8H,3,5,7H2,1H3').size > 0
        e.each { |p,h|
          if p.to_s.scan('bbrc/167').size>0
            count += 1 if h[0] == 1
          end
          if p.to_s.scan('bbrc/134').size>0
            count += 1 if h[0] == 1
          end
          if p.to_s.scan('bbrc/112').size>0
            count += 1 if h[0] == 1
          end
        }
      end
    }
    assert_equal 3, count


    # assert some values
    @dataset.features.each { |c,e|
      if c.to_s.scan('feature/bbrc/183').size > 0
        assert_equal e['http://www.opentox.org/api/1.1#effect'], 1
        assert_equal e['http://www.opentox.org/api/1.1#pValue'].to_f.round_to(2), 0.98
        assert_equal e['http://www.opentox.org/api/1.1#smarts'], "[#7&A]-[#6&a](:[#6&a]:[#6&a])(:[#6&a]:[#6&a]:[#6&a])"
      end
    }

    cleanup
  end

  def test_bbrc_multinomial
    feature = @@multinomial_training_dataset.features.keys.first
    @dataset_uri = OpenTox::Algorithm::Fminer::BBRC.new.run({:dataset_uri => @@multinomial_training_dataset.uri, :prediction_feature => feature, :min_frequency => "10pm", :subjectid => @@subjectid}).to_s
    dump 
    assert_equal 152, @dataset.features.size # 32 bit

    #assert no hit counts present
    count=0
    @dataset.data_entries.each { |c,e|
      if c.to_s.scan('InChI=1S/C10H7NO2/c12-11(13)10-7-3-5-8-4-1-2-6-9(8)10/h1-7H').size > 0
        e.each { |p,h|
          if p.to_s.scan('bbrc/37').size>0
            count += 1 if h[0] == 1
          end
          if p.to_s.scan('bbrc/38').size>0
            count += 1 if h[0] == 1
          end
          if p.to_s.scan('bbrc/39').size>0
            count += 1 if h[0] == 1
          end
        }
      end
    }
    assert_equal 3, count

    # assert some values
    @dataset.features.each { |c,e|
      if c.to_s.scan('feature/bbrc/0').size > 0
        assert_equal e['http://www.opentox.org/api/1.1#effect'], 2
        assert_equal e['http://www.opentox.org/api/1.1#pValue'].to_f.round_to(2), 1.00
        assert_equal e['http://www.opentox.org/api/1.1#smarts'], "[#6&A]-[#6&A](=[#6&A])(-[#6&A])"
      end
    }
    @dataset.features.each { |c,e|
      if c.to_s.scan('feature/bbrc/92').size > 0
        assert_equal e['http://www.opentox.org/api/1.1#effect'], 1
        assert_equal e['http://www.opentox.org/api/1.1#pValue'].to_f.round_to(2), 0.99
        assert_equal e['http://www.opentox.org/api/1.1#smarts'], "[#7&A]-[#6&a](:[#6&a]:[#6&a]:[#6&a])(:[#6&a]:[#6&a]-[#16&A])"
      end
    }
    @dataset.features.each { |c,e|
      if c.to_s.scan('feature/bbrc/42').size > 0
        assert_equal e['http://www.opentox.org/api/1.1#effect'], 3
        assert_equal e['http://www.opentox.org/api/1.1#pValue'].to_f.round_to(2), 0.99
        assert_equal e['http://www.opentox.org/api/1.1#smarts'], "[#6&a]:[#6&a]:[#6&a]:[#6&a]:[#6&a]:[#7&a]:[#6&a]"
      end
    }
    cleanup
  end

  def test_last_multinomial
    feature = @@multinomial_training_dataset.features.keys.first
    @dataset_uri = OpenTox::Algorithm::Fminer::LAST.new.run({:dataset_uri => @@multinomial_training_dataset.uri, :prediction_feature => feature, :min_frequency => "75pm", :subjectid => @@subjectid}).to_s
    dump 
    assert_in_delta 138, @dataset.features.size, 2 # 32 bit

    #assert no hit counts present
    count=0
    @dataset.data_entries.each { |c,e|
      if c.to_s.scan('InChI=1S/C7H6N2O4/c8-6-3-4(9(12)13)1-2-5(6)7(10)11/h1-3H,8H2,(H,10,11)').size > 0
        e.each { |p,h|
          if p.to_s.scan('last/127').size>0
            count += 1 if h[0] == 1
          end
          if p.to_s.scan('last/54').size>0
            count += 1 if h[0] == 1
          end
          if p.to_s.scan('last/120').size>0
            count += 1 if h[0] == 1
          end
        }
      end
    }
    assert_equal 3, count

    # assert some values
    #@dataset.features.each { |c,e|
    #  if c.to_s.scan('feature/last/54').size > 0
    #    assert_equal e['http://www.opentox.org/api/1.1#effect'], 1
    #    assert_equal e['http://www.opentox.org/api/1.1#pValue'].to_f.round_to(2), 0.99
    #    assert_equal e['http://www.opentox.org/api/1.1#smarts'], "[#7&A;$([#7&A](=[#8&A])=[#8&A]),$([#7&A](-[#6&a])=[#8&A])](~*)=[#8&A]"
    #  end
    #}
    #@dataset.features.each { |c,e|
    #  if c.to_s.scan('feature/last/48').size > 0
    #    assert_equal e['http://www.opentox.org/api/1.1#effect'], 2
    #    assert_equal e['http://www.opentox.org/api/1.1#pValue'].to_f.round_to(2), 0.99
    #    assert_equal e['http://www.opentox.org/api/1.1#smarts'], "[#6&A]=[#6&A](-[#6&A])-[#6&A]"
    #  end
    #}
    #@dataset.features.each { |c,e|
    #  if c.to_s.scan('feature/bbrc/76').size > 0
    #    assert_equal e['http://www.opentox.org/api/1.1#effect'], "2"
    #    assert_equal e['http://www.opentox.org/api/1.1#pValue'].to_f.round_to(2), 0.0
    #    assert_equal e['http://www.opentox.org/api/1.1#smarts'], "[#7&A]-[#6&a]:[#6&a]:[#6&a](-[#16&A;$([#16&A](-,=[#8&A])-[#6&a]),$([#16&A](=[#8&A])-[#6&a])](~*)):[#6&a]:[#6&a;$([#6&a](:[#6&a])(:[#6&a]):[#6&a]),$([#6&a](:[#6&a])(:[#6&a]):[#6&a])](~*)(~*):[#6&a]:[#6&a]"
    #  end
    #}
    cleanup
  end
  
  def test_match
    feature = @@classification_training_dataset.features.keys.first
    feature_dataset_uri = OpenTox::Algorithm::Fminer::BBRC.new.run({
      :dataset_uri => @@classification_training_dataset.uri, :prediction_feature => feature, :min_frequency => "10pm", :subjectid => @@subjectid}).to_s
    feature_dataset = OpenTox::Dataset.find(feature_dataset_uri,@@subjectid)
    tmp_resources = [ feature_dataset_uri ]
    [true,false].each do |hits|
      matched_dataset_uri = OpenTox::RestClientWrapper.post(File.join(CONFIG[:services]["opentox-algorithm"],"fminer","bbrc","match"),{:feature_dataset_uri => feature_dataset_uri, :dataset_uri => @@classification_training_dataset.uri, :nr_hits => hits, :min_frequency => "10pm", :subjectid => @@subjectid})
        #{:feature_dataset_uri => feature_dataset_uri, :dataset_uri => @@multinomial_training_dataset.uri, :nr_hits => hits, :min_frequency => "10pm", :subjectid => @@subjectid}).to_s
      tmp_resources << matched_dataset_uri
      matched_dataset = OpenTox::Dataset.find(matched_dataset_uri,@@subjectid)
      # matched datset should have same compounds as input dataset for matching
      #assert_equal matched_dataset.compounds.sort,@@multinomial_training_dataset.compounds.sort
      assert_equal matched_dataset.compounds.sort,@@classification_training_dataset.compounds.sort
      # matched dataset should have same features as feature dataset
      matched_features = matched_dataset.features.keys.collect {|f| f.gsub("/match", "")}
      assert_equal feature_dataset.features.keys.sort,matched_features.sort
      matched_dataset.compounds.each do |c|
        matched_dataset.features.keys.each do |f|
          if matched_dataset.data_entries[c] and matched_dataset.data_entries[c][f]
            v = matched_dataset.data_entries[c][f]
            if hits
              assert_equal v.size,1
              assert v[0].is_a?(Integer)
              assert v[0]>0
            else
              assert_equal v,[1]
            end 
          end
        end
      end
    end
    tmp_resources.each{|uri| OpenTox::RestClientWrapper.delete(uri,{:subjectid=>@@subjectid})}
  end

  def test_match_pValue
    feature = @@classification_training_dataset.features.keys.first
    feature_dataset_uri = OpenTox::Algorithm::Fminer::BBRC.new.run({
      :dataset_uri => @@classification_training_dataset.uri, :prediction_feature => feature, :min_frequency => "10pm", :nr_hits => false, :subjectid => @@subjectid}).to_s
    feature_dataset = OpenTox::Dataset.find(feature_dataset_uri,@@subjectid)
    tmp_resources = [ feature_dataset_uri ]
    
    matched_dataset_uri = OpenTox::RestClientWrapper.post(File.join(CONFIG[:services]["opentox-algorithm"],"fminer","bbrc","match"),{:feature_dataset_uri => feature_dataset_uri, :dataset_uri => @@classification_training_dataset.uri, :nr_hits => false, :subjectid => @@subjectid})
    tmp_resources << matched_dataset_uri
    
    matched_dataset = OpenTox::Dataset.find(matched_dataset_uri,@@subjectid)
    matched_smarts_pValues = {}
    bbrc_smarts_pValues = {}
  
    feature_dataset.features.each do |f, values| 
      if values[RDF::type].include?(OT.Substructure)
        bbrc_smarts_pValues[values[OT::smarts]] =  values[OT::pValue]
      end
    end
    matched_dataset.features.each do |f, values| 
      if values[RDF::type].include?(OT.Substructure)
        matched_smarts_pValues[values[OT::smarts]] =  values[OT::pValue]
      end
    end
   
    # matched dataset has same features and p_values
    assert_equal matched_smarts_pValues.size,bbrc_smarts_pValues.size 
    if !matched_smarts_pValues.nil?
      bbrc_smarts_pValues.each do |s, p|
        assert matched_smarts_pValues.has_key?(s)
        assert_equal p.to_f.round_to(4),matched_smarts_pValues[s].to_f.round_to(4)
      end
    end  
   
    tmp_resources.each{|uri| OpenTox::RestClientWrapper.delete(uri,{:subjectid=>@@subjectid})}
  end

end
