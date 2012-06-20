# # Author: Andreas Maunz, David Vorgrimmler

require 'rubygems'
require 'opentox-ruby'
require 'yaml'

if ARGV.size != 7 
  puts "Args: path/to/dataset.yaml ds_name num_boots backbone min_frequency method find_min_frequency"
  puts ARGV.size
  exit
end

path = ARGV[0]
ds_file = path.split("/").last

if File.exists?(path)
  puts "[#{Time.now.iso8601(4).to_s}] #{ds_file} exists."
else
  puts "#{ds_file} does not exist."
  exit
end

subjectid = nil

ds_name = ARGV[1] # e.g. MOU,RAT
num_boots = ARGV[2] # integer, 100 recommended
backbone = ARGV[3] # true/false
min_freq = ARGV[4] # integer
method = ARGV[5] # mle, mean, bbrc
find_min_frequency = ARGV[6] # true/false
hits = false

ds = YAML::load_file("#{path}")
ds_uri = ds[ds_name]["dataset"]

result1 = []
result2 = []
metadata = []

begin
  for i in 1..50
    puts
    puts "--------------------------- Round: #{i} ---------------------------"

    #################################
    # SPLIT
    #################################
    puts "                       ----- split ds -----"
    split_params = {}
    split_params["dataset_uri"] = ds_uri
    split_params["prediction_feature"] = (ds_uri.to_s + "/feature/1")
    split_params["stratified"] = true 
    split_params["split_ratio"] = 0.5
    split_params["random_seed"] = i
    puts "[#{Time.now.iso8601(4).to_s}] Split params: #{split_params.to_yaml}"

    split_result = OpenTox::RestClientWrapper.post( File.join(CONFIG[:services]["opentox-validation"],"plain_training_test_split"), split_params)
    datasets = {}
    datasets[:training_ds] = split_result.inspect.gsub(/"/,'').split("\\n")[0]
    datasets[:test_ds] = split_result.inspect.gsub(/"/,'').split("\\n")[1]
    puts "[#{Time.now.iso8601(4).to_s}] Split result: #{datasets.to_yaml}"
    puts

    #################################
    # FIND "good" min_frequency 
    #################################

    if find_min_frequency.to_s == "true"
      min_params = {}
      min_params["dataset_uri"] = datasets[:training_ds]

      ds = OpenTox::Dataset.find(datasets[:training_ds])
      ds_nr_com = ds.compounds.size

      min_params["backbone"] = backbone
      durations = []
      x = ds_nr_com
      ds_result_nr_f = 0
      y = x
      y_old = 0
      #  puts
      #  puts "----- Initialization: -----"
      while ds_result_nr_f < (ds_nr_com/4).to_i do
        y_old = y
        y = x
        x = (x/2).to_i
        min_params["min_frequency"] = x
        t = Time.now
        result_uri = OpenTox::RestClientWrapper.post( File.join(CONFIG[:services]["opentox-algorithm"],"fminer/bbrc/"), min_params )
        durations << Time.now - t
        ds_result = OpenTox::Dataset.find(result_uri)
        ds_result_nr_f = ds_result.features.size
      end  

      #  puts
      #  puts "----- Main phase: -----"
      max_duration = durations[0] +(ds_nr_com.to_f * 0.003) # this is only an experience value.
      min_params["min_frequency"] = y
      y = y_old
      found = false
      cnt = 0
      min_f = min_params["min_frequency"]
      # Search for min_frequency with following heuristic procedure. If no good min_frequency found the delivered value(from the arguments) is used.
      while found == false || cnt == 4 do
        if min_f == min_params["min_frequency"]
          cnt = cnt + 1
        end
        min_f = min_params["min_frequency"]
        t = Time.now
        result_uri = OpenTox::RestClientWrapper.post( File.join(CONFIG[:services]["opentox-algorithm"],"fminer/bbrc/"), min_params )
        durations << Time.now - t
        ds_result = OpenTox::Dataset.find(result_uri)
        ds_result_nr_f = ds_result.features.size
        # Check if number of features is max half and min one-tenth of the number of compounds and performed in accaptable amount of time
        if ds_result_nr_f.to_i < (ds_nr_com/2).to_i && ds_result_nr_f.to_i > (ds_nr_com/10).to_i
          if durations.last < max_duration
            found = true
            min_freq = min_params["min_frequency"]
          else
            x = min_params["min_frequency"]
            min_params["min_frequency"] = ((min_params["min_frequency"]+y)/2).to_i
          end
        else
          y = min_params["min_frequency"]
          min_params["min_frequency"] = ((x+min_params["min_frequency"])/2).to_i
        end
      end
    end

    #################################
    # BBRC SAMPLE
    #################################
    puts "                ----- bbrc feature calulation -----"
    algo_params = {}
    algo_params["dataset_uri"] = datasets[:training_ds]
    algo_params["backbone"] = backbone
    algo_params["min_frequency"] = min_freq
    algo_params["nr_hits"] = hits
    algo_params["method"] = method

    t = Time.now
    if method == "bbrc"
      puts "[#{Time.now.iso8601(4).to_s}] BBRC params: #{algo_params.to_yaml}"
      feature_dataset_uri = OpenTox::RestClientWrapper.post( File.join(CONFIG[:services]["opentox-algorithm"],"fminer/bbrc"), algo_params )
    else
      algo_params["num_boots"] = num_boots
      algo_params["random_seed"] = i
      puts "[#{Time.now.iso8601(4).to_s}] BBRC params: #{algo_params.to_yaml}"
      feature_dataset_uri = OpenTox::RestClientWrapper.post( File.join(CONFIG[:services]["opentox-algorithm"],"fminer/bbrc/sample"), algo_params )
    end
    duration = Time.now - t
    puts "[#{Time.now.iso8601(4).to_s}] BBRC duration: #{duration}"
    puts "[#{Time.now.iso8601(4).to_s}] BBRC result: #{feature_dataset_uri}"
    puts

    #################################
    # MATCH
    #################################
    puts "                      ----- bbrc match -----"
    match_params = {}
    match_params["feature_dataset_uri"] = "#{feature_dataset_uri}"
    match_params["dataset_uri"] = datasets[:test_ds]
    match_params["min_frequency"] = min_freq
    match_params["nr_hits"] = hits
    puts "[#{Time.now.iso8601(4).to_s}] Match params: #{match_params.to_yaml}"

    matched_dataset_uri = OpenTox::RestClientWrapper.post(File.join(CONFIG[:services]["opentox-algorithm"],"fminer","bbrc","match"),match_params)
    puts "[#{Time.now.iso8601(4).to_s}] BBRC match result: #{matched_dataset_uri}"
    puts

    #################################
    # COMPARE pValues
    #################################
    puts "                 ----- pValue comparision -----"
    bbrc_ds = OpenTox::Dataset.find(feature_dataset_uri)
    bbrc_smarts_pValues = {}
    bbrc_ds.features.each do |f, values|
      if values[RDF::type].include?(OT.Substructure)
        bbrc_smarts_pValues[values[OT::smarts]] =  values[OT::pValue]
      end
    end 

    match_ds = OpenTox::Dataset.find(matched_dataset_uri)
    matched_smarts_pValues = {}
    match_ds.features.each do |f, values|
      if values[RDF::type].include?(OT.Substructure)
        matched_smarts_pValues[values[OT::smarts]] =  values[OT::pValue]
      end
    end

    sum_E1 = 0.0
    sum_E2 = 0.0
    bbrc_smarts_pValues.each do |s, p|
      if matched_smarts_pValues.include?(s)
        dif = (p.to_f - matched_smarts_pValues[s].to_f).abs
        sum_E1 = sum_E1 + dif 
        sum_E2 = sum_E2 + dif**2
      end
    end 
    puts "[#{Time.now.iso8601(4).to_s}] Sum pValue difference (E1): #{sum_E1}"
    puts "[#{Time.now.iso8601(4).to_s}] Squared sum pValue difference (E2): #{sum_E2}"

    #################################
    # SAVE data 
    #################################
    result1 << sum_E1
    result2 << sum_E2

    info = []
    info << { :ds_name => ds_name, :nr_features => bbrc_ds.features.size} 
    info << split_params
    info << algo_params
    info << match_params

    metadata << info
    puts
  end

  puts "############################################"
  puts "############# FINAL RESULTS ################"
  puts "############################################"
  puts
  puts "[#{Time.now.iso8601(4).to_s}] metadata: #{metadata.to_yaml}"
  puts
  puts "[#{Time.now.iso8601(4).to_s}] result1: #{result1.to_yaml}"
  puts
  puts "[#{Time.now.iso8601(4).to_s}] result2: #{result2.to_yaml}"

rescue Exception => e
  LOGGER.debug "#{e.class}: #{e.message}"
  LOGGER.debug "Backtrace:\n\t#{e.backtrace.join("\n\t")}"

  puts "############################################"
  puts "############ RESULTS befor error ###########"
  puts "############################################"
  puts
  puts "[#{Time.now.iso8601(4).to_s}] metadata: #{metadata.to_yaml}"
  puts
  puts "[#{Time.now.iso8601(4).to_s}] result1: #{result1.to_yaml}"
  puts
  puts "[#{Time.now.iso8601(4).to_s}] result2: #{result2.to_yaml}"
end

