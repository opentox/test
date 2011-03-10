require 'rubygems'
require 'opentox-ruby'
require 'test/unit'

class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end
end

class ValidationTest < Test::Unit::TestCase

=begin
=end
  def test_crossvalidation
=begin
=end
    puts "creating model ..."
    model_uri = OpenTox::Algorithm::Lazar.new.run({:dataset_uri => @@classification_training_dataset.uri, :subjectid => @@subjectid}).to_s
    lazar = OpenTox::Model::Lazar.find model_uri, @@subjectid
    puts @@classification_training_dataset.features.to_yaml
    params = {
      :algorithm_uri => File.join(CONFIG[:services]["opentox-algorithm"],"lazar"),
      :dataset_uri => lazar.parameter("dataset_uri"),
      #:dataset_uri => @@classification_training_dataset.uri,
      :subjectid => @@subjectid,
      #:prediction_feature => @@classification_training_dataset.features.keys.first,
      #:algorithm_params => "feature_generation_uri=#{File.join(CONFIG[:services]["opentox-algorithm"],"bbrc")}"
      :prediction_feature => lazar.parameter("prediction_feature"),
      :algorithm_params => "feature_generation_uri=#{lazar.parameter("feature_generation_uri")}"
    }
    puts params.to_yaml
    cv = OpenTox::Validation.create_crossvalidation(params)
    puts cv.uri
  #@@subjectid = OpenTox::Authorization.authenticate(TEST_USER,TEST_PW) 
    cv = OpenTox::Validation.new "http://opentox.informatik.uni-freiburg.de/validation/crossvalidation/6"
    puts cv.uri
    #puts cv.create_report(@@subjectid)
    #puts cv.create_qmrf_report(@@subjectid)
    #v = YAML.load OpenTox::RestClientWrapper.get(cv.uri,{:accept => "application/x-yaml", :subjectid => @@subjectid}).to_s
    v = YAML.load OpenTox::RestClientWrapper.get(File.join(cv.uri, 'statistics'),{:accept => "application/x-yaml", :subjectid => @@subjectid}).to_s
    puts v.to_yaml
    #puts cv.summary("classification",@@subjectid)
  end
end
