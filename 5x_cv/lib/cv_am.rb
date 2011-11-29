# Do a 10-fold crossvalidation with mutiple datasets
# Author: Andreas Maunz, David Vorgrimmler
# @params: CSV-File, Method (LAST, BBRC), Minimum Frequency

def cv (args)

  #subjectid = OpenTox::Authorization.authenticate("guest","guest") 
  subjectid = nil

  if args.size != 12 
    puts
    puts "Error! Arguments: file_or_dataset_uri feature_generation min_frequency min_chisq_significance backbone stratified random_seed prediction_algorithm local_svm_kernel nr_hits conf_stdev pc_type"
    exit 1
  end

  reg=/^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix

  file=args[0]


  # dataset_is_uri=false
  # if reg.match(file)? true : false
  #   #file.include? "http"
  #   puts "Uri is valid"
  dataset_is_uri=true
  #    files = [ file ]
  # elsif ! File.exists? file
  #   puts "File #{file} missing"
  #   exit 1
  # end

  #  if args[1].to_s != "last" && args[1].to_s != "bbrc"
  if !(args[1].to_s.include? "/algorithm/fminer/bbrc") && !(args[1].to_s.include? "/algorithm/fminer/last")
    puts "feature_generation_uri must contain '/algorithm/fminer/last' or '/algorithm/fminer/bbrc'"
    #    puts "feature_generation must be 'last' or 'bbrc'"
    exit 1
  end

  if ! args[2] == ""
    if args[2].to_i < 2  
      puts "min_frequency must be at least 2 or \"\""
      exit 1
    end
  end

  if ! args[3] == ""
    if ! (args[3].to_f <= 1.0 && args[3].to_f >= 0.0)  
      puts "min_chisq_significance must be between 0 and 1 or \"\""
      exit 1
    end
  end

  if ! args[4] == ""
    if args[4].to_s != "true" && args[4].to_s != "false"
      puts "backbone must be 'true' or 'false'."
      exit 1
    end
  end


  if args[5].to_s != "true" && args[5].to_s != "false"
    puts "stratified must be 'true' or 'false'"
    exit 1
  end

  if ! args[6] == ""
    if ! (args[6].to_i <= 1)  
      puts "random_seed must be a natural number or \"\""
      exit 1
    end
  end

  if ! args[7] == ""
    if ! (args[7] == "local_svm_classification")  
      puts "lazar_prediction_method must be \"local_svm_classification\""
      exit 1
    end
  end

  if ! args[8] == ""
    if ! (args[8] == "weighted_tanimoto" || args[8] == "propositionalized")  
      puts "local_svm_kernel must be \"weighted_tanimoto\" or \"propositionalized\""
      exit 1
    end
  end

  if ! args[9] == ""
    if ! (args[9] == "true")  
      puts "nr_hits must be \"true\""
      exit 1
    end
  end

  if ! args[10] == ""
    if ! (args[10] == "true")  
      puts "conf_stdev must be \"true\""
      exit 1
    end
  end

  if ! args[11] == ""
    if ! (args[11] == "electronic" || args[11] == "geometrical" || args[11] == "topological" || args[11] == "constitutional")
      puts "pc_type must be \"electronic\", \"geometrical\", \"topological\" or \"constitutional\""
      exit 1
    end
  end


  #if !dataset_is_uri 
  #  # Upload a dataset
  #  training_dataset = OpenTox::Dataset.create_from_csv_file(file, subjectid)
  #  prediction_feature = training_dataset.features.keys[0]
  #  training_dataset_uri=training_dataset.uri
  #  puts prediction_feature
  #else
  training_dataset_uri=file
  puts training_dataset_uri
  prediction_feature = OpenTox::Dataset.find(training_dataset_uri).features.keys.first
  puts prediction_feature
  # end
  puts training_dataset_uri


  # Crossvalidation
  # @param [Hash] params (required:algorithm_uri,dataset_uri,prediction_feature, optional:algorithm_params,num_folds(10),random_seed(1),stratified(false))
  alg_params = "feature_generation_uri=#{args[1]}";
  alg_params = alg_params << ";min_frequency=#{args[2]}" unless args[2]==""
  alg_params = alg_params << ";min_chisq_significance=#{args[3]}" unless args[3]==""
  alg_params = alg_params << ";backbone=#{args[4]}" unless args[4]==""   
  alg_params = alg_params << ";prediction_algorithm=#{args[7]}" unless args[7]==""   
  alg_params = alg_params << ";local_svm_kernel=#{args[8]}" unless args[8]==""   
  alg_params = alg_params << ";nr_hits=#{args[9]}" unless args[9]==""
  alg_params = alg_params << ";conf_stdev=#{args[10]}" unless args[10]==""
  alg_params = alg_params << ";pc_type=#{args[11]}" unless args[11]==""

  stratified_param = args[5]
  random_seed_param = args[6]

  cv_args = {:dataset_uri => training_dataset_uri, :prediction_feature => prediction_feature, :algorithm_uri => args[1].split('fminer')[0] + "lazar", :algorithm_params => alg_params, :stratified => stratified_param }
  cv_args[:random_seed] = random_seed_param unless random_seed_param == ""
  puts file
  puts cv_args.to_yaml
  puts
  begin
    lazar_single_args = {}
    lazar_single_args[:feature_generation_uri] = "#{args[1]}";
    lazar_single_args[:min_frequency] = args[2] unless args[2]==""
    lazar_single_args[:min_chisq_significance] = args[3] unless args[3]==""
    lazar_single_args[:backbone] = args[4] unless args[4]==""   
    lazar_single_args[:prediction_algorithm] = args[7] unless args[7]==""   
    lazar_single_args[:local_svm_kernel] = args[8] unless args[8]==""   
    lazar_single_args[:nr_hits] = args[9] unless args[9]==""
    lazar_single_args[:conf_stdev] = args[10] unless args[10]==""
    lazar_single_args[:pc_type] = args[11] unless args[11]==""
    #m = OpenTox::Algorithm::Lazar.new.run({:dataset_uri => training_dataset_uri, :subjectid => subjectid}.merge lazar_single_args ).to_s
    #puts m
    cv = OpenTox::Crossvalidation.create(cv_args).uri
    puts cv
    cvr = OpenTox::CrossvalidationReport.create( cv , subjectid).uri
    puts cvr
    #qmrfr = OpenTox::QMRFReport.create(m).uri
    #puts qmrfr 
    #cv_stat = OpenTox::Validation.from_cv_statistics( cv, subjectid )
    #puts cv_stat.metadata.to_yaml
    #[ cv_stat, training_dataset_uri ]
  rescue Exception => e
    puts "cv failed: #{e.message} #{e.backtrace}"
  end

end
