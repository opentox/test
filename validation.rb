ENV['RACK_ENV'] = 'production'

require 'test/unit'
require 'validation_util.rb'

#TEST_USER = "guest"
#TEST_PW = "guest"

#LOGGER = OTLogger.new(STDOUT)
#LOGGER.datetime_format = "%Y-%m-%d %H:%M:%S "
#LOGGER.formatter = Logger::Formatter.new

class Exception
  def message
    errorCause ? errorCause.to_yaml : to_s
  end
end

class ValidationTest < Test::Unit::TestCase

  @@delete = true
  @@hamster_cv_feature_types = ["bbrc", "last"]
  @@qmrf_test = true
  @@data = []
  @@data << { :type => :crossvalidation,
      :data => "http://apps.ideaconsult.net:8080/ambit2/dataset/272?max=100",
      :feat => "http://apps.ideaconsult.net:8080/ambit2/feature/26221",
      :info => "http://apps.ideaconsult.net:8080/ambit2/dataset/272?max=100" } 
  @@data << { :type => :training_test_validation,
      :train_data => "http://apps.ideaconsult.net:8080/ambit2/dataset/272?page=0&pagesize=150",
      :test_data => "http://apps.ideaconsult.net:8080/ambit2/dataset/272?page=3&pagesize=50",
      :feat => "http://apps.ideaconsult.net:8080/ambit2/feature/26221",
      :info => "http://apps.ideaconsult.net:8080/ambit2/dataset/272?page=0&pagesize=150" } 
  @@data << { :type => :training_test_validation,
      :train_data => "http://apps.ideaconsult.net:8080/ambit2/dataset/435293?page=0&pagesize=300",
      :test_data => "http://apps.ideaconsult.net:8080/ambit2/dataset/435293?page=30&pagesize=10",
      :feat => "http://apps.ideaconsult.net:8080/ambit2/feature/533748",
      :info => "http://apps.ideaconsult.net:8080/ambit2/dataset/435293?page=0&pagesize=300" }     
  @@files = { 
             File.new("data/hamster_carcinogenicity.csv") => :crossvalidation,  
             #File.new("data/hamster_carcinogenicity.mini.csv") => :crossvalidation,
             #File.new("data/EPAFHM.csv") => :crossvalidation,
             File.new("data/EPAFHM.mini.csv") => :crossvalidation,
             File.new("data/hamster_carcinogenicity.csv") => :split_validation,
             File.new("data/EPAFHM.csv") => :split_validation,
            #File.new("data/StJudes-HepG2-testset_Class.csv") => :crossvalidation
             }  
    
  def global_setup
    puts "login and upload datasets"
    if AA_SERVER
      @@subjectid = OpenTox::Authorization.authenticate(TEST_USER,TEST_PW)
      raise "could not log in" unless @@subjectid
      puts "logged in: "+@@subjectid.to_s
    else
      puts "AA disabled"
      @@subjectid = nil
    end
    @@files.each do |file,type|
      @@data << { :type => type,
        :data => ValidationTestUtil.upload_dataset(file, @@subjectid),
        :feat => ValidationTestUtil.prediction_feature_for_file(file),
        :info => file.path, :delete => true} 
    end
  end
  
  def global_teardown
    puts "delete and logout"
    if @@delete
      [:data, :train_data, :test_data].each do |d|
        @@data.each do |data| 
          OpenTox::Dataset.find(data[d],@@subjectid).delete(@@subjectid) if data[d] and data[:delete] and OpenTox::Dataset.exist?(data[d])
        end
      end
      @@vs.each{|v| v.delete(@@subjectid)} if defined?@@vs
      @@cvs.each{|cv| cv.delete(@@subjectid)} if defined?@@cvs
      @@reports.each{|report| report.delete(@@subjectid)} if defined?@@reports
      @@qmrfReports.each{|qmrfReport| qmrfReport.delete(@@subjectid)} if defined?@@qmrfReports
    end
    OpenTox::Authorization.logout(@@subjectid) if AA_SERVER
  end
  
  def test_validation_list
    puts "test_validation_list"
    list = OpenTox::Validation.list
    assert list.is_a?(Array)
    list.each do |l|
      assert l.uri?
    end
  end
 
  def test_training_test_split
    
    @@vs = [] unless defined?@@vs
    @@data.each do |data|
      if data[:type]==:split_validation
        puts "test_training_test_split "+data[:info].to_s
        p = { 
          :dataset_uri => data[:data],
          :algorithm_uri => File.join(CONFIG[:services]["opentox-algorithm"],"lazar"),
          :algorithm_params => "feature_generation_uri="+File.join(CONFIG[:services]["opentox-algorithm"],"fminer/bbrc"),
          :prediction_feature => data[:feat],
          :split_ratio => 0.95,
          :random_seed => 2}
        t = OpenTox::SubTask.new(nil,0,1)
        def t.progress(pct)
          if !defined?@last_msg or @last_msg+10<Time.new
            puts "waiting for training-test-split validation: "+pct.to_s
            @last_msg=Time.new
          end
        end
        def t.waiting_for(task_uri); end
        v = OpenTox::Validation.create_training_test_split(p, @@subjectid, t)
        assert v.uri.uri?
        if @@subjectid
          assert_rest_call_error OpenTox::NotAuthorizedError do
            OpenTox::Validation.find(v.uri)
          end
        end
        v = OpenTox::Validation.find(v.uri, @@subjectid)
        assert_valid_date v
        assert v.uri.uri?
        assert_prob_correct(v)
        model = v.metadata[OT.model]
        assert model.uri?
        v_list = OpenTox::Validation.list( {:model => model} )
        assert v_list.size==1 and v_list.include?(v.uri)
        puts v.uri unless @@delete
        @@vs << v
      end
    end
  end
  
  
  def test_training_test_validation
    
    @@vs = [] unless defined?@@vs
    @@data.each do |data|
      if data[:type]==:training_test_validation
        puts "test_training_test_validation "+data[:info].to_s
        p = { 
          :training_dataset_uri => data[:train_data],
          :test_dataset_uri => data[:test_data],
          :algorithm_uri => File.join(CONFIG[:services]["opentox-algorithm"],"lazar"),
          :algorithm_params => "feature_generation_uri="+File.join(CONFIG[:services]["opentox-algorithm"],"fminer/bbrc"),
          :prediction_feature => data[:feat]}
        t = OpenTox::SubTask.new(nil,0,1)
        def t.progress(pct)
          if !defined?@last_msg or @last_msg+10<Time.new
            puts "waiting for training-test-set validation: "+pct.to_s
            @last_msg=Time.new
          end
        end
        def t.waiting_for(task_uri); end
        v = OpenTox::Validation.create_training_test_validation(p, @@subjectid, t)
        assert v.uri.uri?
        if @@subjectid
          assert_rest_call_error OpenTox::NotAuthorizedError do
            OpenTox::Validation.find(v.uri)
          end
        end
        v = OpenTox::Validation.find(v.uri, @@subjectid)
        assert_valid_date v
        assert v.uri.uri?
        assert_prob_correct(v)
        model = v.metadata[OT.model]
        assert model.uri?
        v_list = OpenTox::Validation.list( {:model => model} )
        assert v_list.size==1 and v_list.include?(v.uri)
        puts v.uri unless @@delete
        @@vs << v
      end
    end
  end
  
  
  def test_validation_report
    #@@cv = OpenTox::Crossvalidation.find("http://local-ot/validation/crossvalidation/48", @@subjectid)
    
    @@reports = [] unless defined?@@reports
    @@vs.each do |v|
      puts "test_validation_report"
      assert defined?v,"no validation defined"
      assert_kind_of OpenTox::Validation,v
      if @@subjectid
        assert_rest_call_error OpenTox::NotAuthorizedError do
          OpenTox::ValidationReport.create(v.uri)
        end
      end
      report = OpenTox::ValidationReport.find_for_validation(v.uri,@@subjectid)
      assert_nil report,"report already exists for validation\nreport: "+(report ? report.uri.to_s : "")+"\nvalidation: "+v.uri.to_s
      params = {:min_confidence => 0.05}
      report = OpenTox::ValidationReport.create(v.uri,params,@@subjectid)
      assert report.uri.uri?
      if @@subjectid
        assert_rest_call_error OpenTox::NotAuthorizedError do
          OpenTox::ValidationReport.find(report.uri)
        end
      end
      report = OpenTox::ValidationReport.find(report.uri,@@subjectid)
      assert_valid_date report
      assert report.uri.uri?
      report2 = OpenTox::ValidationReport.find_for_validation(v.uri,@@subjectid)
      assert_equal report.uri,report2.uri
      report3_uri = v.find_or_create_report(@@subjectid)
      assert_equal report.uri,report3_uri
      puts report2.uri unless @@delete
      @@reports << report2
    end  
  end

  def test_crossvalidation_list
    puts "test_crossvalidation_list"
    list = OpenTox::Crossvalidation.list
    assert list.is_a?(Array)
    list.each do |l|
      assert l.uri?
    end
  end

  def test_crossvalidation
    
    #assert_rest_call_error OpenTox::NotFoundError do 
    #  OpenTox::Crossvalidation.find(File.join(CONFIG[:services]["opentox-validation"],"crossvalidation/noexistingid"))
    #end
    @@cvs = []
    @@cv_datasets = []
    @@cv_identifiers = []
    @@data.each do |data|
      if data[:type]==:crossvalidation
        @@hamster_cv_feature_types.each do |fminer|
          next unless (fminer==@@hamster_cv_feature_types[0] or data[:info].to_s =~ /hamster_carcinogenicity.csv/)
          puts "test_crossvalidation "+data[:info].to_s+" "+fminer
          p = { 
            :dataset_uri => data[:data],
            :algorithm_uri => File.join(CONFIG[:services]["opentox-algorithm"],"lazar"),
            :algorithm_params => "feature_generation_uri="+File.join(CONFIG[:services]["opentox-algorithm"],"fminer/"+fminer)+
             (data[:info] =~ /mini/ ? ";backbone=false;min_chisq_significance=0.0" : ""),
            :prediction_feature => data[:feat],
            :num_folds => 10 }
            #:num_folds => 2 }
          t = OpenTox::SubTask.new(nil,0,1)
          def t.progress(pct)
            if !defined?@last_msg or @last_msg+10<Time.new
              puts "waiting for crossvalidation: "+pct.to_s
              @last_msg=Time.new
            end
          end
          def t.waiting_for(task_uri); end
          cv = OpenTox::Crossvalidation.create(p, @@subjectid, t)
          assert cv.uri.uri?
          if @@subjectid
            assert_rest_call_error OpenTox::NotAuthorizedError do
              OpenTox::Crossvalidation.find(cv.uri)
            end
          end
          cv = OpenTox::Crossvalidation.find(cv.uri, @@subjectid)
          assert_valid_date cv
          assert cv.uri.uri?
          if @@subjectid
            assert_rest_call_error OpenTox::NotAuthorizedError do
              cv.statistics(cv)
            end
          end
          stats_val = cv.statistics(@@subjectid)
          assert_kind_of OpenTox::Validation,stats_val
          assert_prob_correct(stats_val)
          
          algorithm = cv.metadata[OT.algorithm]
          assert algorithm.uri?
          cv_list = OpenTox::Crossvalidation.list( {:algorithm => algorithm} )
          assert cv_list.include?(cv.uri)
          cv_list.each do |cv_uri|
            begin
              alg = OpenTox::Crossvalidation.find(cv_uri, @@subjectid).metadata[OT.algorithm]
              assert alg==algorithm,"wrong algorithm for filtered crossvalidation, should be: '"+algorithm.to_s+"', is: '"+alg.to_s+"'"
            rescue OpenTox::RestCallError => e
              raise "error Report of RestCallError is no errorReport: "+e.errorCause.class.to_s+":\n"+e.errorCause.to_yaml  unless e.errorCause.is_a?(OpenTox::ErrorReport)
              report = e.errorCause
              while report.errorCause
                report = report.errorCause
              end
              assert_equal report.errorType,OpenTox::NotAuthorizedError.to_s
            end
          end
          puts cv.uri unless @@delete
          
          @@cvs << cv
          @@cv_datasets << data
          @@cv_identifiers << fminer
        end
      end
    end
  end
    
  def test_crossvalidation_report
    #@@cv = OpenTox::Crossvalidation.find("http://local-ot/validation/crossvalidation/48", @@subjectid)
    
    @@reports = [] unless defined?@@reports
    @@cvs.each do |cv|
      puts "test_crossvalidation_report"
      assert defined?cv,"no crossvalidation defined"
      assert_kind_of OpenTox::Crossvalidation,cv
      #assert_rest_call_error OpenTox::NotFoundError do 
      #  OpenTox::CrossvalidationReport.find_for_crossvalidation(cv.uri)
      #end
      if @@subjectid
        assert_rest_call_error OpenTox::NotAuthorizedError do
          OpenTox::CrossvalidationReport.create(cv.uri)
        end
      end
      assert OpenTox::CrossvalidationReport.find_for_crossvalidation(cv.uri,@@subjectid)==nil
      report = OpenTox::CrossvalidationReport.create(cv.uri,@@subjectid)
      assert report.uri.uri?
      if @@subjectid
        assert_rest_call_error OpenTox::NotAuthorizedError do
          OpenTox::CrossvalidationReport.find(report.uri)
        end
      end
      report = OpenTox::CrossvalidationReport.find(report.uri,@@subjectid)
      assert_valid_date report
      assert report.uri.uri?
      report2 = OpenTox::CrossvalidationReport.find_for_crossvalidation(cv.uri,@@subjectid)
      assert_equal report.uri,report2.uri
      report3_uri = cv.find_or_create_report(@@subjectid)
      assert_equal report.uri,report3_uri
      puts report2.uri unless @@delete
      @@reports << report2
    end  
  end
  
  def test_crossvalidation_compare_report
    @@reports = [] unless defined?@@reports
    @@cvs.size.times do |i|
      @@cvs.size.times do |j|
        if j>i and @@cv_datasets[i]==@@cv_datasets[j]
          puts "test_crossvalidation_compare_report"
          assert_kind_of OpenTox::Crossvalidation,@@cvs[i]
          assert_kind_of OpenTox::Crossvalidation,@@cvs[j]
          hash = { @@cv_identifiers[i] => [@@cvs[i].uri],
                   @@cv_identifiers[j] => [@@cvs[j].uri] }
          if @@subjectid
            assert_rest_call_error OpenTox::NotAuthorizedError do
              OpenTox::AlgorithmComparisonReport.create hash,@@subjectid
            end
          end
          assert OpenTox::AlgorithmComparisonReport.find_for_crossvalidation(@@cvs[i].uri,@@subjectid)==nil
          assert OpenTox::AlgorithmComparisonReport.find_for_crossvalidation(@@cvs[j].uri,@@subjectid)==nil
          
          params = {:ttest_significance => 0.95, :ttest_attributes => "real_runtime,percent_unpredicted", :max_num_predictions => 5}
          report = OpenTox::AlgorithmComparisonReport.create hash,params,@@subjectid
          assert report.uri.uri?
          if @@subjectid
            assert_rest_call_error OpenTox::NotAuthorizedError do
              OpenTox::AlgorithmComparisonReport.find(report.uri)
            end
          end
          report = OpenTox::AlgorithmComparisonReport.find(report.uri,@@subjectid)
          assert_valid_date report
          assert report.uri.uri?
          report2 = OpenTox::AlgorithmComparisonReport.find_for_crossvalidation(@@cvs[i].uri,@@subjectid)
          assert_equal report.uri,report2.uri
          report3 = OpenTox::AlgorithmComparisonReport.find_for_crossvalidation(@@cvs[j].uri,@@subjectid)
          assert_equal report.uri,report3.uri
          puts report2.uri unless @@delete
          @@reports << report2 
        end
      end
    end
  end
  
  if @@qmrf_test
   def test_qmrf_report
    #@@cv = OpenTox::Crossvalidation.find("http://local-ot/validation/crossvalidation/13", @@subjectid)
   
      @@qmrfReports = []
      @@cvs.each do |cv|
        puts "test_qmrf_report"
        assert defined?cv,"no crossvalidation defined"
        assert cv.metadata[OT.validation].is_a?(Array)
        assert cv.metadata[OT.validation].first.uri?
        validation = OpenTox::Validation.find(cv.metadata[OT.validation].first, @@subjectid)
        prediction_feature_uri = validation.metadata[OT.predictionFeature]
        assert prediction_feature_uri.uri?
        model_uri = OpenTox::Algorithm::Lazar.new.run({:dataset_uri => cv.metadata[OT.dataset], :prediction_feature => prediction_feature_uri,
          :subjectid => @@subjectid}).to_s
        assert model_uri.uri?
        # test search in cvs with model uri
        cv_uris = OpenTox::RestClientWrapper.get(File.join(CONFIG[:services]["opentox-validation"],"/crossvalidation?model="+model_uri),
          {:subjectid =>  @@subjectid}).chomp.split("\n")
        assert cv_uris.size>0 and cv_uris.include?(cv.uri)
  #      validations = cv.metadata[OT.validation]
  #      assert_kind_of Array,validations
  #      assert validations.size==cv.metadata[OT.numFolds].to_i,validations.size.to_s+"!="+cv.metadata[OT.numFolds].to_s
  #      val = OpenTox::Validation.find(validations[0], @@subjectid)
  #      model_uri = val.metadata[OT.model]
        model = OpenTox::Model::Generic.find(model_uri, @@subjectid)
        assert model!=nil
        #assert_rest_call_error OpenTox::NotFoundError do 
        #  OpenTox::QMRFReport.find_for_model(model_uri, @@subjectid)
        #end
        qmrfReport = OpenTox::QMRFReport.create(model_uri, @@subjectid)
        # test search in qmrf reports with model uri        
        qmrf_uris = OpenTox::RestClientWrapper.get(File.join(CONFIG[:services]["opentox-validation"],"/reach_report/QMRF?model="+model_uri),
          {:subjectid =>  @@subjectid}).chomp.split("\n")
        assert qmrf_uris.size==1 and qmrf_uris[0]==qmrfReport.uri
        puts qmrfReport.uri unless @@delete
        @@qmrfReports << qmrfReport
      end
    end
    
  end
  
  ################### utils and overrides ##########################
  
  def app
    Sinatra::Application
  end
  
  # checks RestCallError type
  def assert_rest_call_error( ex )
    if ex==OpenTox::NotAuthorizedError and @@subjectid==nil
      puts "AA disabled: skipping test for not authorized"
      return
    end
    begin
      yield
      assert false,"no rest-call error thrown"
    rescue OpenTox::RestCallError => e
      raise "error Report of RestCallError is no errorReport: "+e.errorCause.class.to_s+":\n"+e.errorCause.to_yaml  unless e.errorCause.is_a?(OpenTox::ErrorReport)
      report = e.errorCause
      while report.errorCause
        report = report.errorCause
      end
      assert_equal report.errorType,ex.to_s
    end
  end
  
  # checks if opento_object has date defined in metadata, and time is less than max_time seconds ago
  def assert_valid_date( opentox_object, max_time=600 )
    
    raise "no opentox object" unless opentox_object.class.to_s.split("::").first=="OpenTox"
    assert opentox_object.metadata.is_a?(Hash)
    assert opentox_object.metadata[DC.date].to_s.length>0,"date not set for "+opentox_object.uri.to_s+", is metadata loaded? (use find)"
    time = Time.parse(opentox_object.metadata[DC.date])
    assert time!=nil
=begin    
    assert time<Time.new,"date of "+opentox_object.uri.to_s+" is in the future: "+time.to_s
    assert time>Time.new-(10*60),opentox_object.uri.to_s+" took longer than 10 minutes "+time.to_s
=end
  end

  def assert_prob_correct( validation )
    class_stats = validation.metadata[OT.classificationStatistics]
    if class_stats != nil
      class_value_stats = class_stats[OT.classValueStatistics]
      class_value_stats.each do |cs|
        #puts cs[OT.positivePredictiveValue]
        #puts validation.probabilities(0,cs[OT.classValue]).inspect
        assert cs[OT.positivePredictiveValue]==validation.probabilities(0,cs[OT.classValue],@@subjectid)[:probs][cs[OT.classValue]]
      end
    end
  end
  
  # hack to have a global_setup and global_teardown 
  def teardown
    if((@@expected_test_count-=1) == 0)
      global_teardown
    end
  end
  def setup
    unless defined?@@expected_test_count
      @@expected_test_count = (self.class.instance_methods.reject{|method| method[0..3] != 'test'}).length
      global_setup
    end
  end

end

