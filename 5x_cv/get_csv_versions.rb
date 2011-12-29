require 'yaml'
ds = YAML::load_file("datasets_nestle.yaml")
ds.keys.each { |d| puts d ; ds[d].keys.each {|t| puts "  #{t}"; cmd = "  curl -H 'accept:text/csv' #{ds[d][t]} > #{d}_#{t}.csv" unless t=="dataset"; puts cmd } }
