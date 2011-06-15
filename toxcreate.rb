require 'rubygems'
require "rubygems"
require 'opentox-ruby'
require 'test/unit'
require 'akephalos'
require 'capybara/dsl'
Capybara.default_driver = :akephalos
#Capybara.default_driver = :selenium # use this for visual inspection
Capybara.run_server = false
Capybara.default_wait_time = 600



class ToxCreateTest < Test::Unit::TestCase
  include Capybara

  def setup
    @user = "test_ch"
    @password = "test_ch"
  end

  def teardown
  end

=begin
  def test_login
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


  def test_predict # works only with selenium
    visit CONFIG[:services]["opentox-toxcreate"]
    click_on "Predict"
    fill_in "or enter a Name, InChI, Smiles, CAS, ...", :with => "NNc1ccccc1"
    check "hamster_carcinogenicity"
    click_button "Predict"
    assert page.has_content? "false"
    assert page.has_content? "0.294"
    click_on "Details"
    assert page.has_content? "0.875"
  end
=end

  def test_toxcreate # works only with akephalos
    #login(@browser, @user, @password)
    visit CONFIG[:services]["opentox-toxcreate"]
    assert page.has_content?('Upload training data')
    attach_file('file', "./data/hamster_carcinogenicity.csv")
    click_on "Create model"
    assert first("h2").has_content? 'hamster_carcinogenicity'
    time = 0
    while first(".model_status").has_no_content?("Completed") and time < 120 do
      sleep 5
      time +=5
    end
    assert first(".model_status").has_content?("Completed")
    click_on "Predict"
    fill_in "or enter a Name, InChI, Smiles, CAS, ...", :with => "NNc1ccccc1"
    check "hamster_carcinogenicity"
    #click_button "Predict"
    #assert page.has_content? "false"
    #assert page.has_content? "0.294"
    #click_on "Details"
    #assert page.has_content? "0.875"
  end

=begin
  def test_multi_cell_call
    login(@browser, @user, @password)
    @browser.goto CONFIG[:services]["opentox-toxcreate"]
    @browser.file_field(:id, "file").set(`pwd`.chomp+"/data/multi_cell_call.csv")
    @browser.button(:value, "Create model").click
    # wait until validation is completed
    # check results (links, reports, results)
    puts @browser.url
  end

  def test_kazius
    login(@browser, @user, @password)
    @browser.goto CONFIG[:services]["opentox-toxcreate"]
    @browser.file_field(:id, "file").set(`pwd`.chomp+"/data/kazius.csv")
    @browser.button(:value, "Create model").click
    # wait until validation is completed
    # check results (links, reports, results)
    puts @browser.url
  end

  def test_parallel_models
    login(@browser, @user, @password)
    10.times do
      @browser.goto CONFIG[:services]["opentox-toxcreate"]
      @browser.file_field(:id, "file").set(`pwd`.chomp+"/data/hamster_carcinogenicity.csv")
      @browser.button(:value, "Create model").click
    end
    #@browser.close
  end
=end
end

=begin
def login(browser, user, password)
  browser.goto File.join(CONFIG[:services]["opentox-toxcreate"], "login")
  browser.text_field(:id, "username").set(user)
  browser.text_field(:id, "password").set(password)
  browser.button(:value, "Login").click
end
=end
