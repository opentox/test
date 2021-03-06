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
    @compounds = []
    @files = []
    @dump_dir = FileUtils.mkdir_p File.join(File.dirname(__FILE__),"dump",File.basename(__FILE__,".rb"))
    FileUtils.mkdir_p File.join(File.dirname(__FILE__),"reference",File.basename(__FILE__,".rb"))
  end

  def dump(object,file)
    @files << file
    FileUtils.mkdir_p File.dirname(file)
    File.open(file,"w+"){|f| f.puts object.to_yaml}
  end

  def create_model(params)
    params[:subjectid] = @@subjectid
    params[:min_frequency] = "8"
    model_uri = OpenTox::Algorithm::Lazar.new.run(params).to_s
    @model = OpenTox::Model::Lazar.find model_uri, @@subjectid
    dump @model, File.join(@dump_dir,caller[0][/`.*'/][1..-2],"model")+".yaml"
  end

  def predict_compound(compound)
    @compounds << compound
    prediction_uri = @model.run(:compound_uri => compound.uri, :subjectid => @@subjectid)
    prediction = OpenTox::LazarPrediction.find(prediction_uri, @@subjectid)
    @predictions << prediction
    dump prediction, File.join(@dump_dir,caller[0][/`.*'/][1..-2],"compound_prediction")+@compounds.size.to_s+".yaml"
  end

  def predict_dataset(dataset)
    prediction_uri = @model.run(:dataset_uri => dataset.uri,  :subjectid => @@subjectid)
    prediction = OpenTox::LazarPrediction.find(prediction_uri, @@subjectid)
    @predictions << prediction
    dump prediction, File.join(@dump_dir,caller[0][/`.*'/][1..-2],"dataset_prediction")+".yaml"
  end

  def cleanup # executed only when assertions succeed (teardown is called even when assertions fail)
    @files.each do |f|
      reference = f.sub(/dump/,"reference")
      FileUtils.mkdir_p File.dirname(reference)
      FileUtils.cp f, reference
      FileUtils.rm f
    end
    @predictions.each do |dataset|
      dataset.delete(@@subjectid)
    end
    @model.delete(@@subjectid)
  end


## Regression
def test_create_regression_svm_pc_model
  create_model :dataset_uri => @@regression_training_dataset.uri, :feature_dataset_uri => @@regression_feature_dataset.uri, :pc_type => "constitutional", :lib => "cdk", :subjectid => @@subjectid
  predict_compound OpenTox::Compound.from_smiles("c1ccccc1NN")
  assert_in_delta @predictions.first.value(@compounds.first), 17.13, 0.3
  assert_equal 0.531, @predictions.first.confidence(@compounds.first).round_to(3)
  assert_equal 91, @predictions.first.neighbors(@compounds.first).size
  cleanup
end


##Classification
def test_classification_model
  create_model :dataset_uri => @@classification_training_dataset.uri, :subjectid => @@subjectid
  # single prediction
  predict_compound OpenTox::Compound.from_smiles("c1ccccc1NN")
  # dataset activity
  predict_compound OpenTox::Compound.from_smiles("CNN")
  # dataset prediction
  predict_dataset OpenTox::Dataset.create_from_csv_file("data/multicolumn.csv", @@subjectid)
  # assertions
  # single prediction
  assert_equal "false", @predictions[0].value(@compounds[0])
  assert_equal 0.3443.round_to(4), @predictions[0].confidence(@compounds[0]).round_to(4)
  assert_equal 18, @predictions[0].neighbors(@compounds[0]).size
  # dataset activity
  assert !@predictions[1].measured_activities(@compounds[1]).empty?
  assert_equal "true", @predictions[1].measured_activities(@compounds[1]).first.to_s
  assert @predictions[1].value(@compounds[1]).nil?
  # dataset prediction
  c = OpenTox::Compound.from_smiles("CC(=Nc1ccc2c(c1)Cc1ccccc21)O")
  assert_equal nil, @predictions[2].value(c)
  assert_equal "true", @predictions[2].measured_activities(c).first.to_s
  c = OpenTox::Compound.from_smiles("c1ccccc1NN")
  assert_equal "false", @predictions[2].value(c)
  assert_equal 0.3443 , @predictions[2].confidence(c).round_to(4)
  # model
  assert_equal 25, @model.features.size
  cleanup
end
 
# DISABLED TEMPORARILY
#   def test_ambit_classification_model
#
#     # create model
#     dataset_uri = "http://apps.ideaconsult.net:8080/ambit2/dataset/9?max=400"
#     feature_uri ="http://apps.ideaconsult.net:8080/ambit2/feature/2153"
#     #model_uri = OpenTox::Algorithm::Lazar.new.run({:dataset_uri => dataset_uri, :prediction_feature => feature_uri}).to_s
#     #lazar = OpenTox::Model::Lazar.find model_uri
#     model_uri = OpenTox::Algorithm::Lazar.new.run({:dataset_uri => dataset_uri, :prediction_feature => feature_uri, :subjectid => @@subjectid}).to_s
#     validate_owl model_uri,@@subjectid
#     lazar = OpenTox::Model::Lazar.find model_uri, @@subjectid
#     puts lazar.features.size
#     assert_equal lazar.features.size, 1874
#     #puts "Model: #{lazar.uri}"
#     #puts lazar.features.size
#
#     # single prediction
#     compound = OpenTox::Compound.from_smiles("c1ccccc1NN")
#     #prediction_uri = lazar.run(:compound_uri => compound.uri)
#     #prediction = OpenTox::LazarPrediction.find(prediction_uri)
#     prediction_uri = lazar.run(:compound_uri => compound.uri, :subjectid => @@subjectid)
#     prediction = OpenTox::LazarPrediction.find(prediction_uri, @@subjectid)
#     #puts "Prediction: #{prediction.uri}"
#     #puts prediction.value(compound)
#     assert_equal prediction.value(compound), "3.0"
#     #puts @prediction.confidence(compound).round_to(4)
#     #assert_equal @prediction.confidence(compound).round_to(4), 0.3005.round_to(4)
#     #assert_equal @prediction.neighbors(compound).size, 15
#     #@prediction.delete(@@subjectid)
#
#     # dataset activity
#     #compound = OpenTox::Compound.from_smiles("CNN")
#     #prediction_uri  = @lazar.run(:compound_uri => compound.uri, :subjectid => @@subjectid)
#     #@prediction = OpenTox::LazarPrediction.find prediction_uri, @@subjectid
#     #assert !@prediction.measured_activities(compound).empty?
#     #assert_equal @prediction.measured_activities(compound).first, true
#     #assert @prediction.value(compound).nil?
#     #@prediction.delete(@@subjectid)
#
#     # dataset prediction
#     #@lazar.delete(@@subjectid)
#   end

end
