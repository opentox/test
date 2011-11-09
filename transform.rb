require 'rubygems'
require 'opentox-ruby'
require 'test/unit'


class TransformTest < Test::Unit::TestCase

  #def test_mlr
  #  2.times {
  #    n_prop = [ [1,1], [2,2], [3,3] ] # erste WH
  #    acts = [ 3,2,3 ]   # should yield a constant y=2.8
  #    sims = [ 4,2,4 ]   # move constant closer to 3.0
  #    q_prop = [0.5,0.5] # extrapolation
  #    params={:n_prop => n_prop, :q_prop => q_prop, :sims => sims, :acts => acts}
  #
  #    prediction = OpenTox::Algorithm::Neighbors.mlr(params)
  #    assert_in_delta prediction, 2.8, 1.0E-10 # small deviations, don't know why
  #
  #    q_prop = [1.5,1.5] # interpolation
  #    prediction = OpenTox::Algorithm::Neighbors.mlr(params)
  #    assert_in_delta prediction, 2.8, 1.0E-10 # small deviations, don't know why
  #  }
  #end
  
  def test_pca
  
    d = GSL::Matrix.alloc([1,1.1,2,1.9,3,3.3], 3, 2)
    td = GSL::Matrix.alloc([-1.64373917483226, -0.155542754209564, 1.79928192904182],3,1)
    ev = GSL::Matrix.alloc([0.707106781186548, 0.707106781186548], 2, 1)
    rd = GSL::Matrix.alloc([1.05098674493306, 1.043223563717, 1.91019734898661, 2.0, 3.03881590608033, 3.256776436283], 3, 2)
  
    # Lossy
    2.times do # repeat to ensure idempotency
      pca = OpenTox::Transform::PCA.new(d, 0.05)
      assert_equal pca.data_matrix, d
      assert_equal pca.data_transformed_matrix, td
      assert_equal pca.transform(d), td
      assert_equal pca.eigenvector_matrix, ev
      assert_equal pca.restore, rd
    end
  
    td = GSL::Matrix.alloc([-1.64373917483226, 0.0883116327366195, -0.155542754209564, -0.155542754209564, 1.79928192904182, 0.0672311214729441],3,2)
    ev = GSL::Matrix.alloc([0.707106781186548, -0.707106781186548, 0.707106781186548, 0.707106781186548], 2, 2)
  
    # Lossless
    2.times do
      pca = OpenTox::Transform::PCA.new(d, 0.0)
      assert_equal pca.data_matrix, d
      assert_equal pca.data_transformed_matrix, td
      assert_equal pca.transform(d), td
      assert_equal pca.eigenvector_matrix, ev
      assert_equal pca.restore, d
    end
  
  end
  
  def test_logas
  
    d1 = [ 1,2,3 ]
    d2 = [ -1,0,1 ]
    d3 = [ -2,3,8 ]
    d4 = [ -20,30,80 ]


    2.times {

      logas = OpenTox::Transform::LogAutoScale.new(d1)
      d1la = logas.vs
      d1la.each_with_index { |v,i| 
        assert_in_delta v, [ -1.31668596949013, 0.211405021140643, 1.10528094834949 ][i], 1.0E-10
      }
      assert_equal logas.transform(d1), d1la
      logas.restore(d1la).each_with_index { |v,i|
        assert_in_delta v, d1[i], 1.0E-10
      }
  
      logas = OpenTox::Transform::LogAutoScale.new(d2)
      d2la = logas.vs
      assert_equal d2la, d1la
      assert_equal logas.transform(d2), d2la
      logas.restore(d2la).each_with_index { |v,i|
        assert_in_delta v, d2[i], 1.0E-10
      }
  
      logas = OpenTox::Transform::LogAutoScale.new(d3)
      d3la = logas.vs
      d3la.each_with_index { |v,i|
        assert_in_delta v, [ -1.37180016053906, 0.388203523926062, 0.983596636612997 ][i], 1.0E-10
      }
      assert_equal logas.transform(d3), d3la
      logas.restore(d3la).each_with_index { |v,i|
        assert_in_delta v, d3[i], 1.0E-10
      }
   
      logas = OpenTox::Transform::LogAutoScale.new(d4)
      d4la = logas.vs
      d4la.each_with_index { |v,i|
        assert_in_delta v, [ -1.40084731572532, 0.532435269814955, 0.868412045910369 ][i], 1.0E-10
      }
      assert_equal logas.transform(d4), d4la
      logas.restore(d4la).each_with_index { |v,i|
        assert_in_delta v, d4[i], 1.0E-10
      }

    }
 
  end

end
