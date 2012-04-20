require 'rubygems'
require 'opentox-ruby'
require 'test/unit'
require 'validate-owl'
require 'test-util'

class DatasetTest < Test::Unit::TestCase
  include TestUtil
  
  def setup
    @datasets = {
      @@regression_training_dataset.uri => nil,
      @@classification_training_dataset.uri => {
        :nr_compounds => 85,
        :nr_features => 1,
        :nr_dataset_features => 1,
        :nr_data_entries => 85
      },
      "http://apps.ideaconsult.net:8080/ambit2/dataset/2698" => {
        :nr_compounds => 3,
        :nr_features => 8,
        :nr_dataset_features => 36,
        :nr_data_entries => 3
      }
    }
  end

  def teardown
    #@new_dataset.delete
  end

  def test_save_external

    @dataset = OpenTox::Dataset.find "http://apps.ideaconsult.net:8080/ambit2/dataset/2698"
    #File.open("test.rdf","w+"){|f| f.puts @dataset.to_rdfxml}
    @dataset.uri = "http://apps.ideaconsult.net:8080/ambit2/dataset" 
    uri = @dataset.save(@@subjectid)
    #@dataset.load_csv(File.open("data/hamster_carcinogenicity.csv").read)
    #@dataset.save
  end

  def test_create
    dataset = OpenTox::Dataset.create(CONFIG[:services]["opentox-dataset"], @@subjectid)
    dataset.save(@@subjectid)
    assert_kind_of URI::HTTP, URI.parse(dataset.uri)
    #dataset.delete(@@subjectid)
  end

  def test_all
    datasets = OpenTox::Dataset.all(CONFIG[:services]["opentox-dataset"], @@subjectid)
    assert_kind_of Array, datasets
  end

  def test_owl
    validate_owl @@classification_training_dataset.uri
    validate_owl @@regression_training_dataset.uri
    # ambit datasets do ot validate
    #@datasets.keys.each {|d| validate_owl d }
  end

  def test_from_yaml
    @dataset = OpenTox::Dataset.new
    @dataset.load_yaml(File.open("data/hamster_carcinogenicity.yaml").read)
    hamster_carc?
  end

  def test_sdf_with_multiple_features
    uri = OpenTox::RestClientWrapper.post(CONFIG[:services]["opentox-dataset"], File.read("data/CPDBAS_v5c_1547_29Apr2008part.sdf") ,{:accept => "text/uri-list",:content_type => "chemical/x-mdl-sdfile", :subjectid => @@subjectid}).to_s.chomp
    assert_kind_of URI::HTTP, URI.parse(uri)
  end

  def test_rest_csv
    uri = OpenTox::RestClientWrapper.post(CONFIG[:services]["opentox-dataset"], {:file => File.new("data/hamster_carcinogenicity.csv")} ,{:accept => "text/uri-list", :subjectid => @@subjectid}).to_s.chomp
    @dataset = OpenTox::Dataset.new uri, @@subjectid
    #@dataset = OpenTox::Dataset.new uri
    @dataset.load_all @@subjectid
    hamster_carc?
  end

  def test_multicolumn_csv
    uri = OpenTox::RestClientWrapper.post(CONFIG[:services]["opentox-dataset"], {:file => File.new("data/multicolumn.csv")},{:accept => "text/uri-list", :subjectid => @@subjectid}).to_s.chomp
    @dataset = OpenTox::Dataset.new uri, @@subjectid
    #@dataset = OpenTox::Dataset.new uri
    @dataset.load_all @@subjectid
    assert_equal 5, @dataset.features.size
    assert_equal 4, @dataset.compounds.size
    
  end

  def test_from_csv
    @dataset = OpenTox::Dataset.new
    @dataset.load_csv(File.open("data/hamster_carcinogenicity.csv").read, @@subjectid)
    #puts @dataset.to_yaml
    hamster_carc?
    @dataset.delete(@@subjectid)
  end

  def test_from_excel
    @dataset = OpenTox::Dataset.new
    @dataset.load_spreadsheet(Excel.new("data/hamster_carcinogenicity.xls"), @@subjectid)
    hamster_carc?
    @dataset.delete(@@subjectid)
  end

  def test_load_metadata
    @datasets.each do |uri,data|
      @dataset = OpenTox::Dataset.find(uri, @@subjectid)
      assert @dataset.metadata.size != 0
    end
  end

  def test_load_compounds
    @datasets.each do |uri,data|
      @dataset = OpenTox::Dataset.new(uri)
      @dataset.load_compounds @@subjectid
      assert_equal @dataset.compounds.size,data[:nr_compounds] if data
    end
  end

  def test_load_features
    @datasets.each do |uri,data|
      @dataset = OpenTox::Dataset.new(uri)
      @dataset.load_features @@subjectid
      assert_equal @dataset.features.keys.size,data[:nr_dataset_features] if data
    end
  end

  def test_load_all
    @datasets.each do |uri,data|
      @dataset = OpenTox::Dataset.new(uri)
      @dataset.load_all @@subjectid
      validate data
    end
  end

  def test_yaml
    @datasets.each do |uri,data|
      @dataset = OpenTox::Dataset.new(uri)
      @dataset.load_all @@subjectid
      #@dataset = YAML.load @dataset.to_yaml
      validate data
    end
  end

  def test_sdf
    @datasets.each do |uri,data|
      @dataset = OpenTox::Dataset.new(uri)
      @dataset.load_all @@subjectid
      sdf = @dataset.to_sdf
      size = sdf.lines.to_a.select{|i| i == "$$$$\n"}.size
      assert_equal size, data[:nr_compounds]  if data
    end
  end

  def test_csv
    @datasets.each do |uri,data|
      @dataset = OpenTox::Dataset.new(uri)
      @dataset.load_all @@subjectid
      csv = @dataset.to_csv.split("\n")
      assert_equal csv.size, data[:nr_compounds]+1  if data
      assert_equal csv.first.split(",").size, data[:nr_dataset_features]+1 if data
    end
  end

  def test_excel
    @datasets.each do |uri,data|
      @dataset = OpenTox::Dataset.new(uri)
      @dataset.load_all @@subjectid
      book =  @dataset.to_spreadsheet
      assert_kind_of Spreadsheet::Workbook, book
      #File.open("#{@dataset.id}.xls","w+"){|f| book.write f.path}
    end
  end

  def test_ntriples
    @datasets.each do |uri,data|
      @dataset = OpenTox::Dataset.new(uri)
      @dataset.load_all @@subjectid
      assert_kind_of String, @dataset.to_ntriples
    end
  end

  def test_owl
    @datasets.each do |uri,data|
      @dataset = OpenTox::Dataset.new(uri)
      @dataset.load_all @@subjectid
      assert_kind_of String, @dataset.to_rdfxml
    end
  end
  
  def test_rdf_conversion
    @datasets.each do |uri,data|
      #puts "dataset "+uri.to_s
      @dataset = OpenTox::Dataset.new(uri)
      @dataset.load_all @@subjectid
      
      #puts @dataset.features.keys.size.to_s+" # features"
      #puts "download to rdf"
      f = Tempfile.new("ot-rdf") 
      f.puts @dataset.to_rdfxml
      f.close
      
      #puts "upload as rdf"
      d = OpenTox::Dataset.create(CONFIG[:services]["opentox-dataset"], @@subjectid)
      d.load_rdfxml_file(f)
      f.delete
      d.save(@@subjectid)
      assert d.uri.uri?
      
      #puts "compare"
      dataset_equal(@dataset,d)
      
      #puts "download new dataset as yaml"
      d2 = OpenTox::Dataset.new(d.uri)
      d2.load_all @@subjectid
      
      #puts "compare again"
      dataset_equal(@dataset,d2)
    end
  end
  
 
  def test_merge()
    #upload
    dataset1 = OpenTox::Dataset.create_from_csv_file(File.new("data/hamster_carcinogenicity.csv").path, @@subjectid)
    dataset2 = OpenTox::Dataset.create_from_csv_file(File.new("data/multi_cell_call.csv").path, @@subjectid)
    #merge1
    title = "test merge"
    dataset_merge1 = OpenTox::Dataset.merge(dataset1, dataset2, { DC.title => title,DC.creator => "testsuite"}, @@subjectid )
    dataset_reloaded1 = OpenTox::Dataset.find(dataset_merge1.uri, @@subjectid)
    #test1
    [dataset_merge1, dataset_reloaded1].each do |d|
      assert_equal d.metadata[DC.title],title
      assert_equal d.features.size,(dataset1.features.size+dataset2.features.size)
      assert_equal d.compounds.size,(dataset1.compounds+dataset2.compounds).uniq.size
      [dataset1, dataset2].each do |d_i|
        d_i.compounds.each{|c| assert d.compounds.include?(c)}
        d_i.features.keys.each{|f| assert d.features.keys.include?(f)}
        d_i.features.keys.each do |f|
          assert_equal d_i.features[f],d.features[f]
          d_i.compounds do |c|
            assert_equal d_i.data_entries[c][f],d.data_entries[c][f]
          end
        end  
      end
    end
    #merge2
    compounds1 = dataset1.compounds[0..dataset1.compounds.size/2]
    features1 = []
    dataset_merge2 = OpenTox::Dataset.merge(dataset1, dataset2, {}, @@subjectid, features1, nil, compounds1 )
    dataset_reloaded2 = OpenTox::Dataset.find(dataset_merge2.uri, @@subjectid)
    #test2
    [dataset_merge2, dataset_reloaded2].each do |d|
      assert_equal d.features.size,dataset2.features.size
      assert_equal d.compounds.size,(compounds1+dataset2.compounds).uniq.size
    end
    #cleanup
    [dataset_merge1, dataset_merge2, dataset1, dataset2].each do |d|
      OpenTox::RestClientWrapper.delete(d.uri,{:subjectid => @@subjectid})
    end
  end
  
  def test_multithreading
    dataset = OpenTox::Dataset.find(@datasets.keys[0],@@subjectid)
    assert dataset!=nil && dataset.compounds.size>0 && dataset.features.size > 0
    uris = []
    
    num = 20
    num.times do |i|
      Thread.new do
        d = OpenTox::Dataset.new
        dataset.compounds.each do |c|
          d.add_compound c
        end
        dataset.features.each do |f,m|
          d.add_feature f,m
        end
        dataset.compounds.each do |c|
          dataset.features.keys.each do |f|
            dataset.add c,f,rand
          end
        end
        d.save @@subjectid
        uris << d.uri
      end
    end
    
    sleep 1 while (uris.size < num)
    uris.uniq.each{|uri| OpenTox::RestClientWrapper.delete(uri,{:subjectid=>@@subjectid})}
    #puts uris.sort.to_yaml
    assert_equal uris.size,uris.uniq.size
  end

  def validate(data)
    assert_kind_of OpenTox::Dataset, @dataset
    assert_equal @dataset.data_entries.size, data[:nr_data_entries] if data
    assert_equal @dataset.compounds.size, data[:nr_compounds] if data
    assert_equal @dataset.features.size, data[:nr_dataset_features] if data
    assert_equal @dataset.uri, @dataset.metadata[XSD.anyURI]
  end

  def hamster_carc?
    assert_kind_of OpenTox::Dataset, @dataset
    assert_equal 85, @dataset.data_entries.size
    assert_equal 85, @dataset.compounds.size
    assert_equal @dataset.uri, @dataset.metadata[XSD.anyURI]
  end
end
