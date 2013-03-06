Metaforce.configure do |config|
  #config.username = ENV["stacy_crochet@schumachergroup.com.test"]
  #config.password = ENV["Summer11"]
  #config.security_token = ENV["qbNoRxixCqFXYx6qWQIYzVVQ"]
  #config.host = ENV["test.salesforce.com"]

  config.username = ENV["SALESFORCE_USERNAME"]
  config.password = ENV["SALESFORCE_PASSWORD"]
  config.security_token = ENV["SALESFORCE_SECURITY_TOKEN"]
  config.host = ENV["SALESFORCE_HOST"] #test.salesforce.co or login.salesforce.com

  #config.username = "shawn_blanchard@sg.ww.shawndev"
  #config.password = "1234Force"
  #config.security_token = "ISQn7fFonAzK01v2N4e4NxQk"
  #config.host = "test.salesforce.com"
end