class User < ApplicationRecord
	has_many :attendances, 	class_name: "Attendance",
							foreign_key: "user_id",
							dependent: :destroy

	has_many :events, through: :attendances
	validates :facebook_id, presence: true

	def attend!(user_id, new_event_id)
		Attendance.where(user_id: user_id, event_id: new_event_id).first_or_create
	end

	def unattend(user_id, new_event_id)
		Attendance.where(user_id: user_id, event_id: new_event_id).delete_all
	end

end
