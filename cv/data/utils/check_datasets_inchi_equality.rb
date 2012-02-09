require 'rubygems'
require 'opentox-ruby'
require 'yaml'

@subjectid = nil



def check_ds(t_ds_uri, f_ds_uri)
  puts t_ds_uri
  puts f_ds_uri

  regression_training_dataset = OpenTox::Dataset.find(t_ds_uri, @subjectid)
  regression_feature_dataset = OpenTox::Dataset.find(f_ds_uri, @subjectid)

  train_ds = regression_training_dataset.data_entries.keys
  train_cmds = regression_training_dataset.compounds
  feature_ds = regression_feature_dataset.data_entries.keys
  feature_cmds = regression_feature_dataset.compounds

  puts "----- Check activity inchi -----"
  match=0
  mismatch=0
  train_ds.each { |i| 
    if feature_ds.include?(i)
      match = match + 1
    else
      mismatch = mismatch + 1
    end
  }
  if  mismatch > 0
    puts "NOT all training compounds represented in feature dataset!!!" unless mismatch > 0
    puts "match: #{match}; and mismatch: !!!!!#{mismatch}!!!!!"
  else
    puts "All training compounds represented in feature dataset." unless mismatch > 0
    puts "match: #{match};    mismatch: #{mismatch}"
    puts "OK!!!"
  end
  
  train_ds.sort!          
  feature_ds.sort!        
                          
  if train_ds == feature_ds
    puts "train_ds == feature_ds"
  else                    
    a = train_ds - feature_ds
    #puts "d: '#{a}'"
    puts "train_ds: " + train_ds.size.to_s + ";     feature_ds: "+ feature_ds.size.to_s
    puts "train_ds =NOT feature_ds"
  end



  puts "----- Check compound inchi -----"
  match=0
  mismatch=0
  train_cmds.each { |i|
    if feature_cmds.include?(i)
      match = match + 1
    else
      mismatch = mismatch + 1
    end
  }
  if  mismatch > 0
    puts "NOT all training compounds represented in feature dataset!!!" unless mismatch > 0
    puts "match: #{match}; and mismatch: !!!!!#{mismatch}!!!!!"
  else
    puts "All training compounds represented in feature dataset." unless mismatch > 0
    puts "match: #{match};    mismatch: #{mismatch}"
    puts "OK!!!"
  end



  feature_cmds.sort!      
  train_cmds.sort!        

  if train_cmds == feature_cmds
    puts "train_cmds == feature_cmds"
  else
    b = train_cmds - feature_cmds
    #puts "d: '#{b}'"
    puts "train_cmds: " + train_cmds.size.to_s + ";     feature_cmds: " + feature_cmds.size.to_s
    puts "train_cmds =NOT feature_cmds"
  end 
  puts
end




ds = YAML::load_file("../datasets.yaml")
ds.keys.each { |dataset|
  ds[dataset].keys.each { |pc|
    puts pc
    check_ds(ds[dataset]["dataset"], ds[dataset][pc])
  }
}
