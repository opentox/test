require 'rubygems'
require "rubygems"
require 'opentox-ruby'
require 'test/unit'
require 'akephalos'
require 'capybara/dsl'
gem 'capybara-envjs'
require 'capybara/envjs' # gem install capybara-envjs
# requires firefox 3.6 for akephalos and selenium !!!
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
=begin # works only with AA enabled  
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
=end
  def test_02_toxcreate # works only with akephalos
    # create a model and check status is complete
    Capybara.current_driver = :akephalos 
    visit File.join(CONFIG[:services]["opentox-toxcreate"], "create")
    assert page.has_content?('Upload training data')
    attach_file('file', "./data/hamster_carcinogenicity.csv")
    assert page.has_button?('endpoint_list_button')
    click_on "Select endpoint"
    choose('EcotoxicEffects')
    choose('Acute_toxicity_to_fish_lethality')
    click_on "Create model"
    assert first("h2").has_content? "hamster_carcinogenicity"
    time = 0
    while (first(".model_status").has_no_content?("Completed") and first(".model_status").has_no_content?("Error")) do
      sleep 5
      time +=5
    end
    assert first(".model_status").has_content?("Completed")
    sleep 5
  end

  def test_03_predict
  # predict with the model from test_02
    Capybara.register_driver :akephalos do |app|
      Capybara::Driver::Akephalos.new(app, :validate_scripts => false)
    visit File.join(CONFIG[:services]["opentox-toxcreate"], "predict")
    fill_in 'identifier', :with => 'NNc1ccccc1'
    find(:xpath, '//form/fieldset[2]/input[contains(@name, "select")]').click
    click_button("Predict")
    click_button("Details")
    page.has_content? "false"
    page.has_content? "0.294"   
    page.has_content? "0.875"
    page.has_content? "next"
    end
  end

  def test_04_delete_model
  # delete the model from test_02
    visit File.join(CONFIG[:services]["opentox-toxcreate"], "models")
    assert (first(".model_status").has_content?("Completed") or first(".model_status").has_content?("Error"))
    click_on "delete"
    page.evaluate_script('window.confirm = function() { return true; }')
    sleep 5
  end
=begin
  def test_09_multi_cell_call
    #login(@browser, @user, @password)
    #Capybara.current_driver = :akephalos 
    visit File.join(CONFIG[:services]["opentox-toxcreate"], "create")
    assert page.has_content?('Upload training data')
    attach_file('file', "./data/multi_cell_call.csv")
    click_on "Create model"
  end

  def test_10_kazius
    #Capybara.current_driver = :akephalos 
    #login(@browser, @user, @password)
    visit File.join(CONFIG[:services]["opentox-toxcreate"], "create")
    assert page.has_content?('Upload training data')
    attach_file('file', "./data/kazius.csv")
    # wait until validation is completed
    # check results (links, reports, results)
    puts @browser.url
  end
 
  def test_11_parallel_models
    5.times do
      visit File.join(CONFIG[:services]["opentox-toxcreate"], "create")
      assert page.has_content?('Upload training data')
      attach_file('file', "./data/hamster_carcinogenicity.csv")
      click_on "Create model"
    end
    while (first(".model_status").has_no_content?("Completed") and first(".model_status").has_no_content?("Error")) do
      sleep 1
    end
    assert first(".model_status").has_content?("Completed")
  end
 
  def test_12_delete_parallel_models  
    5.times do
      visit File.join(CONFIG[:services]["opentox-toxcreate"], "models")
      click_on "delete"
      page.evaluate_script('window.confirm = function() { return true; }')
      #sleep 5
    end
    sleep 5
    visit File.join(CONFIG[:services]["opentox-toxcreate"], "models")
    while page.has_no_content? "There are currently no models" do
      sleep 1
    end
    assert page.has_content? "There are currently no models"
  end
=begin
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
