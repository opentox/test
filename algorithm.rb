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
    params[:training_compound2] = "http://localhost/compound/InChI=1S/c1-2/h1H2"
    params[:fingerprints] = {}
    params[:fingerprints][params[:training_compound]] = {"c:c" => 6, "c:c:c" => 3, "O:O" => 2}
    params[:fingerprints][params[:training_compound2]] = {"c:c" => 2, "O:N" => 2}
    params[:weights] = { "c:c" => 0.95, "c:c:c" => 0.96, "O:N" => 0.97, "O:O" => 0.98}
    params[:features] = (params[:compound_features_hits].keys + params[:fingerprints][params[:training_compound2]].keys + params[:fingerprints][params[:training_compound]].keys).uniq
    2.times{
      params[:mode] = "min"
      assert_in_delta OpenTox::Algorithm.p_sum_support(params), 12.8762796504849, 0.00001
      params[:mode] = "max"
      assert_in_delta OpenTox::Algorithm.p_sum_support(params), 18.8034091184372, 0.00001
    }
  end
  
  def test_tanimoto
    params = {}
    params[:compound_features_hits] = { "c:c" => 10, "c:c:c" => 5, "O:N" => 2}
    params[:training_compound] = "http://localhost/compound/InChI=1S/CH2O/c1-2/h1H2"
    params[:training_compound2] = "http://localhost/compound/InChI=1S/c1-2/h1H2"
    params[:fingerprints] = {}
    params[:fingerprints][params[:training_compound]] = {"c:c" => 6, "c:c:c" => 3, "O:O" => 2}
    params[:fingerprints][params[:training_compound2]] = {"c:c" => 2, "O:N" => 2}
    weights = { "c:c" => 0.95, "c:c:c" => 0.96, "O:N" => 0.97, "O:O" => 0.98}
    features_a = params[:compound_features_hits].keys
    features_b = params[:fingerprints][params[:training_compound]].keys
    features_c = params[:fingerprints][params[:training_compound2]].keys

    2.times{
      params[:nr_hits] = nil
      #test without weights
      assert_in_delta OpenTox::Algorithm::Similarity.tanimoto(features_a, features_b, nil, params), 0.5, 0.000001
      assert_in_delta OpenTox::Algorithm::Similarity.tanimoto(features_a, features_c, nil, params), 0.666666666666667, 0.000001
      
      #test with weights
      assert_in_delta OpenTox::Algorithm::Similarity.tanimoto(features_a, features_b, weights, params), 0.498056105472291, 0.000001
      assert_in_delta OpenTox::Algorithm::Similarity.tanimoto(features_a, features_c, weights, params), 0.666545393630348, 0.000001

      #test with weights and nr_hits true
      params[:nr_hits] = "true"
      assert_in_delta OpenTox::Algorithm::Similarity.tanimoto(features_a, features_b, weights, params), 0.472823526091916, 0.000001  
      assert_in_delta OpenTox::Algorithm::Similarity.tanimoto(features_a, features_c, weights, params), 0.470450908604158, 0.000001
      }
  end

end
