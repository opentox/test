require 'rubygems'
require 'test/unit'

module TestUtil
  
  def dataset_equal(d,d2)
    assert d.compounds.sort==d2.compounds.sort,
      d.compounds.sort.to_yaml+"\n!=\n"+d2.compounds.sort.to_yaml
    assert d.features.keys.size==d2.features.keys.size,
      d.features.keys.to_yaml+"\n!=\n"+d2.features.keys.to_yaml
    assert d.features.keys.sort==d2.features.keys.sort,
      d.features.keys.sort.to_yaml+"\n!=\n"+d2.features.keys.sort.to_yaml
    d.compounds.each do |c|
      d.features.keys.each do |f|
        assert_array_about_equal d.data_entries[c][f],d2.data_entries[c][f]
      end
    end
  end
  
  def assert_array_about_equal(a,a2)
    if (a!=nil || a2!=nil)
      raise "no arrays #{a.class} #{a2.class}" unless a.is_a?(Array) and a2.is_a?(Array)
      assert a.size==a2.size
      a.sort! 
      a2.sort!
      a.size.times do |i|
        if (a[i].is_a?(Float) and a2[i].is_a?(Float))
          assert (a[i]-a2[i]).abs<0.0000001,"#{a[i]}(#{a[i].class}) != #{a2[i]}(#{a2[i].class})"
        else
          assert a[i]==a2[i],"#{a[i]}(#{a[i].class}) != #{a2[i]}(#{a2[i].class})"
        end
      end
    end
  end
  
end