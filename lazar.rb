require 'rubygems'
require 'opentox-ruby'
require 'test/unit'
require "./validate-owl.rb"

class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end
end

class LazarTest < Test::Unit::TestCase

  def setup
    @predictions = []
    @models = []
  end

  def teardown
    @predictions.each {|p| p.delete(@@subjectid)}
    @models.each {|m| m.delete(@@subjectid)}
  end

=begin
=end
  def test_create_regression_model
    model_uri = OpenTox::Algorithm::Lazar.new.run({:dataset_uri => @@regression_training_dataset.uri, :subjectid => @@subjectid}).to_s
    #puts model_uri
    validate_owl model_uri,@@subjectid
    lazar = OpenTox::Model::Lazar.find model_uri, @@subjectid
    @models << lazar
    assert_equal 219, lazar.features.size
    compound = OpenTox::Compound.from_smiles("c1ccccc1NN")
    prediction_uri = lazar.run(:compound_uri => compound.uri, :subjectid => @@subjectid).to_s
    prediction = OpenTox::LazarPrediction.find(prediction_uri, @@subjectid)
    @predictions << prediction
    assert_equal prediction.value(compound).round_to(3),0.378.round_to(3)
    assert_equal prediction.confidence(compound).round_to(3), 0.276.round_to(3)
    #assert_equal prediction.value(compound).round_to(4), 0.2847.round_to(4)
    #assert_equal prediction.confidence(compound).round_to(4), 0.3223.round_to(4)
    assert_equal prediction.neighbors(compound).size, 61
  end

  def test_create_regression_prop_model
    model_uri = OpenTox::Algorithm::Lazar.new.run({:dataset_uri => @@regression_training_dataset.uri, :subjectid => @@subjectid, :local_svm_kernel => "propositionalized"}).to_s
    #puts model_uri
    validate_owl model_uri,@@subjectid
    lazar = OpenTox::Model::Lazar.find model_uri, @@subjectid
    @models << lazar
    assert_equal 219, lazar.features.size
    compound = OpenTox::Compound.from_smiles("c1ccccc1NN")
    prediction_uri = lazar.run(:compound_uri => compound.uri, :subjectid => @@subjectid).to_s
    prediction = OpenTox::LazarPrediction.find(prediction_uri, @@subjectid)
    @predictions << prediction
    assert_equal prediction.value(compound).round_to(1),0.1.round_to(1)
    assert_equal prediction.confidence(compound).round_to(3), 0.276.round_to(3)
    #assert_equal prediction.value(compound).round_to(4), 0.2847.round_to(4)
    #assert_equal prediction.confidence(compound).round_to(4), 0.3223.round_to(4)
    assert_equal prediction.neighbors(compound).size, 61
  end

  def test_classification_model

    # create model
    model_uri = OpenTox::Algorithm::Lazar.new.run({:dataset_uri => @@classification_training_dataset.uri, :subjectid => @@subjectid}).to_s
    validate_owl model_uri,@@subjectid
    lazar = OpenTox::Model::Lazar.find model_uri, @@subjectid
    @models << lazar
    assert_equal lazar.features.size, 52

    # single prediction
    compound = OpenTox::Compound.from_smiles("c1ccccc1NN")
    prediction_uri = lazar.run(:compound_uri => compound.uri, :subjectid => @@subjectid)
    prediction = OpenTox::LazarPrediction.find(prediction_uri, @@subjectid)
    @predictions << prediction
    #puts prediction_uri
    assert_equal prediction.value(compound), "false"
    assert_equal prediction.confidence(compound).round_to(4), 0.3067.round_to(4)
    assert_equal prediction.neighbors(compound).size, 14

    # dataset activity
    compound = OpenTox::Compound.from_smiles("CNN")
    prediction_uri  = lazar.run(:compound_uri => compound.uri, :subjectid => @@subjectid)
    prediction = OpenTox::LazarPrediction.find prediction_uri, @@subjectid
    @predictions << prediction
    assert !prediction.measured_activities(compound).empty?
    assert_equal prediction.measured_activities(compound).first.to_s, "true"
    assert prediction.value(compound).nil?

    # dataset prediction
    test_dataset = OpenTox::Dataset.create_from_csv_file("data/multicolumn.csv", @@subjectid)
    prediction = OpenTox::LazarPrediction.find lazar.run(:dataset_uri => test_dataset.uri, :subjectid => @@subjectid), @@subjectid
    @predictions << prediction
    assert_equal prediction.compounds.size, 4
    compound = OpenTox::Compound.from_smiles "CC(=Nc1ccc2c(c1)Cc1ccccc21)O"
    assert_equal prediction.value(compound), nil
    assert_equal prediction.measured_activities(compound).first.to_s, "true"
  end

  def test_classification_svm_model

    # create model
    model_uri = OpenTox::Algorithm::Lazar.new.run({:dataset_uri => @@classification_training_dataset.uri, :subjectid => @@subjectid, :prediction_algorithm => "local_svm_classification"}).to_s
    lazar = OpenTox::Model::Lazar.find model_uri, @@subjectid
    @models << lazar
    assert_equal lazar.features.size, 52

    # single prediction
    compound = OpenTox::Compound.from_smiles("c1ccccc1NN")
    prediction_uri = lazar.run(:compound_uri => compound.uri, :subjectid => @@subjectid)
    prediction = OpenTox::LazarPrediction.find(prediction_uri, @@subjectid)
    @predictions << prediction
    assert_equal prediction.value(compound), "false"
    assert_equal prediction.confidence(compound).round_to(4), 0.4131.round_to(4)
    assert_equal prediction.neighbors(compound).size, 14

    # dataset prediction
    test_dataset = OpenTox::Dataset.create_from_csv_file("data/multicolumn.csv", @@subjectid)
    prediction = OpenTox::LazarPrediction.find lazar.run(:dataset_uri => test_dataset.uri, :subjectid => @@subjectid), @@subjectid
    @predictions << prediction
    assert_equal prediction.compounds.size, 4
    compound = OpenTox::Compound.from_smiles "CC(=Nc1ccc2c(c1)Cc1ccccc21)O"
    assert_equal prediction.value(compound), nil
    assert_equal prediction.measured_activities(compound).first, true
 end

  def test_classification_svm_prop_model


    # create model
    model_uri = OpenTox::Algorithm::Lazar.new.run({:dataset_uri => @@classification_training_dataset.uri, :subjectid => @@subjectid, :prediction_algorithm => "local_svm_classification", :local_svm_kernel => "propositionalized"}).to_s
    lazar = OpenTox::Model::Lazar.find model_uri, @@subjectid
    @models << lazar
    assert_equal lazar.features.size, 52

    # single prediction
    compound = OpenTox::Compound.from_smiles("c1ccccc1NN")
    prediction_uri = lazar.run(:compound_uri => compound.uri, :subjectid => @@subjectid)
    prediction = OpenTox::LazarPrediction.find(prediction_uri, @@subjectid)
    @predictions << prediction
    assert_equal prediction.value(compound), "false"
    assert_equal prediction.confidence(compound).round_to(4), 0.4131.round_to(4)
    assert_equal prediction.neighbors(compound).size, 14

    # dataset prediction
    test_dataset = OpenTox::Dataset.create_from_csv_file("data/multicolumn.csv", @@subjectid)
    prediction = OpenTox::LazarPrediction.find lazar.run(:dataset_uri => test_dataset.uri, :subjectid => @@subjectid), @@subjectid
    @predictions << prediction
    assert_equal prediction.compounds.size, 4
    compound = OpenTox::Compound.from_smiles "CC(=Nc1ccc2c(c1)Cc1ccccc21)O"
    assert_equal prediction.value(compound), nil
    assert_equal prediction.measured_activities(compound).first, true

  end

  def test_ambit_classification_model

    # create model
    dataset_uri = "http://apps.ideaconsult.net:8080/ambit2/dataset/9?max=400"
    feature_uri ="http://apps.ideaconsult.net:8080/ambit2/feature/21573"
    #model_uri = OpenTox::Algorithm::Lazar.new.run({:dataset_uri => dataset_uri, :prediction_feature => feature_uri}).to_s
    #lazar = OpenTox::Model::Lazar.find model_uri
    model_uri = OpenTox::Algorithm::Lazar.new.run({:dataset_uri => dataset_uri, :prediction_feature => feature_uri, :subjectid => @@subjectid}).to_s
    validate_owl model_uri,@@subjectid
    lazar = OpenTox::Model::Lazar.find model_uri, @@subjectid
    puts lazar.features.size
    assert_equal lazar.features.size, 1874
    #puts "Model: #{lazar.uri}"
    #puts lazar.features.size

    # single prediction
    compound = OpenTox::Compound.from_smiles("c1ccccc1NN")
    #prediction_uri = lazar.run(:compound_uri => compound.uri)
    #prediction = OpenTox::LazarPrediction.find(prediction_uri)
    prediction_uri = lazar.run(:compound_uri => compound.uri, :subjectid => @@subjectid)
    prediction = OpenTox::LazarPrediction.find(prediction_uri, @@subjectid)
    #puts "Prediction: #{prediction.uri}"
    #puts prediction.value(compound)
    assert_equal prediction.value(compound), "3.0"
    #puts @prediction.confidence(compound).round_to(4)
    #assert_equal @prediction.confidence(compound).round_to(4), 0.3005.round_to(4)
    #assert_equal @prediction.neighbors(compound).size, 15
    #@prediction.delete(@@subjectid)

    # dataset activity
    #compound = OpenTox::Compound.from_smiles("CNN")
    #prediction_uri  = @lazar.run(:compound_uri => compound.uri, :subjectid => @@subjectid)
    #@prediction = OpenTox::LazarPrediction.find prediction_uri, @@subjectid
    #assert !@prediction.measured_activities(compound).empty?
    #assert_equal @prediction.measured_activities(compound).first, true
    #assert @prediction.value(compound).nil?
    #@prediction.delete(@@subjectid)

    # dataset prediction
    #@lazar.delete(@@subjectid)
  end
=begin
=end

end
