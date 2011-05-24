require "rubygems"
require "opentox-ruby"
require "test/unit"

TEST_URI    = "http://only_a_test/test/" + rand(1000000).to_s
USER_TYPE   = "LDAPUsers"
USER_NAME   = "guest"
USER_VALUE  = "uid=guest,ou=people,dc=opentox,dc=org"
USER_GROUP  = "member"
GROUP_TYPE  = "LDAPGroups"
GROUP_VALUE = "cn=member,ou=groups,dc=opentox,dc=org"
POLICY_NAME = "test_policy_#{rand(100000)}"
RULE_NAME = "test_rule_#{rand(100000)}"
SUBJECT_NAME = "test_subject_#{rand(100000)}"

unless AA_SERVER #overwrite turned off A&A server for testing
  AA_SERVER = "https://opensso.in-silico.ch"
  @@subjectid = OpenTox::Authorization.authenticate(TEST_USER,TEST_PW)
end

class PolicyTest < Test::Unit::TestCase
 
  def test_01_class
    policies = OpenTox::Policies.new()
    assert_equal(policies.class, OpenTox::Policies)
    assert_kind_of Array, policies.names
    assert_kind_of Array, policies.uris
    assert_kind_of Array, policies.names
  end

  def test_02_subclasses
    policies = OpenTox::Policies.new()
    policies.new_policy(POLICY_NAME)
    assert_equal(policies.names[0], POLICY_NAME)
    assert_equal(policies.policies[policies.names[0]].class, OpenTox::Policy)
    policy = policies.policies[policies.names[0]]
    policy.rule.name = RULE_NAME
    policy.uri = TEST_URI
    assert_equal(policy.rule.class, OpenTox::Policy::Rule)
    assert_equal(policy.rule.name, RULE_NAME)
    assert_equal(policy.rule.uri, TEST_URI)
    assert_equal(policy.uri, TEST_URI)    
    policy.subject.name = SUBJECT_NAME
    policy.type = USER_TYPE
    policy.value = USER_VALUE
    assert_equal(policy.subject.class, OpenTox::Policy::Subject)
    assert_equal(policy.subject.name, SUBJECT_NAME)
    assert_equal(policy.subject.type, USER_TYPE)
    assert_equal(policy.type, USER_TYPE)
    assert_equal(policy.subject.value, USER_VALUE)
    assert_equal(policy.value, USER_VALUE)
  end
 
  def test_03_read_readwrite
    policies = OpenTox::Policies.new()
    policies.new_policy(POLICY_NAME)
    policy = policies.policies[policies.names[0]]
    policy.rule.name = RULE_NAME
    policy.uri = TEST_URI
    policy.rule.get = "allow"
    assert policy.rule.read
    assert !policy.rule.readwrite
    policy.rule.post = "allow"
    policy.rule.put = "allow"
    assert !policy.rule.read
    assert policy.rule.readwrite
    policy.rule.read = true
  end

  def test_04_group_user
    policies = OpenTox::Policies.new()
    policies.load_default_policy(TEST_USER, TEST_URI, "member")
    assert_equal "member", policies.policies["policy_group"].group
    assert_equal TEST_USER, policies.policies["policy_user"].user    
  end

  def test_05_DN
    policies = OpenTox::Policies.new()
    policies.new_policy(POLICY_NAME)
    policy = policies.policies[policies.names[0]]
    policy.set_ot_user(USER_NAME)
    assert_equal USER_VALUE, policy.value
    assert_equal USER_TYPE, policy.type  
    policy.set_ot_group(USER_GROUP)
    assert_equal GROUP_VALUE, policy.value 
    assert_equal GROUP_TYPE, policy.type
    
  end

end



#p= OpenTox::Policies.new()
#p.load_xml(xml)
#p.names
#p.policies[p.names[0]] 