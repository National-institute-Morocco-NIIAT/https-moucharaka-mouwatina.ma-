require "rails_helper"

RSpec.describe I18nContent do
  let(:i18n_content) { build(:i18n_content, key: "awe.so.me") }

  it "is valid" do
    expect(i18n_content).to be_valid
  end

  it "is not valid if key is not unique" do
    create(:i18n_content, key: "awe.so.me")

    expect(i18n_content).not_to be_valid
    expect(i18n_content.errors.size).to eq(1)
  end

  context "Globalize" do
    it "translates key into multiple languages" do
      key = "devise_views.mailer.confirmation_instructions.welcome"
      welcome = build(:i18n_content, key: key, value_en: "Welcome", value_es: "Bienvenido")

      expect(welcome.value_en).to eq("Welcome")
      expect(welcome.value_es).to eq("Bienvenido")
    end

    it "responds to locales defined on model" do
      expect(i18n_content).to respond_to(:value_en)
      expect(i18n_content).to respond_to(:value_es)
      expect(i18n_content).not_to respond_to(:value_wl)
    end

    it "returns nil if translations are not available" do
      expect(i18n_content.value_en).to eq("Text in english")
      expect(i18n_content.value_es).to eq("Texto en español")
      expect(i18n_content.value_nl).to be nil
      expect(i18n_content.value_fr).to be nil
    end

    it "responds accordingly to the current locale" do
      expect(i18n_content.value).to eq("Text in english")

      I18n.with_locale(:es) { expect(i18n_content.value).to eq("Texto en español") }
    end
  end

  describe "#flat_hash" do
    it "uses one parameter" do
      expect(I18nContent.flat_hash(nil)).to eq({ nil => nil })
      expect(I18nContent.flat_hash("string")).to eq({ nil => "string" })
      expect(I18nContent.flat_hash({ w: "string" })).to eq({ "w" => "string" })
      expect(I18nContent.flat_hash({ w: { p: "string" }})).to eq({ "w.p" => "string" })
    end

    it "uses the first two parameters" do
      expect(I18nContent.flat_hash("string", "f")).to eq({ "f" => "string" })
      expect(I18nContent.flat_hash(nil, "f")).to eq({ "f" => nil })
      expect(I18nContent.flat_hash({ w: "string" }, "f")).to eq({ "f.w" => "string" })
      expect(I18nContent.flat_hash({ w: { p: "string" }}, "f")).to eq({ "f.w.p" => "string" })
    end

    it "uses the first and last parameters" do
      expect { I18nContent.flat_hash("string", nil, "not hash") }.to raise_error(NoMethodError)

      expect(I18nContent.flat_hash(nil, nil, { q: "other string" })).to eq({
        q: "other string",
        nil => nil
      })

      expect(I18nContent.flat_hash({ w: "string" }, nil, { q: "other string" })).to eq({
        q: "other string",
        "w" => "string"
      })

      expect(I18nContent.flat_hash({ w: { p: "string" }}, nil, { q: "other string" })).to eq({
        q: "other string",
        "w.p" => "string"
      })
    end

    it "uses all parameters" do
      expect { I18nContent.flat_hash("string", "f", "not hash") }.to raise_error NoMethodError

      expect(I18nContent.flat_hash(nil, "f", { q: "other string" })).to eq({
        q: "other string",
        "f" => nil
      })

      expect(I18nContent.flat_hash({ w: "string" }, "f", { q: "other string" })).to eq({
        q: "other string",
        "f.w" => "string"
      })

      expect(I18nContent.flat_hash({ w: { p: "string" }}, "f", { q: "other string" })).to eq({
        q: "other string",
        "f.w.p" => "string"
      })
    end
  end

  describe ".translations_hash" do
    let!(:content) { create(:i18n_content, key: "great", value_en: "Custom great", value_es: nil) }

    it "gets the translations" do
      expect(I18nContent.translations_hash(:en)["great"]).to eq "Custom great"
    end

    it "does not use fallbacks, so YAML files will be used instead" do
      expect(I18nContent.translations_hash(:es)["great"]).to be nil
    end

    it "gets new translations after values are cached" do
      expect(I18nContent.translations_hash(:en)["great"]).to eq "Custom great"

      create(:i18n_content, key: "amazing", value_en: "Custom amazing")

      expect(I18nContent.translations_hash(:en)["great"]).to eq "Custom great"
      expect(I18nContent.translations_hash(:en)["amazing"]).to eq "Custom amazing"
    end

    it "gets the updated translation after values are cached" do
      expect(I18nContent.translations_hash(:en)["great"]).to eq "Custom great"

      content.update!(value_en: "New great")

      expect(I18nContent.translations_hash(:en)["great"]).to eq "New great"
    end

    it "does not get removed translations after values are cached" do
      expect(I18nContent.translations_hash(:en)["great"]).to eq "Custom great"

      I18nContent.delete_all

      expect(I18nContent.translations_hash(:en)["great"]).to be nil
    end
  end

  describe ".update" do
    it "stores new keys with a different translation" do
      I18nContent.update([{ id: "shared.yes", values: { "value_en" => "Oh, yeah" }}])

      expect(I18nContent.count).to eq 1
      expect(I18nContent.first.translations.count).to eq 1
      expect(I18nContent.first.value).to eq "Oh, yeah"
    end

    it "does not store new keys with the default translation" do
      I18nContent.update([{ id: "shared.yes", values: { "value_en" => "Yes" }}])

      expect(I18nContent.all).to be_empty
    end

    it "updates existing keys with the default translation" do
      I18nContent.create!(key: "shared.yes", value_en: "Oh, yeah")

      I18nContent.update([{ id: "shared.yes", values: { "value_en" => "Yes" }}])

      expect(I18nContent.count).to eq 1
      expect(I18nContent.first.translations.count).to eq 1
      expect(I18nContent.first.value).to eq "Yes"
    end

    it "does not store new keys for disabled translations" do
      Setting["locales.default"] = "es"
      Setting["locales.enabled"] = "es"

      I18nContent.update([{ id: "shared.yes", values: { "value_en" => "Oh, yeah" }}])

      expect(I18nContent.all).to be_empty
    end

    it "uses different enabled translations when given a parameter" do
      Setting["locales.enabled"] = "en es"

      I18nContent.update([{ id: "shared.yes", values: { "value_en" => "Oh, yeah" }}], [:es])

      expect(I18nContent.all).to be_empty
    end
  end
end
