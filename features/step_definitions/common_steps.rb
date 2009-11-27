Given /^Content-Type is (.*)/ do |content_type|
	@content_type = content_type
end

When /^I post (.*) to the (.*) webservice$/ do |data,component|
	#puts @@config[:services]["opentox-#{component}"]
	case data
	when /^file:/
		data = File.read(File.join(File.dirname(File.expand_path(__FILE__)),"../data",data.sub(/file:\s+/,'')))
		@data = data
	end
	@uri = RestClient.post @@config[:services]["opentox-#{component}"], data, :content_type => @content_type
	@resources << @uri unless /compound|feature/ =~ component
end

Then /^I should receive a valid URI$/ do
	@response = RestClient.get @uri
	#puts @response
end

Then /^the URI should contain (.+)$/ do |result|
	#puts @uri
	regexp = /#{Regexp.escape(URI.encode(result))}/
	assert regexp =~ @uri, true
end

Then /^the URI response should be (.+)$/ do |data|
	case data
	when /^file:/
		data = @data
	end
	assert data == @response, true
end

