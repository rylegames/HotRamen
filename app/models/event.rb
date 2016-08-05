class Event < ApplicationRecord
	has_many :attendances, dependent: :destroy
	has_many :users, through: :attendances
	validates :title, presence: true

	def mini_display
		#event = Event.find_by(event_id: event_id)
		if self.title.length > 26
			text = self.title[0..26] + "\n"
		else
			text = self.title + " " * (26 - self.title.length) + "\n"
		end

		if self.id.to_s.length < (26 - self.begin_date.to_s.length + 8)
			text = text + self.id.to_s + (" " * (26 - self.id.to_s.length - self.begin_date.to_s.length + 8)) + self.begin_date.to_s[0..-8] + "\n"
		end

		if self.description.length > 26
			text = text + self.description[0..26] + "\n"
		else
			text = text + self.description + " " * (26 - self.description.length) + "\n"
		end

		text = text + self.location

		#text = text + event.description + "\n" + event.location

		return text
	end

end
