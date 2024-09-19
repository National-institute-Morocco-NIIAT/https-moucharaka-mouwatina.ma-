require "rails_helper"

describe Budget::ContentBlock do
  let(:block) { build(:heading_content_block) }

  it "is valid" do
    expect(block).to be_valid
  end

  it "Heading is unique per locale" do
    heading_content_block_en = create(:heading_content_block, locale: "en")
    invalid_block = build(:heading_content_block,
                          heading: heading_content_block_en.heading, locale: "en")

    expect(invalid_block).not_to be_valid
    expect(invalid_block.errors.full_messages).to include("Heading has already been taken")

    valid_block = build(:heading_content_block,
                        heading: heading_content_block_en.heading, locale: "es")
    expect(valid_block).to be_valid
  end

  it "is not valid with a disabled locale" do
    Setting["locales.default"] = "pt-BR"
    Setting["locales.enabled"] = "nl pt-BR"

    block.locale = "en"

    expect(block).not_to be_valid
  end

  describe "#name" do
    it "uses the heading name" do
      block = Budget::ContentBlock.new(heading: Budget::Heading.new(name: "Central"))

      expect(block.name).to eq "Central"
    end

    it "returns nil on new records without heading" do
      block = Budget::ContentBlock.new

      expect(block.name).to be nil
    end
  end
end
