
require 'test/unit'

  class ValidationTestUtil    
    
    @@dataset_uris = {}
    @@prediction_features = {}

    def self.upload_dataset(file, subjectid=nil, dataset_service=CONFIG[:services]["opentox-dataset"]) #, file_type="application/x-yaml")
      raise "File not found: "+file.path.to_s unless File.exist?(file.path)
      if @@dataset_uris[file.path.to_s]==nil
        LOGGER.debug "uploading file: "+file.path.to_s
        if (file.path =~ /yaml$/)
          data = File.read(file.path)
          #data_uri = OpenTox::RestClientWrapper.post(dataset_service,{:content_type => file_type},data).to_s.chomp
          #@@dataset_uris[file.path.to_s] = data_uri
          #LOGGER.debug "uploaded dataset: "+data_uri
          d = OpenTox::Dataset.create(CONFIG[:services]["opentox-dataset"], subjectid)
          d.load_yaml(data)
          d.save( subjectid )
          @@dataset_uris[file.path.to_s] = d.uri
        elsif (file.path =~ /csv$/)
          d = OpenTox::Dataset.create_from_csv_file(file.path, subjectid)
          raise "num features not 1 (="+d.features.keys.size.to_s+"), what to predict??" if d.features.keys.size != 1
          @@prediction_features[file.path.to_s] = d.features.keys[0]
          @@dataset_uris[file.path.to_s] = d.uri
        elsif (file.path =~ /rdf$/)
          d = OpenTox::Dataset.create(CONFIG[:services]["opentox-dataset"], subjectid)
          d.load_rdfxml_file(file, subjectid)
          d.save(subjectid)
          @@dataset_uris[file.path.to_s] = d.uri
        else
          raise "unknown file type: "+file.path.to_s
        end
        LOGGER.debug "uploaded dataset: "+d.uri
      else
        LOGGER.debug "file already uploaded: "+@@dataset_uris[file.path.to_s]
      end
      return @@dataset_uris[file.path.to_s]
    end
    
    def self.prediction_feature_for_file(file)
      @@prediction_features[file.path.to_s]
    end

  end
