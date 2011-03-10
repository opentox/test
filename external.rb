require 'rubygems'
require 'opentox-ruby'
require 'test/unit'
require "./validate-owl.rb"

class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end
end

class ExternalAlgorithmTest < Test::Unit::TestCase


      # fix dataset
      #"http://opentox.informatik.tu-muenchen.de:8080/OpenTox-dev/algorithm/J48" => {:dataset_uri => "http://apps.ideaconsult.net:8080/ambit2/dataset/10", :prediction_feature => "http://apps.ideaconsult.net:8080/ambit2/feature/21595"},
      #"http://apps.ideaconsult.net:8080/ambit2/algorithm/toxtreeskinirritation" => {:dataset_uri => "http://apps.ideaconsult.net:8080/ambit2/dataset/2698" }, # TASK redirects to model
      #"http://apps.ideaconsult.net:8080/ambit2/algorithm/org.openscience.cdk.qsar.descriptors.molecular.ALOGPDescriptor" => {:dataset_uri => "http://apps.ideaconsult.net:8080/ambit2/dataset/2698" }
      #""
  def test_model_creation
    {
      # works
=begin
      "http://opentox.informatik.tu-muenchen.de:8080/OpenTox-dev/algorithm/J48" => {
        :params => {
          :dataset_uri => "http://apps.ideaconsult.net:8080/ambit2/dataset/19629",
          :prediction_feature => "http://apps.ideaconsult.net:8080/ambit2/feature/111148"
        },
        :feature_value => []
      },
=end
      "http://opentox.ntua.gr:3000/algorithm/svm" => {
        :params => {
          :dataset_uri => "http://apps.ideaconsult.net:8080/ambit2/dataset/54",
          :prediction_feature => "http://apps.ideaconsult.net:8080/ambit2/feature/22201"
          #:prediction_feature => "http://apps.ideaconsult.net:8080/ambit2/feature/28364"
        },
        :feature_value => []
      }
    }.each do |uri,data|
      algorithm = OpenTox::Algorithm::Generic.new uri
      model_uri = algorithm.run(data[:params])
      #puts model_uri
      assert_match /model/, model_uri
    end
  end

=begin
  def test_descriptor_services
    {
      # works
      "http://opentox.informatik.tu-muenchen.de:8080/OpenTox-dev/algorithm/CDKPhysChem" => {
        :params => {:dataset_uri => "http://apps.ideaconsult.net:8080/ambit2/dataset/2698" },
        :feature_value => [
          "http://apps.ideaconsult.net:8080/ambit2/compound/143948/conformer/420420",
          "http://apps.ideaconsult.net:8080/ambit2/feature/26184",
          0.5509999990463257
        ]
      },
      "http://opentox.informatik.tu-muenchen.de:8080/OpenTox-dev/algorithm/JOELIB2" => {
        :params => {:dataset_uri => "http://apps.ideaconsult.net:8080/ambit2/dataset/2698" },
        :feature_value => [
          "http://apps.ideaconsult.net:8080/ambit2/compound/143948/conformer/420420",
          "http://apps.ideaconsult.net:8080/ambit2/feature/26556",
          4.16669988632202
        ]
      },
    }.each do |uri,data|
      algorithm = OpenTox::Algorithm::Generic.new uri
      dataset_uri = algorithm.run(data[:params])
      puts dataset_uri
      dataset = OpenTox::Dataset.find dataset_uri
      assert_equal dataset.compounds.size, 3
      c = data[:feature_value][0]
      f = data[:feature_value][1]
      v = dataset.data_entries[c][f].first.to_f
      assert_equal v.round_to(5), data[:feature_value][2].round_to(5)
      #dataset.delete
      #puts dataset.to_yaml
    end
  end
=end

end
