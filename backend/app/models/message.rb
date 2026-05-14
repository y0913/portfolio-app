class Message < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :chat_session

  validates :role, inclusion: { in: ROLES }
  validates :content, presence: true
end
