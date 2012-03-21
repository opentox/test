require 'rubygems'
require 'opentox-ruby'
require 'yaml'

@subjectid = nil

if ARGV.size != 1
  puts "Args: path/to/dataset.yaml"
  puts ARGV.size
  exit
end

path = ARGV[0]
puts path
ds = YAML::load_file("#{path}")
#ds.keys.each { |dataset|
["LOAEL"].each { |dataset|
  puts "----------------- next dataset -----------------"
  ["electronic,cpsa,constitutional,topological,hybrid,joelib"].each { |pc|
    puts "#{dataset}, #{pc}"

    args = {}
    args[:pc_type] = pc
    ds_uri = ds[dataset]["dataset"]

    puts args.to_yaml

    feature_ds = OpenTox::RestClientWrapper.post( File.join(ds_uri,"/pcdesc"), args )
    puts "Result feature dataset:" 
    puts feature_ds
    puts "--------" 
  }
  puts "-----------------" 
}
