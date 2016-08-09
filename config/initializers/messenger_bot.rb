Messenger::Bot.config do |config|
  config.access_token = ENV['ACCESS_TOKEN']
  config.validation_token = ENV['VERIFY_TOKEN']
  #config.secret_token = ENV['FB_APP_SECRET_TOKEN']
end