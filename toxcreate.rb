require 'rubygems'
require "rubygems"
require 'opentox-ruby'
require 'test/unit'
require 'akephalos'
require 'capybara/dsl'
gem 'capybara-envjs'
require 'capybara/envjs' # gem install capybara-envjs

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

  def test_01_login
    visit File.join(CONFIG[:services]["opentox-toxcreate"], "login")
    assert page.has_content?('User: guest')
    fill_in('Username', :with => @user)
    fill_in('Password', :with => @password + "nonsense")
    click_button('Login')
    assert page.has_content? "Login failed. Please try again."
    fill_in('Username', :with => @user)
    fill_in('Password', :with => @password)
    click_button('Login')
    assert page.has_content? "Welcome #{@user}!"
    visit File.join(CONFIG[:services]["opentox-toxcreate"], "login")
    assert page.has_content?('User: guest')
    fill_in('Username', :with => @user)
    fill_in('Password', :with => @password + "nonsense")
    click_button('Login')
    assert page.has_content? "Login failed. Please try again."
    click_button('Login as guest')
    assert page.has_content? "Welcome #{@user}!"
  end

  def test_02_toxcreate # works only with akephalos
    # create a model and check status is complete
    Capybara.current_driver = :akephalos 
    #login(@browser, @user, @password)
    visit File.join(CONFIG[:services]["opentox-toxcreate"], "create")#visit CONFIG[:services]["opentox-toxcreate"]
    assert page.has_content?('Upload training data')
    attach_file('file', "./data/hamster_carcinogenicity.csv")
    click_on "Create model"
    assert first("h2").has_content? "hamster_carcinogenicity"
    time = 0
    while (first(".model_status").has_no_content?("Completed") and first(".model_status").has_no_content?("Error")) do
      sleep 5
      time +=5
    end
    assert first(".model_status").has_content?("Completed")
  end

  def test_03_predict
  # predict with the model from test_02
    Capybara.register_driver :akephalos do |app|
      Capybara::Driver::Akephalos.new(app, :validate_scripts => false)
    end
    session = Capybara::Session.new(:akephalos)
    session.visit File.join(CONFIG[:services]["opentox-toxcreate"], "predict")#CONFIG[:services]["opentox-toxcreate"]
    #session.click_on "Predict"
    session.fill_in('identifier', :with => "NNc1ccccc1")
    session.check "hamster_carcinogenicity"
    session.click_button("Predict")
    session.click_button("Details")
    assert session.has_content? "false"
    assert session.has_content? "0.294"   
    assert session.has_content? "0.875"
    Capybara.reset_sessions!
  end

  def test_04_inspect_policies
    visit File.join(CONFIG[:services]["opentox-toxcreate"], "models")#visit CONFIG[:services]["opentox-toxcreate"]
    #click_on "Inspect"
    assert first('h2').has_content? 'hamster_carcinogenicity'
    click_on("edit name")
    click_on("Cancel")
    click_on("protect data")
    within(:xpath, '//form[contains(@id, "form_policy_group_member_")]') do
      find(:xpath, './/input[5]').click
      click_on "update"
    end
  end

  def test_05_inspect_policies
    #visit CONFIG[:services]["opentox-toxcreate"]
    #click_on "Inspect"
    #assert first('h2').has_content? 'hamster_carcinogenicity'
    #click_on "edit"
    #click_on "manage policy"
    within(:xpath, '//form[contains(@id, "form_policy_group_member_")]') do
      find(:xpath, './/input[4]').click
      click_on "update"
    end    
  end
  
  def test_06_inspect_policies
    #visit CONFIG[:services]["opentox-toxcreate"]
    #click_on "Inspect"
    #assert first('h2').has_content? 'hamster_carcinogenicity'
    #click_on "edit"
    #click_on "manage policy"
    within(:xpath, '//form[contains(@id, "form_development")]') do
      find(:xpath, './/input[4]').click
      click_on "add"
    end
    sleep 5
  end
  
  def test_07_inspect_policies
    #visit CONFIG[:services]["opentox-toxcreate"]
    #click_on "Inspect"
    #assert first('h2').has_content? 'hamster_carcinogenicity'
    #click_on "edit"
    #click_on "manage policy"
    within(:xpath, '//form[contains(@id, "form_policy_group_development_")]') do
      find(:xpath, './/input[3]').click
      click_on "update"
    end
    sleep 5
    #page.evaluate_script('window.confirm = function() { return true; }')
    click_on "exit"
  end
  
  def test_08_delete_model
    click_on "delete"
  end
=begin
  def test_09_multi_cell_call
    #login(@browser, @user, @password)
    Capybara.current_driver = :akephalos 
    visit CONFIG[:services]["opentox-toxcreate"]
    assert page.has_content?('Upload training data')
    attach_file('file', "./data/multi_cell_call.csv")
    click_on "Create model"
  end

  def test_10_kazius
    Capybara.current_driver = :akephalos 
    #login(@browser, @user, @password)
    visit CONFIG[:services]["opentox-toxcreate"]
    assert page.has_content?('Upload training data')
    attach_file('file', "./data/kazius.csv")
    # wait until validation is completed
    # check results (links, reports, results)
    puts @browser.url
  end

  def test_11_parallel_models
    #login(@browser, @user, @password)
    10.times do
      visit CONFIG[:services]["opentox-toxcreate"]
      assert page.has_content?('Upload training data')
      attach_file('file', "./data/multi_cell_call.csv")
      click_on "Create model"
    end
  end
  # raises capybara errors, but gui works from browser
  def test_12_toxcreate_sdf # works only with akephalos
    Capybara.current_driver = :akephalos 
    #login(@browser, @user, @password)
    visit CONFIG[:services]["opentox-toxcreate"]
    assert page.has_content?('Upload training data')
    attach_file('file', "./data/hamster_carcinogenicity.sdf")
    click_on "Create model"
    assert first("h2").has_content? "hamster_carcinogenicity"
    time = 0
    while first(".model_status").has_no_content?("Completed") do
      sleep 5
      time +=5
    end
    assert first(".model_status").has_content?("Completed")
  end
=end

end   
