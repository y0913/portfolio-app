require "rails_helper"

RSpec.describe Messaging::Chatwork::SignatureVerifier do
  let(:secret) { "test-webhook-secret" }
  let(:raw_body) { '{"webhook_event_type":"message_created"}' }

  def expected_signature(body, key = secret)
    Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", key, body))
  end

  describe "#configured?" do
    it "is false when secret is missing" do
      expect(described_class.new(secret: nil).configured?).to be false
      expect(described_class.new(secret: "").configured?).to be false
    end

    it "is true when secret is set" do
      expect(described_class.new(secret: secret).configured?).to be true
    end
  end

  describe "#verify" do
    subject(:verifier) { described_class.new(secret: secret) }

    it "accepts a valid signature" do
      sig = expected_signature(raw_body)
      expect(verifier.verify(raw_body: raw_body, signature: sig)).to be true
    end

    it "rejects an invalid signature" do
      expect(verifier.verify(raw_body: raw_body, signature: "wrong")).to be false
    end

    it "rejects when the body is tampered" do
      sig = expected_signature(raw_body)
      tampered = raw_body + " "
      expect(verifier.verify(raw_body: tampered, signature: sig)).to be false
    end

    it "rejects an empty signature" do
      expect(verifier.verify(raw_body: raw_body, signature: "")).to be false
      expect(verifier.verify(raw_body: raw_body, signature: nil)).to be false
    end

    it "returns false when not configured" do
      bad = described_class.new(secret: "")
      sig = expected_signature(raw_body)
      expect(bad.verify(raw_body: raw_body, signature: sig)).to be false
    end
  end
end
