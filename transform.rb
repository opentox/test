require 'rubygems'
require 'opentox-ruby'
require 'test/unit'

class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end
end

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
  
    d = GSL::Matrix.alloc([1.0, -5, 1.1, 2.0, -5, 1.9, 3.0, -5, 3.3], 3, 3) # 2nd col is const -5, gets removed
    rd = GSL::Matrix.alloc([1.0, 1.1, 1.9, 2.0, 3.1, 3.2], 3, 2)
    td = GSL::Matrix.alloc([-1.4142135623731, -0.14142135623731, 1.5556349186104],3,1)
    ev = GSL::Matrix.alloc([0.707106781186548, 0.707106781186548], 2, 1)
  
    # Lossy
    2.times do # repeat to ensure idempotency
      pca = OpenTox::Transform::PCA.new(d, 0.05)
      assert_equal pca.data_matrix, d
      assert_equal pca.data_transformed_matrix, td
      assert_equal pca.transform(d), td
      assert_equal pca.eigenvector_matrix, ev
      assert_equal pca.restore, rd
    end
  
    rd = GSL::Matrix.alloc([1.0, 1.1, 2.0, 1.9, 3.0, 3.3], 3, 2) # 2nd col of d is const -5, gets removed on rd
    td = GSL::Matrix.alloc([-1.4142135623731, -7.84962372879505e-17, -0.14142135623731, -0.14142135623731, 1.5556349186104, 0.141421356237309],3,2)
    ev = GSL::Matrix.alloc([0.707106781186548, -0.707106781186548, 0.707106781186548, 0.707106781186548], 2, 2)
  
    # Lossless
    2.times do
      pca = OpenTox::Transform::PCA.new(d, 0.0)
      assert_equal pca.data_matrix, d
      assert_equal pca.data_transformed_matrix, td
      assert_equal pca.transform(d), td
      assert_equal pca.eigenvector_matrix, ev
      assert_equal pca.restore, rd
    end

    rd = GSL::Matrix.alloc([1.0, 1.1, 1.9, 2.0, 3.1, 3.2], 3, 2)
    td = GSL::Matrix.alloc([-1.4142135623731, -0.14142135623731, 1.5556349186104],3,1)
    ev = GSL::Matrix.alloc([0.707106781186548, 0.707106781186548], 2, 1)
    # Lossy, but using maxcols constraint
    2.times do
      pca = OpenTox::Transform::PCA.new(d, 0.0, 1) # 1 column
      assert_equal pca.data_matrix, d
      assert_equal pca.data_transformed_matrix, td
      assert_equal pca.transform(d), td
      assert_equal pca.eigenvector_matrix, ev
      assert_equal pca.restore, rd
    end
  
  
  end

  def test_svd

    m = GSL::Matrix[
            [5,5,0,5],
            [5,0,3,4],
            [3,4,0,3],
            [0,0,5,3],
            [5,4,4,5],
            [5,4,5,5] 
     ]
     svd = OpenTox::Algorithm::Transform::SVD.new m

     foo = svd.transform_feature GSL::Matrix[[5,5,3,0,5,5]]
     sim = []
     svd.vk.each_row { |x|
       sim << OpenTox::Algorithm::Similarity.cosine_num(x,foo.row(0))
     }
     assert_equal sim[0].round_to(3), 1.000
     assert_equal sim[1].round_to(3), 0.874
     assert_equal sim[2].round_to(3), 0.064
     assert_equal sim[3].round_to(3), 0.895

     bar = svd.transform_instance GSL::Matrix[[5,4,5,5]]
     sim = []
     svd.uk.each_row { |x|
       sim << OpenTox::Algorithm::Similarity.cosine_num(x,bar.row(0))
     }

     assert_equal sim[0].round_to(3), 0.346
     assert_equal sim[1].round_to(3), 0.966
     assert_equal sim[2].round_to(3), 0.282
     assert_equal sim[3].round_to(3), 0.599
     assert_equal sim[4].round_to(3), 0.975
     assert_equal sim[5].round_to(3), 1.000 
  end
  
  def test_logas
  
    d1 = [ 1,2,3 ].to_gv
    d2 = [ -1,0,1 ].to_gv
    d3 = [ -2,3,8 ].to_gv
    d4 = [ -20,30,80 ].to_gv
    d5 = [ 0.707, 0.7071].to_gv

    d1la = [ -1.31668596949013, 0.211405021140643, 1.10528094834949 ].to_gv
    d2la = d1la
    d3la = [ -1.37180016053906, 0.388203523926062, 0.983596636612997 ].to_gv
    d4la = [ -1.40084731572532, 0.532435269814955, 0.868412045910369 ].to_gv
    d5la = [ -1.0, 1.0 ].to_gv

    2.times {

      logas = OpenTox::Transform::LogAutoScale.new(d1)
      assert_equal logas.vs, d1la
      assert_equal logas.restore(logas.vs), d1
  
      logas = OpenTox::Transform::LogAutoScale.new(d2)
      assert_equal logas.vs, d2la
      assert_equal logas.restore(logas.vs), d2

      logas = OpenTox::Transform::LogAutoScale.new(d3)
      assert_equal logas.vs, d3la
      assert_equal logas.restore(logas.vs), d3
  
      logas = OpenTox::Transform::LogAutoScale.new(d4)
      assert_equal logas.vs, d4la
      assert_equal logas.restore(logas.vs), d4

      logas = OpenTox::Transform::LogAutoScale.new(d5)
      assert_equal logas.vs, d5la
      assert_equal logas.restore(logas.vs), d5
  
    }
 
  end

end
