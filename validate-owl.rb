def validate_owl(uri, subjectid=nil)
  if validator_available?
    owl = OpenTox::RestClientWrapper.get(uri,{:accept => "application/rdf+xml",:subjectid => subjectid}, nil, false)
    html = OpenTox::RestClientWrapper.post("http://www.mygrid.org.uk/OWL/Validator",{:rdf => owl, :level => "DL",:subjectid => subjectid})
    # assert_match(/YES/,html)
    # avoid verbose html output if validation fails
    owl_dl = false
    owl_dl = true if html =~ /YES/
    assert_equal true, owl_dl, "Invalid OWL-DL: #{uri}"
  else
    puts "http://www.mygrid.org.uk/OWL/Validator offline"
  end
end

def validator_available?
  uri = URI.parse "http://www.mygrid.org.uk/OWL/Validator"
  Net::HTTP.start(uri.host, uri.port) do |http| 
    begin
      http.read_timeout = 5
      http.head(uri.path).code == '200' 
    rescue Timeout::Error
      false
    end
  end
end
