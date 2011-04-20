require 'rubygems'
require "rubygems"
require 'opentox-ruby'
require 'test/unit'
require 'watir-webdriver'

class ToxCreateTest < Test::Unit::TestCase
  def setup
    @browser = Watir::Browser.new :firefox
    @user = "test_ch"
    @password = "test_ch"
  end

  def test_login
    @browser.goto File.join(CONFIG[:services]["opentox-toxcreate"], "login")
    @browser.button(:value, "Login").click
    puts "Login without credentials"    
    assert @browser.text.include? "Please enter username and password."
    @browser.text_field(:id, "username").set(@user)
    @browser.text_field(:id, "password").set(@password + "nonsense")
    @browser.button(:value, "Login").click
    puts "Login with wrong password"
    assert @browser.text.include? "Login failed. Please try again." 
    @browser.text_field(:id, "username").set(@user)
    @browser.text_field(:id, "password").set(@password)
    @browser.button(:value, "Login").click
    puts "Login as user #{@user}"
    assert @browser.text.include? "Welcome #{@user}!"
    @browser.goto File.join(CONFIG[:services]["opentox-toxcreate"], "login")
    @browser.button(:value, "Login as guest").click
    puts "Login as user guest"    
    assert @browser.text.include? "Welcome guest!"
    @browser.close    
  end

=begin
  def teardown
    @browser.close
  end
=end

  def test_toxcreate
    @browser.goto CONFIG[:services]["opentox-toxcreate"]
    @browser.file_field(:id, "file").set(`pwd`.chomp+"/data/hamster_carcinogenicity.csv")
    @browser.button(:value, "Create model").click
    # wait until validation is completed
    # check results (links, reports, results)
    puts @browser.url
  end

=begin
  def test_multi_cell_call
    @browser.goto CONFIG[:services]["opentox-toxcreate"]
    @browser.file_field(:id, "file").set(`pwd`.chomp+"/data/multi_cell_call.csv")
    @browser.button(:value, "Create model").click
    # wait until validation is completed
    # check results (links, reports, results)
    puts @browser.url
  end

  def test_kazius
    @browser.goto CONFIG[:services]["opentox-toxcreate"]
    @browser.file_field(:id, "file").set(`pwd`.chomp+"/data/kazius.csv")
    @browser.button(:value, "Create model").click
    # wait until validation is completed
    # check results (links, reports, results)
    puts @browser.url
  end

  def test_parallel_models
    10.times do
      @browser.goto CONFIG[:services]["opentox-toxcreate"]
      @browser.file_field(:id, "file").set(`pwd`.chomp+"/data/hamster_carcinogenicity.csv")
      @browser.button(:value, "Create model").click
    end
    #@browser.close
  end
=end
end
