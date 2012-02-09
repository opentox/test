require 'rubygems'
require 'opentox-ruby'
require 'test/unit'
require "./validate-owl.rb"

class AlgorithmTest < Test::Unit::TestCase

  def setup
   @@subjectid = OpenTox::Authorization.authenticate(TEST_USER,TEST_PW) 
    @algorithms = [
      File.join(CONFIG[:services]["opentox-algorithm"],"fminer","bbrc"),
      File.join(CONFIG[:services]["opentox-algorithm"],"fminer","last"),
      File.join(CONFIG[:services]["opentox-algorithm"],"lazar")
      #"http://apps.ideaconsult.net:8080/ambit2/algorithm/J48",
    ]
  end

  def teardown
  end

  def test_metadata
    @algorithms.each do |algorithm|
      validate_owl(algorithm, @@subjectid) unless CONFIG[:services]["opentox-algorithm"].match(/localhost/)
    end
  end

=begin
  def test_clustering
    # Parameters
    dataset_uri         = @@classification_training_dataset.uri
    query_compound      = OpenTox::Compound.from_smiles("O1COc2cc(ccc12)C")

    c = OpenTox::Algorithm::Similarity::StructuralClustering.new dataset_uri
    cluster_datasets = Array.new
    if c.trained? 
      c.get_clusters query_compound.uri 
      cluster_datasets = c.target_clusters_array
    end
    assert_equal cluster_datasets.size, 2

  end
=end
end
