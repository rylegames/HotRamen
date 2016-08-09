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
  when /help/i
    text = ["Here's the list of commands",
      "'all events' -> display all upcoming events",
      "'my events' -> display my events in schedule",
      "'show 1' -> show info of event with id, in this case 1",
      "'add 1' -> add event to your schedule, in this case 1",
      "'delete 1' -> delete event in your schedule, in this case 1",
      "'help' -> Here's the list of commands ..."]

    text.each do |piece|
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: piece
        }
      )
    end
  when /add/i

    user = User.find_by(facebook_id: message.sender["id"])
    event_id = message.text.split(" ")[-1].to_i
    event = Event.find(event_id)
    
    if event
      attendance = user.attend!(event_id)
      attendance.save

      Bot.deliver(
        recipient: message.sender,
        message: {
          text: 'Event has been added!'
        }
      )

      if user.events.size == 0
        Bot.deliver(
          recipient: message.sender,
          message: {
            text: "You've added your first event to your schedule! Text 'my events' again to see your entire schedule!"
          }
        )
      end

    else
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: "Couldn't find that event. Double check the event number"
        }
      )
    end
  when /delete/i
    user = User.find_by(facebook_id: message.sender["id"])
    event_id = message.text.split(" ")[-1].to_i
    user.unattend(event_id)
    Bot.deliver(
        recipient: message.sender,
        message: {
          text: 'Event has been deleted!'
        }
      )
  when /show/i
    event_id = message.text.split(" ")[-1].to_i
    event = Event.find(event_id)

    if event
      puts "show event #{event.id}"
      event.full_display.each do |text|
        Bot.deliver(
          recipient: message.sender,
          message: {
            text: text
          }
        )
      end

      Bot.deliver(
        recipient: message.sender,
        message: {
          "attachment": {
            "type": "template",
            "payload": {
              "template_type": "generic",
              "elements": {
                "element": {
                  "title": event.location,
                  "image_url": "https://maps.googleapis.com/maps/api/staticmap?size=764x400&center="+event.latitude.to_s+","+event.longitude.to_s+"&zoom=17&markers="+event.latitude.to_s+","+event.longitude.to_s,
                  "item_url": "http://maps.apple.com/maps?q="+event.latitude.to_s+","+event.longitude.to_s+"&z=16"
                }
              }
            }
          }
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
    events = Event.order(:id).where('begin_date > ?', DateTime.current - 30.minutes).order('id asc').limit(5).offset(0)
    user = User.find_by(facebook_id: message.sender["id"])
    events[0..-2].each do |event|
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: event.mini_display
        }
      )
    end

    Bot.deliver(
      recipient: message.sender,
      message:{
        "attachment":{
          "type":"template",
          "payload":{
            "template_type":"button",
            "text": events[-1].mini_display,     
            "buttons":[
              {
                "type":"postback",
                "title":"More Events",
                "payload":"MORE_ALL_EVENTS_" + 5.to_s
              }              
            ]
          }
        }
      }
    )

    if user.events.size == 0
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: "All events have a unique ID number right under the title. Text 'Add' and the ID number of an event, such as 'Add 7' to add the event to your schedule."
        }
      )
    end

  when /my events/i
    user = User.find_by(facebook_id: message.sender["id"])
    events = user.events.where('begin_date > ?', DateTime.current - 30.minutes).order('id asc')
    if user and events.size > 0
      events.each do |event|
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
            text: "Looks like you haven't added any events to your schedule.\nText 'all events' and see what's going on!"
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
  when 'WELCOME_NEW_USER'
    text = "Welcome to upData, the bot with all the events for Harvard's Opening Days! Created by your classmate Ryan Lee '20. Text 'my events' to start building your schedule!"
    Bot.deliver(
      recipient: postback.sender,
      message: {
        text: text
      }
    ) 
  when /MORE_ALL_EVENTS/i

    event_id = postback.payload.split("_")[-1].to_i
    events = Event.where('begin_date > ?', DateTime.current - 30.minutes).order('id asc').limit(5).offset(event_id)
    #events = Event.order('id asc').limit(5).offset(event_id)

    if events.length > 1
      events[0..-2].each do |event|
        Bot.deliver(
          recipient: postback.sender,
          message: {
            text: event.mini_display
          }
        )
      end
    end

    Bot.deliver(
      recipient: postback.sender,
      message:{
        "attachment":{
          "type":"template",
          "payload":{
            "template_type":"button",
            "text": events[-1].mini_display,     
            "buttons":[
              {
                "type":"postback",
                "title":"More Events",
                "payload":"MORE_ALL_EVENTS_" + (event_id + 5).to_s 
              }              
            ]
          }
        }
      }
    )

  when /SHOW/i
    event_id = postback.payload.split("_")[-1].to_i
    event = Event.find(event_id)
    event.full_display.each do |text|
      Bot.deliver(
        recipient: postback.sender,
        message: {
          text: text
        }
      )
    end

  end

  Bot.deliver(
    recipient: message.sender,
    message: {
      "attachment": {
        "type": "template",
        "payload": {
          "template_type": "generic",
          "elements": {
            "element": {
              "title": event.location,
              "image_url": "https://maps.googleapis.com/maps/api/staticmap?size=764x400&center="+event.latitude.to_s+","+event.longitude.to_s+"&zoom=17&markers="+event.latitude.to_s+","+event.longitude.to_s,
              "item_url": "http://maps.apple.com/maps?q="+event.latitude.to_s+","+event.longitude.to_s+"&z=16"
            }
          }
        }
      }
    }
  )

end

Bot.on :delivery do |delivery|
  puts "Delivered message(s) #{delivery.ids}"
end






