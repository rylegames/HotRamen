require 'facebook/messenger'

# curl -X POST -H "Content-Type: application/json" -d '{
#   "setting_type":"call_to_actions",
#   "thread_state":"new_thread",
#   "call_to_actions":[
#     {
#       "payload":"WELCOME_NEW_USER"
#     }
#   ]
# }' "https://graph.facebook.com/v2.6/me/thread_settings?access_token=EAASmNgjGL9sBAEjNsWIuB1SDX1VjExN9NgBWGNP4kl0ZC3wk3XdOuhQ4Ee2JH0KlzG2QKMrer7MbwEZCpryAUnWjzXTsFs4ZB8KG9NZA9EX772lIXUuHYEHHHN9l5PQ7awdqUttfkXMzJBzks8v17h1ZC5ZCmqyf7tco4RHODtzQZDZD"      

Facebook::Messenger.configure do |config|
  config.access_token = ENV['ACCESS_TOKEN']
  config.verify_token = ENV['VERIFY_TOKEN']
end

include Facebook::Messenger

Bot.on :message do |message|
  puts "Received #{message.text} from #{message.sender}"

  case message.text
  when /hello/i
    Bot.deliver(
      recipient: message.sender,
      message: {
        text: 'Hello, human!'
      }
    )

  when /new account/i
    begin
      user = User.new(facebook_id: message.sender["id"])
      user.save

      Bot.deliver(
        recipient: message.sender,
        message: {
          text: 'created!'
        }
      )
    catch
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: 'failed!'
        }
      )
    end

  when /add/i
    user = User.find_by(facebook_id: message.sender["id"])
    
    if user
      event_id = message.text.split(" ")[-1].to_i
      attendance = user.attend!(event_id)
      attendance.save

      Bot.deliver(
        recipient: message.sender,
        message: {
          text: 'Event has been added!'
        }
      )
    else
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: "Couldn't find that event. Double check the event number"
        }
      )
    end

  when /more/i
    event_id = message.text.split(" ")[-1].to_i
    event = Event.find_by(id: event_id)

    if event
      event.full_display.each do |text|
        Bot.deliver(
          recipient: message.sender,
          message: {
            text: text
          }
        )
    else
      Bot.deliver(
          recipient: message.sender,
          message: {
            text: "Couldn't find that event. Double check the event number"
          }
        )
    end

  when /all events/i
    events = Event.all
    events.each do |event|
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: event.mini_display
        }
      )
    end

  when /my events/i
    user = User.find_by(facebook_id: message.sender["id"])
    user.events.each do |event|
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: event.mini_display
        }
      )
    end

  else
    Bot.deliver(
      recipient: message.sender,
      message: {
        text: "I couldn't catch that. Try texting 'help'"
      }
    )
  end
end

Bot.on :postback do |postback|
  case postback.payload
  when 'ALL_EVENTS'
    text = 'That makes bot happy!'
  when 'YOUR_EVENTS'
    text = 'Oh.'
  when 'WELCOME_NEW_USER'
    text = "Welcome to upData, the bot with all the events for Harvard's Opening Days! Created by your classmate Ryan Lee '20. Text 'my events' to start building your schedule!"
  end

  Bot.deliver(
    recipient: postback.sender,
    message: {
      text: text
    }
  )
end

Bot.on :delivery do |delivery|
  puts "Delivered message(s) #{delivery.ids}"
end






