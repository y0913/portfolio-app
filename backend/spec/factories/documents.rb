FactoryBot.define do
  factory :document do
    user
    title { "Sample document" }
    status { "pending" }

    trait :with_text do
      transient { body { "Sample content for the document." } }
      after(:build) do |doc, ev|
        doc.file.attach(
          io: StringIO.new(ev.body),
          filename: "sample.md",
          content_type: "text/markdown"
        )
      end
    end

    trait :ready do
      status { "ready" }
    end
  end
end
