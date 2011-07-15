require 'rubygems'
require 'opentox-ruby'
require 'test/unit'


class TransformTest < Test::Unit::TestCase


  def test_pca

    d = GSL::Matrix.alloc([1,1.1,2,1.9,3,3.3], 3, 2)
    td = GSL::Matrix.alloc([-1.3421074161875, -0.127000127000191, 1.46910754318769],3,1)
    ev = GSL::Matrix.alloc([0.707106781186548, 0.707106781186548], 2, 1)
    rd = GSL::Matrix.alloc([1.05098674493306, 1.043223563717, 1.91019734898661, 2.0, 3.03881590608033, 3.256776436283], 3, 2)

    # Lossy
    2.times do # repeat to ensure idempotency
      pca = OpenTox::Algorithm::Transform::PCA.new(d, 0.05)
      assert_equal pca.data_matrix, d
      assert_equal pca.data_transformed_matrix, td
      assert_equal pca.eigenvector_matrix, ev
      assert_equal pca.restore, rd
    end

    td = GSL::Matrix.alloc([-1.3421074161875, 0.0721061461855949, -0.127000127000191, -0.127000127000191, 1.46910754318769, 0.0548939808145955],3,2)
    ev = GSL::Matrix.alloc([0.707106781186548, -0.707106781186548, 0.707106781186548, 0.707106781186548], 2, 2)

    # Lossless
    2.times do
      pca = OpenTox::Algorithm::Transform::PCA.new(d, 0.0)
      assert_equal pca.data_matrix, d
      assert_equal pca.data_transformed_matrix, td
      assert_equal pca.eigenvector_matrix, ev
      assert_equal pca.restore, d
    end

  end

end
