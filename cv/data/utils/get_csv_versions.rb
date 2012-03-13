require 'yaml'
ds = YAML::load_file("../datasets.yaml")
ds.keys.each { |d| puts d ; ds[d].keys.each {|t| puts "  #{t}"; cmd = "  curl -H 'accept:text/csv' #{ds[d][t]} > csv_file; mv -v --backup=numbered csv_file #{d}_#{t.gsub(/,/, '_')}.csv" unless t=="dataset"; puts cmd } }
