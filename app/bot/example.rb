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
    text = "Hello! I'm here to tell you everything going on. 
• all events 
• my events

For each event, you can 'add', 'delete', and 'show'. For example, here's what you can do with event of ID num 7.
• add 7
• delete 7
• show 7

Hope this was helpful!
          "

    Bot.deliver(
      recipient: message.sender,
      message: {
        text: text
      }
    )

  when /add/i
    user = User.where(facebook_id: message.sender["id"]).pluck(:id, :newuser)[0]
    newuser = user[1]
    user_id = user[0]
    event_id = message.text.split(" ")[-1].to_i
    attendance = Attendance.where(user_id: user_id, event_id: event_id).first_or_create

    if attendance.id and event_id != 0

      Bot.deliver(
        recipient: message.sender,
        message: {
          text: 'Event has been added!'
        }
      )

      if newuser
        Bot.deliver(
          recipient: message.sender,
          message: {
            text: "You've added your first event! Note: you can add, delete, or show an event whenever you want, as long as you include the event id. Text 'my events' to see your entire schedule!"
          }
        )

        #User.where(facebook_id: message.sender["id"]).update(newuser: 4)
      end

    else
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: "Couldn't find that event. Double check the event number"
        }
      )
    end

    user = 0
    newuser = 0
    user_id = 0
    event_id = 0
    attendance = 0

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
    event = Event.find(event_id)  if event_id != 0
    newuser = User.where(facebook_id: message.sender["id"]).pluck(:newuser)[0]

    if event
      puts "show event #{event.id}"
      parts = event.full_display
      parts[0..-2].each do |text|
        Bot.deliver(
          recipient: message.sender,
          message: {
            text: text
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
              "text": parts[-1],     
              "buttons":[
                {
                  "type":"postback",
                  "title":"Add To Schedule",
                  "payload":"ADD_" + event_id.to_s
                }              
              ]
            }
          }
        }
      )

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

      if newuser
        Bot.deliver(
          recipient: message.sender,
          message: {
            text: "Pretty cool huh? Text 'add' and the event ID number, or press 'Add to Schedule', to add it to your schedule!"
          }
        )
        #User.where(facebook_id: message.sender["id"]).update(newuser: 3)
      end

    else
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: "Couldn't find that event. Double check the event number"
        }
      )
    end

  when /all events/i
    # if message["quick_reply"]
    #   event_id = message["quick_reply"].payload.to_i
    # else
    #   event_id = message.text.split(" ")[-1].to_i
    # end
    puts message.payload
    event_id = 0
    events = Event.order(:id).where('begin_date > ?', DateTime.current - 30.minutes).order('id asc').limit(5).offset(event_id)
    newuser = User.where(facebook_id: message.sender["id"]).pluck(:newuser)[0]

    events[0..-2].each do |event|
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: event.mini_display
        }
      )
    end

    # Bot.deliver(
    #   recipient: message.sender,
    #   message:{
    #     "attachment":{
    #       "type":"template",
    #       "payload":{
    #         "template_type":"button",
    #         "text": events[-1].mini_display,     
    #         "buttons":[
    #           {
    #             "type":"postback",
    #             "title":"More Events",
    #             "payload":"MORE_ALL_EVENTS_" + 5.to_s
    #           }              
    #         ]
    #       }
    #     }
    #   }
    # )

    Bot.deliver(
      recipient: message.sender,
      message:{
        "text": events[-1].mini_display,     
        "quick_replies":[
          {
            "content_type":"text",
            "title":"All Events",
            "payload":"#{event_id + 5}" 
          },
          {
            "content_type":"text",
            "title":"Show #{event_id + 1}",
            "payload":"SHOW_#{event_id + 1}" 
          },
          {
            "content_type":"text",
            "title":"Show #{event_id + 2}",
            "payload":"SHOW_#{event_id + 2}" 
          },
          {
            "content_type":"text",
            "title":"Show #{event_id + 3}",
            "payload":"SHOW_#{event_id + 3}"
          } ,
          {
            "content_type":"text",
            "title":"Show #{event_id + 4}",
            "payload":"SHOW_#{event_id + 4}" 
          },
          {
            "content_type":"text",
            "title":"Show #{event_id + 5}",
            "payload":"SHOW_#{event_id + 5}" 
          }                
        ]
      }
    )

    # if newuser
    #   Bot.deliver(
    #     recipient: message.sender,
    #     message: {
    #       text: "So much fun stuff! 'All events' shows you all current and upcoming events. Each event has a unique ID number right under the title. Text 'Show' and the event ID number to see the full description and location."
    #     }
    #   )

      #User.where(facebook_id: message.sender["id"]).update(newuser: 2)
    #end

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
      if events.size == 1
        Bot.deliver(
          recipient: message.sender,
          message: {
            text: "You're all set! You can 'delete' your events as well. Text 'help' whenever you need the reference. Welcome aboard and have fun at orientation!"
          }
        )
        User.where(facebook_id: message.sender["id"]).update(newuser: false)
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
    if User.find_by(facebook_id: postback.sender["id"]) 
      user = User.where(facebook_id: postback.sender["id"]).update(newuser: true)
    else
      user = User.create(facebook_id: postback.sender["id"], newuser: true) 
    end

    text = "Welcome to My Ramen, the bot with all the events for Harvard's Opening Days! Created by Ryan Lee '20. Text 'all events' to start building your schedule!"
    Bot.deliver(
      recipient: postback.sender,
      message: {
        text: text
      }
    ) 
    user = 0

  when "HELP"
    text = "Hello! I'm here to tell you everything going on. 
• all events 
• my events

For each event, you can 'add', 'delete', and 'show'. For example, here's what you can do with event of ID num 7.
• add 7
• delete 7
• show 7

Hope this was helpful!
          "

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

    Bot.deliver(
      recipient: postback.sender,
      message:{
        "text": "Show Full Description Of",     
        "quick_replies":[
          {
            "content_type":"text",
            "title":"Show #{event_id + 1}",
            "payload":"SHOW_#{event_id + 1}" 
          },
          {
            "content_type":"text",
            "title":"Show #{event_id + 2}",
            "payload":"SHOW_#{event_id + 2}" 
          },
          {
            "content_type":"text",
            "title":"Show #{event_id + 3}",
            "payload":"SHOW_#{event_id + 3}"
          } ,
          {
            "content_type":"text",
            "title":"Show #{event_id + 4}",
            "payload":"SHOW_#{event_id + 4}" 
          },
          {
            "content_type":"text",
            "title":"Show #{event_id + 5}",
            "payload":"SHOW_#{event_id + 5}" 
          }                
        ]
      }
    )


  when /ADD/i

    user = User.where(facebook_id: postback.sender["id"]).pluck(:id, :newuser)[0]
    newuser = user[1]
    user_id = user[0]
    event_id = postback.payload.split(" ")[-1].to_i
    attendance = Attendance.where(user_id: user_id, event_id: event_id).first_or_create

    if attendance.id and event_id != 0

      Bot.deliver(
        recipient: message.sender,
        message: {
          text: 'Event has been added!'
        }
      )

      if newuser
        Bot.deliver(
          recipient: message.sender,
          message: {
            text: "You've added your first event! Note: you can add, delete, or show an event whenever you want, as long as you include the event id. Text 'my events' to see your entire schedule!"
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

    user = 0
    newuser = 0
    user_id = 0
    event_id = 0
    attendance = 0

  else
    Bot.deliver(
      recipient: postback.sender,
      message: {
        text: "Couldn't find that event. Double check the event number"
      }
    )
  end

end

Bot.on :delivery do |delivery|
  puts "Delivered message(s) #{delivery.ids}"
end






