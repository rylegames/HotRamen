require 'facebook/messenger'

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
    user = User.new(facebook_id: message.sender["id"])
    user.save

    Bot.deliver(
      recipient: message.sender,
      message: {
        text: 'created!'
      }
    )

  when /add/i
    user = User.find_by(facebook_id: message.sender["id"]).
    event_id = message.text.split(" ")[-1].to_i
    attendance = user.attend!(event_id)
    attendance.save

    Bot.deliver(
      recipient: message.sender,
      message: {
        text: 'added!'
      }
    )

  when /all events/i
    events = Event.all
    events do |event|
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: event.id.to_
        }
      )
    end

  when /my events/i
    user = User.find_by(facebook_id: message.sender["id"]).
    user.events do |event|
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: event.title
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