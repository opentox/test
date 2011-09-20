require "rubygems"
require "opentox-ruby"
require "test/unit"

unless AA_SERVER #overwrite turned off A&A server for testing
  AA_SERVER = "https://opensso.in-silico.ch"
  @@subjectid = OpenTox::Authorization.authenticate(TEST_USER,TEST_PW)
end

class TestOpenToxOntology < Test::Unit::TestCase
 
  def test_01_register_model
    uri = OpenTox::Model::Lazar.all.last
    puts uri
    OpenTox::Ontology::Model.register(uri, @@subjectid)
    assert_equal(true, OpenTox::Ontology::Model.exists?(uri, @@subjectid))
  end

  def test_02_delete_model
    uri = OpenTox::Model::Lazar.all.last
    puts uri
    OpenTox::Ontology::Model.delete(uri, @@subjectid)
    assert_equal(false, OpenTox::Ontology::Model.exists?(uri, @@subjectid))
  end

end