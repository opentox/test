require 'rubygems'
require 'opentox-ruby'

=begin
=end
class Exception
  def message
   errorCause ? errorCause.to_yaml : to_s
  end
end

TEST_USER = "guest"
TEST_PW   = "guest"

task ARGV[0] do
  puts "Environment: #{ENV["RACK_ENV"]}"
  puts "Test: "+ARGV[0]+".rb"
  require "./"+ARGV[0]+".rb"
end

task :setup do
  @@subjectid = OpenTox::Authorization.authenticate(TEST_USER,TEST_PW) 
  @@classification_training_dataset = OpenTox::Dataset.create_from_csv_file("data/hamster_carcinogenicity.csv", @@subjectid)
  @@multinomial_training_dataset = OpenTox::Dataset.create_from_csv_file("data/ISSCAN-multi.csv", @@subjectid)
  @@regression_training_dataset = OpenTox::Dataset.create_from_csv_file("data/EPAFHM.csv", @@subjectid)
  @@regression_feature_dataset = OpenTox::Dataset.create_from_csv_file("data/EPAFHM-constitutional.csv", @@subjectid)
end

task :teardown do
  @@classification_training_dataset.delete(@@subjectid)
  @@multinomial_training_dataset.delete(@@subjectid)
  @@regression_training_dataset.delete(@@subjectid)
  @@regression_feature_dataset.delete(@@subjectid)
  OpenTox::Authorization.logout(@@subjectid)
end

#[:all, :feature, :dataset, :fminer, :lazar, :authorization, :validation].each do |t|
[:all, :algorithm, :feature, :dataset, :fminer, :lazar, :authorization, :parser, :validation ].each do |t|
  task :teardown => t
  task t => :setup 
end
