require "sessions_helper"

shared_examples "remotely_translatable" do |factory_name, path_name, path_arguments|
  let(:arguments) do
    path_arguments.transform_values { |path_to_value| resource.send(path_to_value) }
  end
  let(:path) { send(path_name, arguments) }
  let!(:resource) { create(factory_name) }

  before do
    Setting["feature.remote_translations"] = true
    available_locales_response = %w[de en es fr pt zh-Hans]
    expect(RemoteTranslations::Microsoft::AvailableLocales)
      .to receive(:locales).at_most(4).times
      .and_return(available_locales_response)
    allow(Rails.application.secrets).to receive(:microsoft_api_key).and_return("123")
  end

  context "Button to request remote translation" do
    scenario "should not be present when current locale translation exists" do
      visit path

      expect(page).not_to have_button("Translate page")
    end

    scenario "should be present when current locale translation does not exists" do
      visit path

      select "Español", from: "Language:"

      expect(page).to have_button("Traducir página")
    end

    scenario "should not be present when new current locale translation exists" do
      add_translations(resource, :es)
      visit path
      expect(page).not_to have_button("Translate page")

      select "Español", from: "Language:"

      expect(page).not_to have_button("Traducir página")
    end

    scenario "should not be present when there are no resources to translate", if: index_path?(path_name) do
      resource.destroy!
      visit path

      select "Español", from: "Language:"

      expect(page).not_to have_button("Traducir página")
    end

    describe "with delayed job active", :delay_jobs do
      scenario "should not be present when an equal RemoteTranslation is enqueued" do
        create(:remote_translation, remote_translatable: resource, locale: :es)
        visit path

        select "Español", from: "Language:"

        expect(page).not_to have_button("Traducir página")
        expect(page).to have_content "En un breve periodo de tiempo refrescando la página " \
                                     "podrá ver todo el contenido en su idioma"
      end
    end

    describe "should ignore missing translations on resource comments",
             if: index_path?(path_name) && commentable?(factory_name) do
      scenario "is not present when a resource translation exists but its comment has not tanslations" do
        add_translations(resource, :es)
        create(:comment, commentable: resource)
        visit path
        expect(page).not_to have_button("Translate page")

        select "Español", from: "Language:"

        expect(page).not_to have_button("Traducir página")
      end
    end

    describe "should evaluate missing translations on resource comments", if: show_path?(path_name) do
      scenario "display when exists resource translations but the comment does not have a translation" do
        add_translations(resource, :es)
        create(:comment, commentable: resource)
        visit path
        expect(page).not_to have_button("Translate page")

        select "Español", from: "Language:"

        expect(page).to have_button("Traducir página")
      end

      scenario "not display when exists resource translations but his comment has tanslations" do
        add_translations(resource, :es)
        create_comment_with_translations(resource, :es)
        visit path
        expect(page).not_to have_button("Translate page")

        select "Español", from: "Language:"

        expect(page).not_to have_button("Traducir página")
      end
    end

    describe "should evaluate missing translations on featured_debates", if: path_name == "debates_path" do
      scenario "display when exists featured_debates without tanslations" do
        add_translations(resource, :es)
        create_featured_debates
        visit path
        expect(page).not_to have_button("Translate page")

        select "Español", from: "Language:"

        expect(page).to have_button("Traducir página")
      end
    end

    describe "should evaluate missing translations on featured_proposals",
             if: path_name == "proposals_path" do
      scenario "display when exists featured_proposals without tanslations" do
        add_translations(resource, :es)
        create_featured_proposals
        visit path
        expect(page).not_to have_button("Translate page")

        select "Español", from: "Language:"

        expect(page).to have_button("Traducir página")
      end
    end
  end

  context "After click remote translations button" do
    describe "with delayed jobs", :delay_jobs do
      scenario "the remote translation button should not be present" do
        visit path
        select "Español", from: "Language:"

        click_button "Traducir página"

        expect(page).not_to have_button("Traducir página")
      end

      scenario "the remote translation is pending to translate" do
        visit path
        select "Español", from: "Language:"

        expect { click_button "Traducir página" }.to change { RemoteTranslation.count }.from(0).to(1)
      end

      scenario "should be present enqueued notice and informative text" do
        visit path
        select "Español", from: "Language:"

        click_button "Traducir página"

        expect(page).to have_content "Se han solicitado correctamente las traducciones."
        expect(page).to have_content "En un breve periodo de tiempo refrescando la página " \
                                     "podrá ver todo el contenido en su idioma"
      end

      scenario "should be present only informative text when user visit page with all content enqueued" do
        visit path
        select "Español", from: "Language:"
        click_button "Traducir página"
        expect(page).to have_content("Se han solicitado correctamente las traducciones.")

        visit path
        select "Español", from: "Idioma:"

        expect(page).not_to have_button "Traducir página"
        expect(page).not_to have_content "Se han solicitado correctamente las traducciones."
        expect(page).to have_content "En un breve periodo de tiempo refrescando la página " \
                                     "podrá ver todo el contenido en su idioma"
      end
    end

    describe "without delayed jobs" do
      scenario "the remote translation button should not be present" do
        response = generate_response(resource)
        expect_any_instance_of(RemoteTranslations::Microsoft::Client).to receive(:call).and_return(response)
        visit path
        select "Español", from: "Language:"

        click_button "Traducir página"

        expect(page).not_to have_button("Traducir página")
      end

      scenario "the remote translation has been translated and destoyed" do
        response = generate_response(resource)
        expect_any_instance_of(RemoteTranslations::Microsoft::Client).to receive(:call).and_return(response)
        visit path
        select "Español", from: "Language:"

        click_button "Traducir página"

        expect(page).not_to have_button "Traducir página"
        expect(RemoteTranslation.count).to eq(0)
        expect(resource.translations.count).to eq(2)
      end

      scenario "request a translation of an already translated text" do
        response = generate_response(resource)
        expect_any_instance_of(RemoteTranslations::Microsoft::Client).to receive(:call).and_return(response)

        in_browser(:one) do
          visit path
          select "Español", from: "Language:"

          expect(page).to have_button "Traducir página"
        end

        in_browser(:two) do
          visit path
          select "Español", from: "Language:"
          click_button "Traducir página"

          expect(page).to have_content "Se han solicitado correctamente las traducciones"
        end

        in_browser(:one) do
          click_button "Traducir página"

          expect(page).not_to have_button "Traducir página"
        end
      end
    end
  end
end

def add_translations(resource, locale)
  new_translation = resource.translations.first.dup
  new_translation.update!(locale: locale)
  resource
end

def create_comment_with_translations(resource, locale)
  comment = create(:comment, commentable: resource)
  add_translations(comment, locale)
end

def index_path?(path)
  ["debates_path", "proposals_path", "root_path", "budget_investments_path"].include?(path)
end

def show_path?(path)
  !index_path?(path)
end

def commentable?(factory_name)
  Comment::COMMENTABLE_TYPES.include?(FactoryBot.factories[factory_name].build_class.to_s)
end

def generate_response(resource)
  field_text = Faker::Lorem.characters(number: 10)
  resource.translated_attribute_names.map { field_text }
end
