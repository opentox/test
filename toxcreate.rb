require 'rubygems'
require "rubygems"
require 'opentox-ruby'
require 'test/unit'
require 'akephalos'
require 'capybara/dsl'
require 'capybara/envjs'

Capybara.default_driver = :akephalos # use this without visual inspection
#Capybara.default_driver = :selenium # use this for visual inspection
Capybara.run_server = false
Capybara.default_wait_time = 1000
Capybara.javascript_driver = :envjs

class ToxCreateTest < Test::Unit::TestCase
  include Capybara

  def setup
    @user = "guest"
    @password = "guest"
  end

  def teardown
    #puts Time.now.localtime.strftime("%Y-%m-%d %H:%M:%S")
    sleep 5
  end

=begin
  def test_01_login
    visit File.join(CONFIG[:services]["opentox-toxcreate"], "login")
    click_on "Login"
    puts "Login without credentials"    
    assert page.has_content? "Please enter username and password."
    fill_in('Username', :with => @user)
    fill_in('Password', :with => @password + "nonsense")
    click_on "Login"
    puts "Login with wrong password"
    assert page.has_content? "Login failed. Please try again." 
    fill_in('Username', :with => @user)
    fill_in('Password', :with => @password)
    click_on "Login"
    assert page.has_content? "Welcome #{@user}!"
    visit File.join(CONFIG[:services]["opentox-toxcreate"], "login")
    click_on "Login as guest"
    puts "Login as user guest"    
    assert page.has_content? "Welcome guest!"
  end
=end
  def test_02_toxcreate # works only with akephalos
    Capybara.current_driver = :akephalos 
    #login(@browser, @user, @password)
    visit CONFIG[:services]["opentox-toxcreate"]
    assert page.has_content?('Upload training data')
    attach_file('file', "./data/hamster_carcinogenicity.mini.csv")
    click_on "Create model"
    assert first("h2").has_content? "hamster_carcinogenicity"
    time = 0
    while first(".model_status").has_no_content?("Completed") do
      sleep 5
      time +=5
    end
    assert first(".model_status").has_content?("Completed")
  end

  def test_03_predict
    Capybara.register_driver :akephalos do |app|
      Capybara::Driver::Akephalos.new(app, :validate_scripts => false)
    end
    session = Capybara::Session.new(:akephalos)
    session.visit CONFIG[:services]["opentox-toxcreate"]
    session.click_on "Predict"
    session.fill_in "or enter a Name, InChI, Smiles, CAS, ...", :with => "NNc1ccccc1"
    session.check "hamster_carcinogenicity"
    session.click_button("Predict")
    session.click_on "Details"
    assert session.has_content? "inactive"
    #assert session.has_content? "false"
    #assert session.has_content? "0.294"   
    #assert session.has_content? "0.875"
    Capybara.reset_sessions!
  end

  def test_04_inspect_policies
    visit CONFIG[:services]["opentox-toxcreate"]
    click_on "Inspect"
    assert first('h2').has_content? 'hamster_carcinogenicity'
    click_on "edit"
    click_on "manage policy"
    within(:xpath, '//form[contains(@id, "form_policy_group_member_")]') do
      find(:xpath, './/input[5]').click
      click_on "update"
    end
  end

  def test_05_inspect_policies
    visit CONFIG[:services]["opentox-toxcreate"]
    click_on "Inspect"
    assert first('h2').has_content? 'hamster_carcinogenicity'
    click_on "edit"
    click_on "manage policy"
    within(:xpath, '//form[contains(@id, "form_policy_group_member_")]') do
      find(:xpath, './/input[4]').click
      click_on "update"
    end
    
  end
  
  def test_06_inspect_policies
    visit CONFIG[:services]["opentox-toxcreate"]
    click_on "Inspect"
    assert first('h2').has_content? 'hamster_carcinogenicity'
    click_on "edit"
    click_on "manage policy"
    within(:xpath, '//form[contains(@id, "form_development")]') do
      find(:xpath, './/input[4]').click
      click_on "add"
    end
    sleep 5
  end
  
  def test_07_inspect_policies
    visit CONFIG[:services]["opentox-toxcreate"]
    click_on "Inspect"
    assert first('h2').has_content? 'hamster_carcinogenicity'
    click_on "edit"
    click_on "manage policy"
    within(:xpath, '//form[contains(@id, "form_policy_group_development_")]') do
      find(:xpath, './/input[3]').click
      click_on "update"
    end
    sleep 5
    #page.evaluate_script('window.confirm = function() { return true; }')
    click_on "delete"
  end 

  def test_08_multi_cell_call
    #login(@browser, @user, @password)
    Capybara.current_driver = :akephalos 
    visit CONFIG[:services]["opentox-toxcreate"]
    assert page.has_content?('Upload training data')
    attach_file('file', "./data/multi_cell_call.csv")
    click_on "Create model"
  end

  def test_09_kazius
    Capybara.current_driver = :akephalos 
    #login(@browser, @user, @password)
    visit CONFIG[:services]["opentox-toxcreate"]
    assert page.has_content?('Upload training data')
    attach_file('file', "./data/kazius.csv")
    # wait until validation is completed
    # check results (links, reports, results)
    puts @browser.url
  end

  def test_10_parallel_models
    #login(@browser, @user, @password)
    10.times do
      visit CONFIG[:services]["opentox-toxcreate"]
      assert page.has_content?('Upload training data')
      attach_file('file', "./data/multi_cell_call.csv")
      click_on "Create model"
    end
  end
=end
=begin
def login(browser, user, password)
  browser.goto File.join(CONFIG[:services]["opentox-toxcreate"], "login")
  browser.text_field(:id, "username").set(user)
  browser.text_field(:id, "password").set(password)
  browser.button(:value, "Login").click
end
=end
end   
