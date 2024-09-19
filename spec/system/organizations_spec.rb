require "rails_helper"

describe "Organizations" do
  scenario "Organizations can be created" do
    admin = create(:administrator).user

    visit new_organization_registration_path

    fill_in "user_organization_attributes_name", with: "Greenpeace"
    fill_in "user_organization_attributes_responsible_name", with: "Dorothy Stowe"
    fill_in "user_email",                         with: "green@peace.com"
    fill_in "user_password",                      with: "greenpeace"
    fill_in "user_password_confirmation",         with: "greenpeace"
    check "user_terms_of_service"

    click_button "Register"

    expect(page).to have_content "You have been sent a message containing a verification link"

    login_as admin
    visit admin_users_path

    within "tr", text: "Greenpeace" do
      expect(page).to have_text "organization"
      expect(page).to have_text "level_1_user"
    end
  end

  scenario "Create with invisible_captcha honeypot field", :no_js do
    visit new_organization_registration_path

    fill_in "user_organization_attributes_name",  with: "robot"
    fill_in "user_address",                       with: "This is the honeypot field"
    fill_in "user_organization_attributes_responsible_name", with: "Robots are more responsible than humans"
    fill_in "user_email",                         with: "robot@robot.com"
    fill_in "user_password",                      with: "destroyallhumans"
    fill_in "user_password_confirmation",         with: "destroyallhumans"

    check "user_terms_of_service"

    click_button "Register"

    expect(page.status_code).to eq(200)
    expect(page.html).to be_empty
    expect(page).to have_current_path(organization_registration_path)
  end

  scenario "Create organization too fast" do
    allow(InvisibleCaptcha).to receive(:timestamp_threshold).and_return(Float::INFINITY)
    visit new_organization_registration_path
    fill_in "user_organization_attributes_name", with: "robot"
    fill_in "user_organization_attributes_responsible_name", with: "Robots are more responsible than humans"
    fill_in "user_email",                         with: "robot@robot.com"
    fill_in "user_password",                      with: "destroyallhumans"
    fill_in "user_password_confirmation",         with: "destroyallhumans"

    click_button "Register"

    expect(page).to have_content "Sorry, that was too quick! Please resubmit"

    expect(page).to have_current_path(new_organization_registration_path)
  end

  scenario "Errors on create" do
    visit new_organization_registration_path

    click_button "Register"

    expect(page).to have_content error_message
  end

  scenario "Shared links" do
    # visit new_user_registration_path
    # expect(page).to have_link "Sign up as an organization / collective"

    # visit new_organization_registration_path
    # expect(page).to have_link "Sign up"

    visit new_user_session_path

    expect(page).to have_link "Sign up"
    expect(page).not_to have_link "Sign up as an organization"
  end
end
