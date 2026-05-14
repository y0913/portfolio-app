FactoryBot.define do
  factory :document_chunk do
    document
    sequence(:position) { |n| n - 1 }
    content { "chunk content" }
    embedding_model { "stub-1024" }
    embedding { Array.new(1024) { 0.0 } }
  end
end
