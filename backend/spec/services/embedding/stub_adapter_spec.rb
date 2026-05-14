require "rails_helper"

RSpec.describe Embedding::StubAdapter do
  subject(:adapter) { described_class.new }

  it "returns 1024-dimensional vectors" do
    vec = adapter.embed(["hello"]).first
    expect(vec.size).to eq(1024)
  end

  it "is deterministic for the same input" do
    a = adapter.embed(["foo"]).first
    b = adapter.embed(["foo"]).first
    expect(a).to eq(b)
  end

  it "produces different vectors for different inputs" do
    a = adapter.embed(["foo"]).first
    b = adapter.embed(["bar"]).first
    expect(a).not_to eq(b)
  end

  it "L2-normalizes vectors" do
    vec = adapter.embed(["normalize me"]).first
    norm = Math.sqrt(vec.sum { |x| x * x })
    expect(norm).to be_within(1e-6).of(1.0)
  end
end
