require "rails_helper"

describe "Moderate budget investments" do
  let(:budget)      { create(:budget) }
  let(:heading)     { create(:budget_heading, budget: budget, price: 666666) }
  let(:mod)         { create(:moderator) }
  let(:author)      { create(:user, username: "Julia") }
  let!(:investment) { create(:budget_investment, heading: heading, author: author) }

  scenario "Hiding an investment" do
    login_as(mod.user)
    visit budget_investment_path(budget, investment)

    accept_confirm("Are you sure? Hide \"#{investment.title}\"") { click_button "Hide" }

    expect(page).to have_css(".faded", count: 2)

    visit budget_investments_path(budget.id, heading_id: heading.id)

    expect(page).not_to have_content(investment.title)
  end

  scenario "Hiding an investment's author" do
    login_as(mod.user)
    visit budget_investment_path(budget, investment)

    accept_confirm("Are you sure? This will hide the user \"Julia\" and all their contents.") do
      click_button "Block author"
    end

    expect(page).to have_current_path(budget_investments_path(budget))
    expect(page).not_to have_content(investment.title)
  end

  scenario "Can not hide own investment" do
    investment.update!(author: mod.user)
    login_as(mod.user)

    visit budget_investment_path(budget, investment)

    within "#budget_investment_#{investment.id}" do
      expect(page).not_to have_button "Hide"
      expect(page).not_to have_button "Block author"
    end
  end

  describe "/moderation/ screen" do
    before do
      login_as(mod.user)
    end

    describe "moderate in bulk" do
      describe "When an investment has been selected for moderation" do
        before do
          visit moderation_budget_investments_path
          click_link "All"

          within("#investment_#{investment.id}") do
            check "budget_investment_#{investment.id}_check"
          end
        end

        scenario "Hide the investment" do
          accept_confirm("Are you sure? Hide budget investments") do
            click_button "Hide budget investments"
          end

          expect(page).not_to have_css("#investment_#{investment.id}")

          click_link "Block users"
          fill_in "email or name of user", with: investment.author.email
          click_button "Search"

          within "tr", text: investment.author.name do
            expect(page).to have_button "Block"
          end
        end

        scenario "Block the author" do
          accept_confirm("Are you sure? Block authors") { click_button "Block authors" }

          expect(page).not_to have_css("#investment_#{investment.id}")

          click_link "Block users"
          fill_in "email or name of user", with: investment.author.email
          click_button "Search"

          within "tr", text: investment.author.name do
            expect(page).to have_content "Blocked"
          end
        end

        scenario "Ignore the investment", :no_js do
          click_button "Mark as viewed"

          investment.reload

          expect(investment).to be_ignored_flag
          expect(investment).not_to be_hidden
          expect(investment.author).not_to be_hidden
        end
      end

      scenario "select all/none" do
        create_list(:budget_investment, 2, heading: heading, author: create(:user))

        visit moderation_budget_investments_path
        click_link "All"

        expect(page).to have_field type: :checkbox, count: 3

        within(".check-all-none") { click_button "Select all" }

        expect(all(:checkbox)).to all(be_checked)

        within(".check-all-none") { click_button "Select none" }

        all(:checkbox).each { |checkbox| expect(checkbox).not_to be_checked }
      end

      scenario "remembering page, filter and order" do
        stub_const("#{ModerateActions}::PER_PAGE", 2)
        create_list(:budget_investment, 4, heading: heading, author: create(:user))

        visit moderation_budget_investments_path(filter: "all", page: "2", order: "created_at")

        accept_confirm("Are you sure? Mark as viewed") { click_button "Mark as viewed" }

        expect(page).to have_link "Most recent", class: "is-active"
        expect(page).to have_link "Most flagged"

        expect(page).to have_current_path(/filter=all/)
        expect(page).to have_current_path(/page=2/)
        expect(page).to have_current_path(/order=created_at/)
      end
    end

    scenario "Current filter is properly highlighted" do
      visit moderation_budget_investments_path
      expect(page).not_to have_link("Pending")
      expect(page).to have_link("All")
      expect(page).to have_link("Marked as viewed")

      visit moderation_budget_investments_path(filter: "all")
      expect(page).not_to have_link("All")
      expect(page).to have_link("Pending")
      expect(page).to have_link("Marked as viewed")

      visit moderation_budget_investments_path(filter: "pending_flag_review")
      expect(page).to have_link("All")
      expect(page).not_to have_link("Pending")
      expect(page).to have_link("Marked as viewed")

      visit moderation_budget_investments_path(filter: "with_ignored_flag")
      expect(page).to have_link("All")
      expect(page).to have_link("Pending")
      expect(page).not_to have_link("Marked as viewed")
    end

    scenario "Filtering investments" do
      create(:budget_investment, heading: heading, title: "Books investment")
      create(:budget_investment, :flagged, heading: heading, title: "Non-selected investment")
      create(:budget_investment, :hidden, heading: heading, title: "Hidden investment")
      create(:budget_investment, :flagged, :with_ignored_flag, heading: heading, title: "Ignored investment")

      visit moderation_budget_investments_path(filter: "all")

      expect(page).to have_content("Books investment")
      expect(page).to have_content("Non-selected investment")
      expect(page).not_to have_content("Hidden investment")
      expect(page).to have_content("Ignored investment")

      visit moderation_budget_investments_path(filter: "pending_flag_review")

      expect(page).not_to have_content("Books investment")
      expect(page).to have_content("Non-selected investment")
      expect(page).not_to have_content("Hidden investment")
      expect(page).not_to have_content("Ignored investment")

      visit moderation_budget_investments_path(filter: "with_ignored_flag")

      expect(page).not_to have_content("Books investment")
      expect(page).not_to have_content("Non-selected investment")
      expect(page).not_to have_content("Hidden investment")
      expect(page).to have_content("Ignored investment")
    end

    scenario "sorting investments" do
      flagged_investment = create(
        :budget_investment,
        heading: heading,
        title: "Flagged investment",
        created_at: 1.day.ago,
        flags_count: 5
      )

      flagged_new_investment = create(
        :budget_investment,
        heading: heading,
        title: "Flagged new investment",
        created_at: 12.hours.ago,
        flags_count: 3
      )

      latest_investment = create(
        :budget_investment,
        heading: heading,
        title: "Latest investment",
        created_at: Time.current
      )

      visit moderation_budget_investments_path(order: "created_at")

      expect(flagged_new_investment.title).to appear_before(flagged_investment.title)

      visit moderation_budget_investments_path(order: "flags")

      expect(flagged_investment.title).to appear_before(flagged_new_investment.title)

      visit moderation_budget_investments_path(filter: "all", order: "created_at")

      expect(latest_investment.title).to appear_before(flagged_new_investment.title)
      expect(flagged_new_investment.title).to appear_before(flagged_investment.title)

      visit moderation_budget_investments_path(filter: "all", order: "flags")

      expect(flagged_investment.title).to appear_before(flagged_new_investment.title)
      expect(flagged_new_investment.title).to appear_before(latest_investment.title)
    end
  end
end
