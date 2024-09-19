require "rails_helper"

describe "Admin" do
  let(:user) { create(:user) }

  scenario "Access as regular user is not authorized" do
    login_as(user)
    visit admin_root_path

    expect(page).not_to have_current_path(admin_root_path)
    expect(page).to have_current_path(root_path)
    expect(page).to have_content "You do not have permission to access this page"
  end

  scenario "Access as moderator is not authorized" do
    create(:moderator, user: user)
    login_as(user)
    visit admin_root_path

    expect(page).not_to have_current_path(admin_root_path)
    expect(page).to have_current_path(root_path)
    expect(page).to have_content "You do not have permission to access this page"
  end

  scenario "Access as valuator is not authorized" do
    create(:valuator, user: user)
    login_as(user)
    visit admin_root_path

    expect(page).not_to have_current_path(admin_root_path)
    expect(page).to have_current_path(root_path)
    expect(page).to have_content "You do not have permission to access this page"
  end

  scenario "Access as manager is not authorized" do
    create(:manager, user: user)
    login_as(user)
    visit admin_root_path

    expect(page).not_to have_current_path(admin_root_path)
    expect(page).to have_current_path(root_path)
    expect(page).to have_content "You do not have permission to access this page"
  end

  scenario "Access as SDG manager is not authorized" do
    create(:sdg_manager, user: user)
    login_as(user)
    visit admin_root_path

    expect(page).not_to have_current_path(admin_root_path)
    expect(page).to have_current_path(root_path)
    expect(page).to have_content "You do not have permission to access this page"
  end

  scenario "Access as poll officer is not authorized" do
    login_as(create(:poll_officer).user)
    visit admin_root_path

    expect(page).not_to have_current_path(admin_root_path)
    expect(page).to have_current_path(root_path)
    expect(page).to have_content "You do not have permission to access this page"
  end

  scenario "Access as administrator is authorized", :admin do
    visit root_path

    click_link "Menu"
    click_link "Administration"

    expect(page).to have_current_path(admin_root_path)
    expect(page).to have_css "#admin_menu"
    expect(page).not_to have_css "#moderation_menu"
    expect(page).not_to have_css "#valuation_menu"
    expect(page).not_to have_content "You do not have permission to access this page"
  end

  scenario "Admin menu does not hide active elements", :admin do
    visit admin_budgets_path

    within("#admin_menu") do
      expect(page).to have_link "Participatory budgets"

      click_button "Site content"

      expect(page).to have_link "Participatory budgets"
    end
  end

  describe "Menu button", :admin do
    scenario "is not present on large screens" do
      visit admin_root_path

      expect(page).not_to have_button "Menu"
    end

    scenario "toggles the menu on small screens", :small_window do
      visit admin_root_path

      expect(page).not_to have_link "My account"

      click_button "Menu"

      expect(page).to have_link "My account"
    end
  end
end
