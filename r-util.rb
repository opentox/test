require 'rubygems'
require 'opentox-ruby'
require 'test/unit'
require 'validate-owl'
require 'test-util'

DELETE = true

class RUtilTest < Test::Unit::TestCase
  include TestUtil

  def global_setup
    unless defined?(@@subjectid) 
      @@subjectid = OpenTox::Authorization.authenticate("guest","guest")
      @@signout = true
    end 
    @@rutil = OpenTox::RUtil.new
    @@hamster = OpenTox::Dataset.create_from_csv_file(File.new("data/hamster_carcinogenicity.csv").path, @@subjectid)
    pred_feature = @@hamster.features.keys[0]
    fminer = File.join(CONFIG[:services]["opentox-algorithm"],"fminer/bbrc")
    hamster_features_uri = OpenTox::RestClientWrapper.post(fminer,
      {:dataset_uri=>@@hamster.uri,:prediction_feature=>pred_feature,:subjectid=>@@subjectid}).to_s
    @@hamster_features = OpenTox::Dataset.find(hamster_features_uri,@@subjectid)
    @@resources = [@@hamster.uri, hamster_features_uri]
  end

  def global_teardown
    @@rutil.quit_r
    if DELETE
      @@resources.each do |uri|
        OpenTox::RestClientWrapper.delete(uri,{:subjectid=>@@subjectid})
      end
    else
      puts "Resources "+@@resources.to_yaml
    end
    OpenTox::Authorization.logout(@@subjectid) if defined?(@@signout)
  end
  
  def pre_files(files)
    files.each{|f| File.delete(f) if File.exist?(f)}
  end
  
  def post_files(files)
    files.each{|f| assert File.exist?(f)}
    if DELETE
      files.each{|f| File.delete(f) if File.exist?(f)}
    else
      puts "Plotted to "+files.to_yaml
    end
  end

  def test_paired_ttest
    puts "ttest"
    x = Array.new(1000,0).collect{|e| rand()}
    y = Array.new(1000,0).collect{|e| rand()}
    res = @@rutil.paired_ttest(x,y)
    puts "x >> y ? #{res}"
    assert_equal res,0
    y = Array.new(1000,0).collect{|e| rand()-0.1}
    res = @@rutil.paired_ttest(x,y)
    puts "x >> y ? #{res}"
    assert res>0
  end
  
  def test_boxplot
    puts "boxplot"
    files = ["/tmp/box.svg","/tmp/box.png"]
    pre_files(files)
    data = [ 
      [ :method, [4,4,5,5,4,3,2] ],
      [ :method2, [1,2,3,4,5,4,6] ], 
      [ :asdf, [9,1,8,0,7,1,6] ] ]
    @@rutil.boxplot(files, data, "comparison1" )
    post_files(files)
  end
  
  def test_double_hist_plot
    puts "double_hist_plot"
    hist_num_log = "/tmp/hist_num_log.svg"
    hist_num = "/tmp/hist_num.svg"
    hist_cat = "/tmp/hist_cat.svg"
    pre_files [hist_num_log,hist_num,hist_cat]
    data1 = Array.new(1000,0).collect{|x| rand()*rand()}
    data2 = Array.new(1000,0).collect{|x| rand()*rand()*rand()}
    @@rutil.double_hist_plot([hist_num_log], data1, data2, true, true )
    @@rutil.double_hist_plot([hist_num], data1, data2, true, false )
    data1 = "a,a,a,a,b,b,b,b,b,b,b,b,b,b,c,c,c".split(",")
    data2 = "a,a,a,a,a,a,b,b,b,b,b,b,c,c,c,c,c,d,d,d,d,d".split(",")
    @@rutil.double_hist_plot([hist_cat], data1, data2, false )
    post_files [hist_num_log,hist_num,hist_cat]
  end

  def test_dataset_to_dataframe
    puts "dataset_to_dataframe"
    dataframe = @@rutil.dataset_to_dataframe(@@hamster,"NA",@@subjectid)
    dataset_conv = @@rutil.dataframe_to_dataset(dataframe,@@subjectid)
    dataset_conv_reloaded = OpenTox::Dataset.find(dataset_conv.uri,@@subjectid)
    @@resources << dataset_conv.uri
    dataset_equal(@@hamster,dataset_conv)
    dataset_equal(@@hamster,dataset_conv_reloaded)
    
    feats = @@hamster_features.features.keys[0..(@@hamster_features.features.keys.size/2)]
    dataframe = @@rutil.dataset_to_dataframe(@@hamster_features,"NA",@@subjectid,feats)
    dataset_conv = @@rutil.dataframe_to_dataset(dataframe,@@subjectid)
    dataset_conv_reloaded = OpenTox::Dataset.find(dataset_conv.uri,@@subjectid)
    @@resources << dataset_conv.uri
    [dataset_conv, dataset_conv_reloaded].each do |d|
      assert_equal d.compounds.sort,@@hamster_features.compounds.sort
      assert_equal d.features.keys.sort,feats.sort
      d.compounds.each do |c|
        d.features.keys.each do |f|
          if @@hamster_features.data_entries[c]==nil || @@hamster_features.data_entries[c][f]==nil
            assert d.data_entries[c]==nil || d.data_entries[c][f]==nil
          else
            assert_not_nil d.data_entries[c]
            assert_equal @@hamster_features.data_entries[c][f],d.data_entries[c][f]
          end 
        end
      end
    end
    
    dataframe = @@rutil.dataset_to_dataframe(@@hamster_features,"NA",@@subjectid)
    @@rutil.r.eval "#{dataframe} <- #{dataframe}[2:10,10:20]"
    dataset_conv = @@rutil.dataframe_to_dataset(dataframe,@@subjectid)
    dataset_conv_reloaded = OpenTox::Dataset.find(dataset_conv.uri,@@subjectid)
    @@resources << dataset_conv.uri
    [dataset_conv,dataset_conv_reloaded].each do |d|
      assert_equal d.compounds.size,9
      d.compounds.size.times do |i| 
        assert_equal d.compounds[i],@@hamster_features.compounds[i+1]
      end
      assert_equal d.features.size,11
      d.compounds.each do |c|
        d.features.keys.each do |f|
          if @@hamster_features.data_entries[c]==nil || @@hamster_features.data_entries[c][f]==nil
            assert d.data_entries[c]==nil || d.data_entries[c][f]==nil
          else
            assert_not_nil d.data_entries[c]
            assert_equal @@hamster_features.data_entries[c][f],d.data_entries[c][f]
          end 
        end
      end
    end
  end

  def stratified_split
    unless defined?@@strat
      @@split_ratio = 0.05
      @@split_has_duplicates = false #hamster has no duplicates
#     res = @@rutil.stratified_split(@@hamster,0,@@split_ratio,1)
#     @@resources += [ res[0].uri, res[1].uri ]
#     @@strat = { :data => @@hamster, :split1 => res[0], :split2 => res[1] }
      data_combined = OpenTox::Dataset.merge(@@hamster,@@hamster_features,{},@@subjectid)
      res = @@rutil.stratified_split(data_combined,0,@@split_ratio,@@subjectid,1)
      @@resources += [ data_combined.uri, res[0].uri, res[1].uri ]
      @@strat = {:data => data_combined, :split1 => res[0], :split2 => res[1] }
    end
    @@strat
  end
       
  def test_stratified_split
    puts "test_stratified_split"
    split = stratified_split
    size = split[:data].compounds.size
    size1 = split[:split1].compounds.size
    size2 = split[:split2].compounds.size
    assert_equal size,(split[:split1].compounds+split[:split2].compounds).uniq.size
    unless @@split_has_duplicates
      assert_equal (@@split_ratio*size).round,size1,
        "Dataset #{size} should be split into #{(@@split_ratio*size).round}/#{size-(@@split_ratio*size).round}"+
        " (exact: #{@@split_ratio*size}), instead: #{size1}/#{size2}"
    end
    split[:data].compounds.each do |c|
      include1 = split[:split1].compounds.include?(c)
      include2 = split[:split2].compounds.include?(c)
      unless @@split_has_duplicates
        assert(((include1 and !include2) or (!include1 and include2)))
      else
        assert((include1 or include2))
      end
    end
  end

  def test_feature_value_plot
    puts "feature_value_plot"
    split = stratified_split
    data = split[:data]
    dataset1 = data.split( data.compounds[0..4], data.features.keys, {}, @@subjectid)
    dataset2 = data.split( data.compounds[5..-1], data.features.keys, {}, @@subjectid)
    @@resources += [dataset1.uri, dataset2.uri]
    files = []
    #plot
    [true,false].each do |fast_embedding|
      next if fast_embedding==false and !@@rutil.package_installed?("smacof")
      random_file = "/tmp/feature_value_plot_random_fast#{fast_embedding}.svg"
      stratified_file = "/tmp/feature_value_plot_stratified_fast#{fast_embedding}.svg"
      pre_files [random_file, stratified_file]
      @@rutil.feature_value_plot([random_file], dataset1.uri, dataset2.uri,
         "first five", "rest", nil, fast_embedding, @@subjectid)
      @@rutil.feature_value_plot([stratified_file], split[:split1].uri, split[:split2].uri,
          "five percent stratified", "rest", nil, fast_embedding, @@subjectid)
      files += [random_file, stratified_file]
    end
    #cleanup
    post_files files
  end  

  # hack to have a global_setup and global_teardown 
  def teardown
    if((@@expected_test_count-=1) == 0)
      global_teardown
    end
  end
  
  def setup
    unless defined?@@expected_test_count
      @@expected_test_count = (self.class.instance_methods.reject{|method| method[0..3] != 'test'}).length
      global_setup
    end
  end
  
end
