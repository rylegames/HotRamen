class Event < ApplicationRecord
	has_many :attendances, dependent: :destroy
	has_many :users, through: :attendances
	validates :title, presence: true
end
