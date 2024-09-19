require "rails_helper"

describe RemoteTranslation, :remote_translations do
  let(:remote_translation) { build(:remote_translation, locale: :es) }

  it "is valid" do
    expect(remote_translation).to be_valid
  end

  it "is valid without error_message" do
    remote_translation.error_message = nil
    expect(remote_translation).to be_valid
  end

  it "is not valid without to" do
    remote_translation.locale = nil
    expect(remote_translation).not_to be_valid
  end

  it "is not valid without a remote_translatable_id" do
    remote_translation.remote_translatable_id = nil
    expect(remote_translation).not_to be_valid
  end

  it "is not valid without a remote_translatable_type" do
    remote_translation.remote_translatable_type = nil
    expect(remote_translation).not_to be_valid
  end

  it "is not valid without an available_locales" do
    remote_translation.locale = "unavailable_locale"
    expect(remote_translation).not_to be_valid
  end

  it "is not valid when exists a translation for locale" do
    remote_translation.locale = :en
    expect(remote_translation).not_to be_valid
  end

  it "checks available locales dynamically" do
    allow(RemoteTranslations::Microsoft::AvailableLocales)
      .to receive(:locales).and_return(["en"])

    expect(remote_translation).not_to be_valid

    allow(RemoteTranslations::Microsoft::AvailableLocales)
      .to receive(:locales).and_return(["es"])

    expect(remote_translation).to be_valid
  end

  it "is valid with a locale that uses a different name in the remote service" do
    allow(RemoteTranslations::Microsoft::AvailableLocales).to receive(:locales).and_call_original
    allow(RemoteTranslations::Microsoft::AvailableLocales).to receive(:remote_available_locales)
                                                          .and_return(["pt"])

    remote_translation.locale = :"pt-BR"

    expect(remote_translation).to be_valid
  end

  describe "#enqueue_remote_translation", :delay_jobs do
    it "after create enqueue Delayed Job" do
      expect { remote_translation.save }.to change { Delayed::Job.count }.by(1)
    end
  end
end
