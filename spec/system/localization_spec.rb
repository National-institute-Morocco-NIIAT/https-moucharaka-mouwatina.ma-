require "rails_helper"

describe "Localization" do
  scenario "Wrong locale" do
    I18n.with_locale(:es) do
      create(:widget_card, title: "Bienvenido a CONSUL",
                           description: "Software libre para la participación ciudadana.",
                           link_text: "Más información",
                           link_url: "http://consuldemocracy.org/",
                           header: true)
    end

    visit root_path(locale: :es)
    visit root_path(locale: :klingon)

    expect(page).to have_text("Bienvenido a CONSUL")
  end

  scenario "Changing the locale" do
    visit "/"
    select "Español", from: "Language:"

    expect(page).not_to have_select "Language:"
    expect(page).to have_select "Idioma:", selected: "Español"
  end

  scenario "Keeps query parameters while using protected redirects" do
    visit "/debates?order=created_at&host=evil.dev"

    select "Español", from: "Language:"

    expect(current_host).to eq "http://127.0.0.1"
    expect(page).to have_current_path "/debates?locale=es&order=created_at"
  end

  scenario "uses default locale when session locale has disappeared" do
    default_locales = I18n.available_locales

    visit root_path(locale: :es)

    expect(page).to have_content "Entrar"

    begin
      I18n.available_locales = default_locales - [:es]

      visit root_path

      expect(page).to have_content "Sign in"
    ensure
      I18n.available_locales = default_locales
    end
  end
end
