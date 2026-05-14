# Idempotent seed: demo user + sample documents.
# Safe to re-run.

DEMO_EMAIL = "demo@example.com".freeze
DEMO_PASSWORD = "password123".freeze

demo_user = User.find_or_initialize_by(email_address: DEMO_EMAIL)
if demo_user.new_record?
  demo_user.password = DEMO_PASSWORD
  demo_user.password_confirmation = DEMO_PASSWORD
  demo_user.save!
  puts "Created demo user #{DEMO_EMAIL}"
else
  puts "Demo user #{DEMO_EMAIL} already exists (id=#{demo_user.id})"
end

SAMPLE_DOCS = [
  { title: "返金・返品ポリシー",       filename: "return_policy.md" },
  { title: "入社オンボーディング ハンドブック", filename: "onboarding_handbook.md" }
].freeze

SAMPLE_DOCS.each do |spec|
  existing = demo_user.documents.find_by(title: spec[:title])
  if existing
    puts "Document '#{spec[:title]}' already exists (status=#{existing.status})"
    next
  end

  path = Rails.root.join("db/seed_data", spec[:filename])
  unless File.exist?(path)
    warn "Seed file missing: #{path}"
    next
  end

  document = demo_user.documents.create!(title: spec[:title], status: "pending")
  document.file.attach(
    io: File.open(path),
    filename: spec[:filename],
    content_type: "text/markdown"
  )
  # Run synchronously: the seed process exits before :async queue threads
  # would otherwise finish.
  EmbedDocumentJob.perform_now(document.id)
  document.reload
  puts "Seeded document '#{spec[:title]}' (id=#{document.id}, status=#{document.status}, chunks=#{document.document_chunks.count})"
end
