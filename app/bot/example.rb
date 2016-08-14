require 'facebook/messenger'
require 'functions'

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
  when /help/i
    text = "Hello! I'm here to tell you everything going on.\n 
• all events 
• my events

For each event, you can 'add', 'delete', and 'show'. For example, here's what you can do with event of ID num 7.\n
• add 7
• delete 7
• show 7

Hope this was helpful! If this is the first time using the bot, text 'new user'
          "

    Bot.deliver(
      recipient: message.sender,
      message: {
        text: text
      }
    )

  when /add/i
    event_id = message.text.split(" ")[-1].to_i
    add_event(message.sender, event_id)
 
  when /delete/i
    user_id = User.where(facebook_id: message.sender["id"]).pluck(:id)[0]
    event_id = message.text.split(" ")[-1].to_i

    if Attendance.where(user_id: user_id, event_id: event_id).delete_all
      Bot.deliver(
          recipient: message.sender,
          message: {
            text: 'Event has been deleted!'
          }
        )
    else 
      Bot.deliver(
          recipient: message.sender,
          message: {
            text: "Event couldn't be found... Eh, who cares, not in your schedule!"
          }
        )
    end

    user = 0
    event_id = 0

  when /show/i
    event_id = message.text.split(" ")[-1].to_i
    show_event(message.sender, event_id)    

  when /all events/i
    all_events(message.sender, 0)

  when /more events/i
    begin
      event =  message.as_json["messaging"]["message"]["quick_reply"]["payload"].split("_")
      event_id = event[-1].to_i
      type_id = event[0]
    rescue
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: "Try texting 'all events'"
        }
      ) 
    end

    if event
      if type_id == "ALL"
        all_events(message.sender, event_id) 
      else
        my_events(message.sender, event_id) 
      end
    end

  when /^(\d*)$/
    event_id = message.text.to_i
    show_event(message.sender, event_id)  

  when /my events/i
    my_events(message.sender, 0)

  when /new user/i
    if User.find_by(facebook_id: message.sender["id"]) 
      user = User.where(facebook_id: message.sender["id"]).update(newuser: true)
    else
      user = User.create(facebook_id: message.sender["id"], newuser: true) 
    end

    text = "Welcome to Hot Ramen, the bot with all the events for Harvard's Opening Days! Created by Ryan Lee '20. \n\nText 'all events' or select the triple line menu button at the botton left and click All Events to start building your schedule!"
    Bot.deliver(
      recipient: message.sender,
      message: {
        text: text
      }
    ) 
    user = 0

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
  when /WELCOME_NEW_USER/i
    if User.find_by(facebook_id: postback.sender["id"]) 
      user = User.where(facebook_id: postback.sender["id"]).update(newuser: true)
    else
      user = User.create(facebook_id: postback.sender["id"], newuser: true) 
    end

    text = "Welcome to Hot Ramen, the bot with all the events for Harvard's Opening Days! Created by Ryan Lee '20. \n\nText 'all events' or select the triple line menu button at the botton left and click All Events to start building your schedule!"
    Bot.deliver(
      recipient: postback.sender,
      message: {
        text: text
      }
    ) 
    user = 0

  when "HELP"
    text = "Hello! I'm here to tell you everything going on. \n 
• all events 
• my events

For each event, you can 'add', 'delete', and 'show'. For example, here's what you can do with event of ID num 7.\n 
• add 7
• delete 7
• show 7

Hope this was helpful! If this is the first time using the bot, text 'new user'
          "
    Bot.deliver(
      recipient: postback.sender,
      message: {
        text: text
      }
    )

  when /MORE_ALL_EVENTS/i
    all_events(postback.sender, 0)


  when /ADD/i
    event_id = postback.payload.split("_")[-1].to_i
    add_event(postback.sender, event_id)

  when /MY_EVENTS/i
    my_events(postback.sender, 0)
    
  else
    Bot.deliver(
      recipient: postback.sender,
      message: {
        text: "Couldn't understand that. Try messaging 'help'. If this is the first time using the bot, text 'new user'"
      }
    )
  end

end

Bot.on :delivery do |delivery|
  puts "Delivered message(s) #{delivery.ids}"
end






