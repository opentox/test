require 'rubygems'
require 'opentox-ruby'
require 'test/unit'

class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end
end

class LazarRegressionTest < Test::Unit::TestCase

=begin
=end
  def test_create_regression_model
    model_uri = OpenTox::Algorithm::Lazar.new.run({:dataset_uri => @@regression_training_dataset.uri, :subjectid => @@subjectid}).to_s
    @lazar = OpenTox::Model::Lazar.find model_uri, @@subjectid
    assert_equal 225, @lazar.features.size
    compound = OpenTox::Compound.from_smiles("c1ccccc1NN")
    prediction_uri = @lazar.run(:compound_uri => compound.uri, :subjectid => @@subjectid).to_s
    @prediction = OpenTox::LazarPrediction.find(prediction_uri, @@subjectid)
    assert_equal @prediction.value(compound).round_to(4), 0.1618.round_to(4)
    assert_equal @prediction.confidence(compound).round_to(4), 0.6114.round_to(4)
    assert_equal @prediction.neighbors(compound).size, 81
    @prediction.delete(@@subjectid)
    @lazar.delete(@@subjectid)
  end
end

class LazarClassificationTest < Test::Unit::TestCase
  def test_classification_model

    # create model
    model_uri = OpenTox::Algorithm::Lazar.new.run({:dataset_uri => @@classification_training_dataset.uri, :subjectid => @@subjectid}).to_s
    @lazar = OpenTox::Model::Lazar.find model_uri, @@subjectid
    assert_equal @lazar.features.size, 41

    # single prediction
    compound = OpenTox::Compound.from_smiles("c1ccccc1NN")
    prediction_uri = @lazar.run(:compound_uri => compound.uri, :subjectid => @@subjectid)
    @prediction = OpenTox::LazarPrediction.find(prediction_uri, @@subjectid)
    assert_equal @prediction.value(compound), false
    assert_equal @prediction.confidence(compound).round_to(4), 0.3005.round_to(4)
    assert_equal @prediction.neighbors(compound).size, 15
    @prediction.delete(@@subjectid)

    # dataset activity
    compound = OpenTox::Compound.from_smiles("CNN")
    prediction_uri  = @lazar.run(:compound_uri => compound.uri, :subjectid => @@subjectid)
    @prediction = OpenTox::LazarPrediction.find prediction_uri, @@subjectid
    assert !@prediction.measured_activities(compound).empty?
    assert_equal @prediction.measured_activities(compound).first, true
    assert @prediction.value(compound).nil?
    @prediction.delete(@@subjectid)

    # dataset prediction
    test_dataset = OpenTox::Dataset.create_from_csv_file("data/multicolumn.csv", @@subjectid)
    @prediction = OpenTox::LazarPrediction.find @lazar.run(:dataset_uri => test_dataset.uri, :subjectid => @@subjectid), @@subjectid
    assert_equal @prediction.compounds.size, 4
    compound = OpenTox::Compound.new "http://ot-dev.in-silico.ch/compound/InChI=1S/C15H13NO/c1-10(17)16-13-6-7-15-12(9-13)8-11-4-2-3-5-14(11)15/h2-7,9H,8H2,1H3,(H,16,17)" 
    assert_equal @prediction.value(compound), nil
    assert_equal @prediction.measured_activities(compound).first, true
    @prediction.delete(@@subjectid)
    @lazar.delete(@@subjectid)
  end

=begin
=end
end
