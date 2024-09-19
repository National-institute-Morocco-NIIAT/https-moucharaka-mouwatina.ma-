require "rails_helper"

describe Shared::GlobalizeLocalesComponent do
  describe "Language selector" do
    it "only includes enabled locales" do
      Setting["locales.enabled"] = "en nl"

      I18n.with_locale(:en) do
        render_inline Shared::GlobalizeLocalesComponent.new

        expect(page).to have_select options: ["Choose language", "English"]
      end

      I18n.with_locale(:es) do
        render_inline Shared::GlobalizeLocalesComponent.new

        expect(page).to have_select options: ["Seleccionar idioma"]
      end
    end
  end

  describe "links to destroy languages" do
    it "only includes enabled locales" do
      Setting["locales.enabled"] = "en nl"

      I18n.with_locale(:en) do
        render_inline Shared::GlobalizeLocalesComponent.new

        expect(page).to have_css "a[data-locale]", count: 1
      end

      I18n.with_locale(:es) do
        render_inline Shared::GlobalizeLocalesComponent.new

        expect(page).not_to have_css "a[data-locale]"
      end
    end
  end

  describe "Add language selector" do
    it "only includes enabled locales" do
      Setting["locales.enabled"] = "en nl"

      render_inline Shared::GlobalizeLocalesComponent.new

      expect(page).to have_select options: ["Add language", "English", "Nederlands"]
    end
  end
end
