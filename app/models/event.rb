class Event < ApplicationRecord
	has_many :attendances, dependent: :destroy
	has_many :users, through: :attendances
	validates :title, presence: true

	def mini_display
		#event = Event.find_by(event_id: event_id)
		if self.title.length > 30
			text = self.title[0..30] + "\n"
		else
			text = self.title.downcase + " " * (30 - self.title.length) + "\n"
		end

		if self.id.to_s.length < (30 - self.begin_date.to_s.length + 8)
			text = text + self.id.to_s + (" " * (30 - self.id.to_s.length - self.begin_date.to_s.length + 8)) + self.begin_date.to_s[0..-8] + "\n"
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

end
