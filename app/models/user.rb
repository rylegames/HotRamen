class User < ApplicationRecord
	has_many :attendances, 	class_name: "Attendance",
							foreign_key: "user_id",
							dependent: :destroy

	has_many :events, through: :attendances
	validates :facebook_id, presence: true

	def attend!(new_event_id)
		attendance = attendances.find_by(event_id: new_event_id)
		unless attendance 
			attendances.create!(event_id: new_event_id)
		end
	end

	def unattend(new_event_id)
		attendance = attendances.find_by(event_id: new_event_id)
		if attendance
			attendance.destroy
		end
	end

end
