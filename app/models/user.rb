class User < ApplicationRecord
	has_many :attendances, 	class_name: "Attendance",
							foreign_key: "user_id",
							dependent: :destroy

	has_many :events, through: :attendances
	validates :facebook_id, presence: true

	def attend!(new_event)
		attendances.create!(event_id: new_event.id)
	end

	def unattend(new_event)
		attendances.find_by(event_id: new_event.id).destroy
	end

end