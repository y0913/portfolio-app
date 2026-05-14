class Document < ApplicationRecord
  STATUSES = %w[pending processing ready failed].freeze

  belongs_to :user
  has_many :document_chunks, dependent: :destroy
  has_one_attached :file

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
end
