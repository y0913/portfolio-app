class ChatSession < ApplicationRecord
  belongs_to :user
  has_many :messages, -> { order(:created_at, :id) }, dependent: :destroy

  validates :title, presence: true
end
