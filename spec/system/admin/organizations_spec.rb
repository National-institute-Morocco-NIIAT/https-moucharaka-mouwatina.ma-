require "rails_helper"

describe "Admin::Organizations" do
  before do
    administrator = create(:user)
    create(:administrator, user: administrator)

    login_as(administrator)
  end

  context "Index" do
    scenario "shows info on organizations with hidden users" do
      troll = create(:user, email: "trol@troller.com")
      create(:organization, user: troll, name: "Greentroll")
      org = create(:organization, name: "Human Rights")
      troll.hide

      visit admin_organizations_path

      expect(page).to have_content("Human Rights")
      expect(page).to have_content(org.user.email)
      expect(page).not_to have_content("Greentroll")
      expect(page).not_to have_content("trol@troller.com")
      expect(page).to have_content("There is also one organisation with no users or with a hidden user")
    end
  end

  context "Search" do
    let(:user) { create(:user, email: "marley@humanrights.com", phone_number: "6764440002") }

    before do
      create(:organization, user: user, name: "Get up, Stand up")
    end

    scenario "returns no results if search term is empty" do
      visit admin_organizations_path
      expect(page).to have_content("Get up, Stand up")

      fill_in "search", with: "      "
      click_button "Search"

      expect(page).to have_current_path(search_admin_organizations_path, ignore_query: true)
      within("#search-results") do
        expect(page).not_to have_content("Get up, Stand up")
      end
    end

    scenario "finds by name" do
      visit search_admin_organizations_path
      expect(page).not_to have_content("Get up, Stand up")

      fill_in "search", with: "Up, sta"
      click_button "Search"

      within("#search-results") do
        expect(page).to have_content("Get up, Stand up")
      end
    end

    scenario "finds by users email" do
      visit search_admin_organizations_path
      expect(page).not_to have_content("Get up, Stand up")

      fill_in "search", with: user.email
      click_button "Search"

      within("#search-results") do
        expect(page).to have_content("Get up, Stand up")
      end
    end

    scenario "finds by users phone number" do
      visit search_admin_organizations_path
      expect(page).not_to have_content("Get up, Stand up")

      fill_in "search", with: user.phone_number
      click_button "Search"

      within("#search-results") do
        expect(page).to have_content("Get up, Stand up")
      end
    end
  end

  scenario "Pending organizations have links to verify and reject" do
    organization = create(:organization)

    visit admin_organizations_path
    within("#organization_#{organization.id}") do
      expect(page).to have_current_path(admin_organizations_path, ignore_query: true)
      expect(page).to have_button "Verify"
      expect(page).to have_button "Reject"

      click_button "Verify"
    end
    expect(page).to have_current_path(admin_organizations_path, ignore_query: true)

    click_link "Verified"

    within "tr", text: organization.name do
      expect(page).to have_content "Verified"
    end
  end

  scenario "Verified organizations have link to reject" do
    organization = create(:organization, :verified)

    visit admin_organizations_path

    click_link "Verified"

    within("#organization_#{organization.id}") do
      expect(page).to have_content "Verified"
      expect(page).to have_button "Reject"
      expect(page).not_to have_button "Verify"

      click_button "Reject"
    end
    expect(page).to have_current_path(admin_organizations_path, ignore_query: true)
    expect(page).not_to have_content organization.name

    click_link "Rejected"

    within "tr", text: organization.name do
      expect(page).to have_content "Rejected"
    end
  end

  scenario "Rejected organizations have link to verify" do
    organization = create(:organization, :rejected)

    visit admin_organizations_path
    click_link "Rejected"

    within("#organization_#{organization.id}") do
      expect(page).to have_button "Verify"
      expect(page).not_to have_button "Reject"

      click_button "Verify"
    end
    expect(page).to have_current_path(admin_organizations_path, ignore_query: true)
    expect(page).not_to have_content organization.name
    click_link "Verified"

    within "tr", text: organization.name do
      expect(page).to have_content "Verified"
    end
  end

  scenario "Current filter is properly highlighted" do
    visit admin_organizations_path
    expect(page).not_to have_link("Pending")
    expect(page).to have_link("All")
    expect(page).to have_link("Verified")
    expect(page).to have_link("Rejected")

    visit admin_organizations_path(filter: "all")
    expect(page).not_to have_link("All")
    expect(page).to have_link("Pending")
    expect(page).to have_link("Verified")
    expect(page).to have_link("Rejected")

    visit admin_organizations_path(filter: "pending")
    expect(page).to have_link("All")
    expect(page).not_to have_link("Pending")
    expect(page).to have_link("Verified")
    expect(page).to have_link("Rejected")

    visit admin_organizations_path(filter: "verified")
    expect(page).to have_link("All")
    expect(page).to have_link("Pending")
    expect(page).not_to have_link("Verified")
    expect(page).to have_link("Rejected")

    visit admin_organizations_path(filter: "rejected")
    expect(page).to have_link("All")
    expect(page).to have_link("Pending")
    expect(page).to have_link("Verified")
    expect(page).not_to have_link("Rejected")
  end

  scenario "Filtering organizations" do
    create(:organization, name: "Pending Organization")
    create(:organization, :rejected, name: "Rejected Organization")
    create(:organization, :verified, name: "Verified Organization")

    visit admin_organizations_path(filter: "all")
    expect(page).to have_content("Pending Organization")
    expect(page).to have_content("Rejected Organization")
    expect(page).to have_content("Verified Organization")

    visit admin_organizations_path(filter: "pending")
    expect(page).to have_content("Pending Organization")
    expect(page).not_to have_content("Rejected Organization")
    expect(page).not_to have_content("Verified Organization")

    visit admin_organizations_path(filter: "verified")
    expect(page).not_to have_content("Pending Organization")
    expect(page).not_to have_content("Rejected Organization")
    expect(page).to have_content("Verified Organization")

    visit admin_organizations_path(filter: "rejected")
    expect(page).not_to have_content("Pending Organization")
    expect(page).to have_content("Rejected Organization")
    expect(page).not_to have_content("Verified Organization")
  end

  scenario "Verifying organization links remembers parameters" do
    allow(Organization).to receive(:default_per_page).and_return(2)
    4.times { create(:organization) }

    visit admin_organizations_path(filter: "pending", page: 2)

    click_button "Verify", match: :first

    expect(page).to have_current_path(/filter=pending/)
    expect(page).to have_current_path(/page=2/)
  end
end
