require "rails_helper"

describe Setting do
  before do
    Setting["official_level_1_name"] = "Stormtrooper"
  end

  it "returns the overriden setting" do
    expect(Setting["official_level_1_name"]).to eq("Stormtrooper")
  end

  it "returns nil" do
    expect(Setting["undefined_key"]).to be nil
  end

  it "persists a setting on the db" do
    expect(Setting.where(key: "official_level_1_name", value: "Stormtrooper")).to exist
  end

  describe "#prefix" do
    it "returns the prefix of its key" do
      expect(Setting.create!(key: "prefix.key_name").prefix).to eq "prefix"
    end

    it "returns the whole key for a non prefixed key" do
      expect(Setting.create!(key: "key_name").prefix).to eq "key_name"
    end
  end

  describe "#enabled?" do
    it "is true if value is present" do
      setting = Setting.create!(key: "feature.whatever", value: 1)
      expect(setting.enabled?).to be true

      setting.value = "true"
      expect(setting.enabled?).to be true

      setting.value = "whatever"
      expect(setting.enabled?).to be true
    end

    it "is false if value is blank" do
      setting = Setting.create!(key: "feature.whatever")
      expect(setting.enabled?).to be false

      setting.value = ""
      expect(setting.enabled?).to be false
    end
  end

  describe "#content_type_group" do
    it "returns the group for content_types settings" do
      images =    Setting.create!(key: "update.images.content_types")
      documents = Setting.create!(key: "update.documents.content_types")

      expect(images.content_type_group).to    eq "images"
      expect(documents.content_type_group).to eq "documents"
    end
  end

  describe ".rename_key" do
    it "renames the setting keeping the original value and deletes the old setting" do
      Setting["old_key"] = "old_value"

      Setting.rename_key from: "old_key", to: "new_key"

      expect(Setting.where(key: "new_key", value: "old_value")).to exist
      expect(Setting.where(key: "old_key")).not_to exist
    end

    it "initialize the setting with null value if old key doesn't exist" do
      expect(Setting.where(key: "old_key")).not_to exist

      Setting.rename_key from: "old_key", to: "new_key"

      expect(Setting.where(key: "new_key", value: nil)).to exist
      expect(Setting.where(key: "old_key")).not_to exist
    end

    it "does not change value if new key already exists, but deletes setting with old key" do
      Setting["new_key"] = "new_value"
      Setting["old_key"] = "old_value"

      Setting.rename_key from: "old_key", to: "new_key"

      expect(Setting["new_key"]).to eq "new_value"
      expect(Setting.where(key: "old_key")).not_to exist
    end
  end

  describe ".remove" do
    it "deletes the setting by given key" do
      expect(Setting.where(key: "official_level_1_name")).to exist

      Setting.remove("official_level_1_name")

      expect(Setting.where(key: "official_level_1_name")).not_to exist
    end

    it "does nothing if key doesn't exists" do
      all_settings = Setting.all

      Setting.remove("not_existing_key")

      expect(Setting.all).to eq all_settings
    end
  end

  describe ".accepted_content_types_for" do
    it "returns the formats accepted according to the setting value" do
      Setting["uploads.images.content_types"] = "image/jpeg image/gif"
      Setting["uploads.documents.content_types"] = "application/pdf application/msword"

      expect(Setting.accepted_content_types_for("images")).to    eq ["jpg", "gif"]
      expect(Setting.accepted_content_types_for("documents")).to eq ["pdf", "doc"]
    end

    it "returns empty array if setting does't exist" do
      Setting.remove("uploads.images.content_types")
      Setting.remove("uploads.documents.content_types")

      expect(Setting.accepted_content_types_for("images")).to    be_empty
      expect(Setting.accepted_content_types_for("documents")).to be_empty
    end
  end

  describe ".default_org_name" do
    it "returns the main org name for the default tenant" do
      expect(Setting.default_org_name).to eq "CONSUL DEMOCRACY"
    end

    it "returns the tenant name for other tenants" do
      insert(:tenant, schema: "new", name: "New Institution")
      allow(Tenant).to receive(:current_schema).and_return("new")

      expect(Setting.default_org_name).to eq "New Institution"
    end
  end

  describe ".default_mailer_from_address" do
    before { allow(Tenant).to receive(:default_host).and_return("consuldemocracy.org") }

    it "uses the default host for the default tenant" do
      expect(Setting.default_mailer_from_address).to eq "noreply@consuldemocracy.org"
    end

    it "uses the tenant host for other tenants" do
      allow(Tenant).to receive(:current_schema).and_return("new")

      expect(Setting.default_mailer_from_address).to eq "noreply@new.consuldemocracy.org"
    end

    context "empty default host" do
      before { allow(Tenant).to receive(:default_host).and_return("") }

      it "uses consuldemocracy.dev as host" do
        expect(Setting.default_mailer_from_address).to eq "noreply@consuldemocracy.dev"
      end
    end
  end

  describe ".add_new_settings" do
    context "default settings with strings" do
      before do
        allow(Setting).to receive(:defaults).and_return({ stub: "stub" })
      end

      it "creates the setting if it doesn't exist" do
        expect(Setting.where(key: :stub)).to be_empty

        Setting.add_new_settings

        expect(Setting.where(key: :stub)).not_to be_empty
        expect(Setting.find_by(key: :stub).value).to eq "stub"
      end

      it "doesn't modify custom values" do
        Setting["stub"] = "custom"

        Setting.add_new_settings

        expect(Setting.find_by(key: :stub).value).to eq "custom"
      end

      it "doesn't modify custom nil values" do
        Setting["stub"] = nil

        Setting.add_new_settings

        expect(Setting.find_by(key: :stub).value).to be nil
      end
    end

    context "nil default settings" do
      before do
        allow(Setting).to receive(:defaults).and_return({ stub: nil })
      end

      it "creates the setting if it doesn't exist" do
        expect(Setting.where(key: :stub)).to be_empty

        Setting.add_new_settings

        expect(Setting.where(key: :stub)).not_to be_empty
        expect(Setting.find_by(key: :stub).value).to be nil
      end

      it "doesn't modify custom values" do
        Setting["stub"] = "custom"

        Setting.add_new_settings

        expect(Setting.find_by(key: :stub).value).to eq "custom"
      end
    end
  end

  describe ".force_presence_date_of_birth?" do
    it "return false when feature remote_census is not active" do
      Setting["feature.remote_census"] = false

      expect(Setting.force_presence_date_of_birth?).to be false
    end

    it "return false when feature remote_census is active and date_of_birth is nil" do
      Setting["feature.remote_census"] = true
      Setting["remote_census.request.date_of_birth"] = nil

      expect(Setting.force_presence_date_of_birth?).to be false
    end

    it "return true when feature remote_census is active and date_of_birth is empty" do
      Setting["feature.remote_census"] = true
      Setting["remote_census.request.date_of_birth"] = "some.value"

      expect(Setting.force_presence_date_of_birth?).to be true
    end
  end

  describe ".force_presence_postal_code?" do
    it "return false when feature remote_census is not active" do
      Setting["feature.remote_census"] = false

      expect(Setting.force_presence_postal_code?).to be false
    end

    it "return false when feature remote_census is active and postal_code is nil" do
      Setting["feature.remote_census"] = true
      Setting["remote_census.request.postal_code"] = nil

      expect(Setting.force_presence_postal_code?).to be false
    end

    it "return true when feature remote_census is active and postal_code is empty" do
      Setting["feature.remote_census"] = true
      Setting["remote_census.request.postal_code"] = "some.value"

      expect(Setting.force_presence_postal_code?).to be true
    end
  end

  describe ".available_locales" do
    before { allow(I18n).to receive_messages(default_locale: :de, available_locales: %i[de en es pt-BR]) }

    it "uses I18n available locales by default" do
      Setting["locales.enabled"] = ""

      expect(Setting.enabled_locales).to eq %i[de en es pt-BR]
    end

    it "defines available locales with a space-separated list" do
      Setting["locales.enabled"] = "de es"

      expect(Setting.enabled_locales).to eq %i[de es]
    end

    it "handles locales which include a dash" do
      Setting["locales.enabled"] = "de en pt-BR"

      expect(Setting.enabled_locales).to eq %i[de en pt-BR]
    end

    it "adds the default locale to the list of available locales" do
      Setting["locales.enabled"] = "en es"

      expect(Setting.enabled_locales).to eq %i[de en es]
    end

    it "ignores extra whitespace between locales" do
      Setting["locales.enabled"] = " de  en   pt-BR "

      expect(Setting.enabled_locales).to eq %i[de en pt-BR]
    end

    it "ignores locales which aren't available" do
      Setting["locales.enabled"] = "de es en-US fr zh-CN"

      expect(Setting.enabled_locales).to eq %i[de es]
    end

    it "ignores words that don't make sense in this context" do
      Setting["locales.enabled"] = "yes de 1234 en SuperCool"

      expect(Setting.enabled_locales).to eq %i[de en]
    end

    it "uses I18n available locales when no locale is available" do
      Setting["locales.enabled"] = "nl fr zh-CN"

      expect(Setting.enabled_locales).to eq %i[de en es pt-BR]
    end
  end

  describe ".default_locale" do
    before { allow(I18n).to receive_messages(default_locale: :en, available_locales: %i[de en es pt-BR]) }

    it "uses I18n default locale by default" do
      Setting["locales.default"] = ""

      expect(Setting.default_locale).to eq :en
    end

    it "allows defining the default locale" do
      Setting["locales.default"] = "de"

      expect(Setting.default_locale).to eq :de
    end

    it "handles locales which include a dash" do
      Setting["locales.default"] = "pt-BR"

      expect(Setting.default_locale).to eq :"pt-BR"
    end

    it "ignores extra whitespace in the locale name" do
      Setting["locales.default"] = " es "

      expect(Setting.default_locale).to eq :es
    end

    it "ignores locales which aren't available" do
      Setting["locales.default"] = "fr"

      expect(Setting.default_locale).to eq :en
    end

    it "ignores an array of several locales" do
      Setting["locales.default"] = "de es"

      expect(Setting.default_locale).to eq :en
    end
  end
end
