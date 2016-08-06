class Event < ApplicationRecord
	has_many :attendances, dependent: :destroy
	has_many :users, through: :attendances
	validates :title, presence: true

	def mini_display
		#event = Event.find_by(event_id: event_id)
		if self.title.length > 30
			text = self.title[0..30].downcase + "\n"
		else
			text = self.title.downcase + " " * (30 - self.title.length) + "\n"
		end

		begin_date = self.begin_date.strftime("%a, %b %-d%l:%M%P")
		if self.id.to_s.length < (30 - begin_date.to_s.length)
			text = text + "ID: " + self.id.to_s + (" " * (30 - self.id.to_s.length - begin_date.to_s.length)) + begin_date.to_s+ "\n"
		end

		if self.description.length > 30
			text = text + self.description[0..30] + "\n"
		else
			text = text + self.description + " " * (30 - self.description.length) + "\n"
		end

		text = text + self.location

		#text = text + event.description + "\n" + event.location

		return text
	end

	def full_display
		text = self.title + "\n"

		range = self.begin_date.strftime("%a, %b %-d%l:%M") + " - " + self.end_date.strftime("%l:%M")
		if self.id.to_s.length < (30 - range.to_s.length)
			text = text + "ID: " + self.id.to_s + (" " * (30 - self.id.to_s.length - range.to_s.length)) + range.to_s+ "\n"
		end

		# text = text + self.description + "\n" + self.location

		description = self.description
		if description.length > 315
			new_text = Array.new
			(1..desciption.length/315).each do |i|
				new_text.push(description[315*(i-1)..315*(i)])
				description = description[((315*i) + 1)..-1]
			end
			new_text.push(description)

			return [text] + new_text
		else
			return [text, description]
		end



	end

end
