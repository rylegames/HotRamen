# curl -X POST -H "Content-Type: application/json" -d '{
#   "setting_type" : "call_to_actions",
#   "thread_state" : "existing_thread",
#   "call_to_actions":[
#     {
#       "type":"postback",
#       "title":"All Events",
#       "payload":"MORE_ALL_EVENTS_0"
#     },
#     {
#       "type":"postback",
#       "title":"My Events",
#       "payload":"MY_EVENTS"
#     },
#     {
#       "type":"postback",
#       "title":"Help",
#       "payload":"HELP"
#     }
#   ]
# }' "https://graph.facebook.com/v2.6/me/thread_settings?access_token=EAANT2k7GtasBADWMzmyTUyc59MQZCxpJWfQWFTvwsjvF3rrU97nniUD8Ov93LzDdHFtNleEMHg8AvuvGU2vf4y3FosPvI9cQ1ID1rMe52QZCZAMywQ8ZAhZBltzXwcSk0MeuEBUqfLYT16aM0LsOG8QCf0okD7vrCbPNnVqzhYwZDZD"    

def all_events(sender, event_id)
  events = Event.order(:id).where('begin_date > ?', DateTime.current - 30.minutes).order('id asc').limit(5).offset(event_id)
  newuser = User.where(facebook_id: sender["id"]).pluck(:newuser)[0]

  events[0..-2].each do |event|
    Bot.deliver(
      recipient: sender,
      message: {
        text: event.mini_display
      }
    )
  end

  Bot.deliver(
    recipient: sender,
    message:{
      "text": events[-1].mini_display,     
      "quick_replies":[
        {
          "content_type":"text",
          "title":"More Events",
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

  if newuser
    Bot.deliver(
      recipient: sender,
      message: {
        text: "So much fun stuff! 'All events' shows you all current and upcoming events. Each event has a unique ID number right under the title. Text 'Show' and the event ID number to see the full description and location."
      }
    )
    #User.where(facebook_id: message.sender["id"]).update(newuser: 2)
  end

  events = 0
  newuser = 0
end

def add_event(sender, event_id)
  user = User.where(facebook_id: sender["id"]).pluck(:id, :newuser)[0]
  newuser = user[1]
  user_id = user[0]
  attendance = Attendance.where(user_id: user_id, event_id: event_id).first_or_create

  if attendance.id and event_id != 0

    Bot.deliver(
      recipient: sender,
      message: {
        text: 'Event has been added!'
      }
    )

    if newuser
      Bot.deliver(
        recipient: sender,
        message: {
          text: "You've added your first event! Note: you can add, delete, or show an event whenever you want, as long as you include the event id. Text 'my events' to see your entire schedule!"
        }
      )
    end

  else
    Bot.deliver(
      recipient: sender,
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

end