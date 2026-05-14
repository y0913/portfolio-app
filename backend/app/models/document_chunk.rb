class DocumentChunk < ApplicationRecord
  has_neighbors :embedding

  belongs_to :document

  validates :content, presence: true
  validates :position, presence: true, uniqueness: { scope: :document_id }
  validates :embedding_model, presence: true
end
