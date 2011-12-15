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

  def test_p_sum_support
    params = {}
    params[:compound_features_hits] = { "c:c" => 10, "c:c:c" => 5, "O:N" => 2}
    params[:training_compound] = "http://localhost/compound/InChI=1S/CH2O/c1-2/h1H2"
    params[:training_compound_features_hits] = {"c:c" => 6, "c:c:c" => 3, "O:O" => 2}
    params[:weights] = { "c:c" => 0.95, "c:c:c" => 0.96, "O:N" => 0.97, "O:O" => 0.98}
    params[:features] = (params[:compound_features_hits].keys + params[:training_compound_features_hits].keys).uniq
    2.times{
      params[:mode] = "min"
      assert_in_delta OpenTox::Algorithm.p_sum_support(params), 12.48, 0.001
      params[:mode] = "max"
      assert_in_delta OpenTox::Algorithm.p_sum_support(params), 18,2, 0.001
    }
  end
  
  def test_tanimoto
    params = {}
    params[:training_compound] = "http://localhost/compound/InChI=1S/CH2O/c1-2/h1H2"
    weights = { "c:c" => 0.9, "c:c:c" => 0.96, "O:N" => 0.97, "O:O" => 0.98}
    params[:compound_features_hits] = { "c:c" => 10, "c:c:c" => 5, "O:N" => 2}
    features_a = params[:compound_features_hits].keys
    params[:training_compound_features_hits] = {"c:c" => 6, "c:c:c" => 3, "O:O" => 2}
    features_b = params[:training_compound_features_hits].keys
    2.times{
      params[:nr_hits] = false 
      #test without weights
      assert_in_delta OpenTox::Algorithm::Similarity.tanimoto(features_a, features_b, nil, params), 0.5, 0.0001
      
      #test with weights
      assert_in_delta OpenTox::Algorithm::Similarity.tanimoto(features_a, features_b, weights, params), 0.488188976377953, 0.0001

      #test with weights and nr_hits true
      params[:nr_hits] = true
      assert_in_delta OpenTox::Algorithm::Similarity.tanimoto(features_a, features_b, weights, params), 0.467796610169492, 0.0001  
    }

    params[:training_compound_features_hits] = {"c:c" => 2, "O:N" => 2}
    features_c = params[:training_compound_features_hits].keys

    2.times{
      params[:nr_hits] = false
      #test without weights
      assert_in_delta OpenTox::Algorithm::Similarity.tanimoto(features_a, features_c, nil, params), 0.666666666666667, 0.0001
      #test with weights
      assert_in_delta OpenTox::Algorithm::Similarity.tanimoto(features_a, features_c, weights, params), 0.660777385159011, 0.0001

      #test with weights and nr_hits true
      params[:nr_hits] = true
      assert_in_delta OpenTox::Algorithm::Similarity.tanimoto(features_a, features_c, weights, params), 0.237611181702668, 0.0001
    }
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
