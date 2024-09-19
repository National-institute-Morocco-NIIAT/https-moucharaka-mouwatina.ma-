require "rails_helper"

describe "Moderate proposals" do
  scenario "Hide" do
    citizen   = create(:user)
    proposal  = create(:proposal)
    moderator = create(:moderator)

    login_as(moderator.user)
    visit proposal_path(proposal)

    within("#proposal_#{proposal.id}") do
      accept_confirm("Are you sure? Hide") { click_button "Hide" }
    end

    expect(page).to have_css("#proposal_#{proposal.id}.faded")

    login_as(citizen)
    visit proposals_path

    expect(page).to have_css(".proposal", count: 0)
  end

  scenario "Can hide own proposal" do
    moderator = create(:moderator)
    proposal = create(:proposal, author: moderator.user)

    login_as(moderator.user)
    visit proposal_path(proposal)

    within("#proposal_#{proposal.id}") do
      expect(page).to have_button "Hide"
      expect(page).not_to have_button "Block author"
    end
  end

  describe "/moderation/ screen" do
    before do
      moderator = create(:moderator)
      login_as(moderator.user)
    end

    describe "moderate in bulk" do
      let!(:proposal) { create(:proposal) }

      describe "When a proposal has been selected for moderation" do
        before do
          visit moderation_proposals_path
          click_link "All"

          within("#proposal_#{proposal.id}") do
            check "proposal_#{proposal.id}_check"
          end
        end

        scenario "Hide the proposal" do
          accept_confirm("Are you sure? Hide proposals") { click_button "Hide proposals" }

          expect(page).not_to have_css("#proposal_#{proposal.id}")

          click_link "Block users"
          fill_in "email or name of user", with: proposal.author.email
          click_button "Search"

          within "tr", text: proposal.author.name do
            expect(page).to have_button "Block"
          end
        end

        scenario "Block the author" do
          accept_confirm("Are you sure? Block authors") { click_button "Block authors" }

          expect(page).not_to have_css("#proposal_#{proposal.id}")

          click_link "Block users"
          fill_in "email or name of user", with: proposal.author.email
          click_button "Search"

          within "tr", text: proposal.author.name do
            expect(page).to have_content "Blocked"
          end
        end

        scenario "Ignore the proposal", :no_js do
          click_button "Mark as viewed"

          expect(proposal.reload).to be_ignored_flag
          expect(proposal.reload).not_to be_hidden
          expect(proposal.author).not_to be_hidden
        end
      end

      scenario "select all/none" do
        create_list(:proposal, 2)

        visit moderation_proposals_path
        click_link "All"

        expect(page).to have_field type: :checkbox, count: 3

        within(".check-all-none") { click_button "Select all" }

        expect(all(:checkbox)).to all(be_checked)

        within(".check-all-none") { click_button "Select none" }

        all(:checkbox).each { |checkbox| expect(checkbox).not_to be_checked }
      end

      scenario "remembering page, filter and order" do
        stub_const("#{ModerateActions}::PER_PAGE", 2)
        create_list(:proposal, 4)

        visit moderation_proposals_path(filter: "all", page: "2", order: "created_at")

        accept_confirm("Are you sure? Mark as viewed") { click_button "Mark as viewed" }

        expect(page).to have_link "Most recent", class: "is-active"
        expect(page).to have_link "Most flagged"

        expect(page).to have_current_path(/filter=all/)
        expect(page).to have_current_path(/page=2/)
        expect(page).to have_current_path(/order=created_at/)
      end
    end

    scenario "Current filter is properly highlighted" do
      visit moderation_proposals_path
      expect(page).not_to have_link("Pending")
      expect(page).to have_link("All")
      expect(page).to have_link("Mark as viewed")

      visit moderation_proposals_path(filter: "all")
      expect(page).not_to have_link("All")
      expect(page).to have_link("Pending review")
      expect(page).to have_link("Mark as viewed")

      visit moderation_proposals_path(filter: "pending_flag_review")
      expect(page).to have_link("All")
      expect(page).not_to have_link("Pending")
      expect(page).to have_link("Mark as viewed")

      visit moderation_proposals_path(filter: "with_ignored_flag")
      expect(page).to have_link("All")
      expect(page).to have_link("Pending review")
      expect(page).not_to have_link("Marked as viewed")
    end

    scenario "Filtering proposals" do
      create(:proposal, title: "Regular proposal")
      create(:proposal, :flagged, title: "Pending proposal")
      create(:proposal, :hidden, title: "Hidden proposal")
      create(:proposal, :flagged, :with_ignored_flag, title: "Ignored proposal")

      visit moderation_proposals_path(filter: "all")
      expect(page).to have_content("Regular proposal")
      expect(page).to have_content("Pending proposal")
      expect(page).not_to have_content("Hidden proposal")
      expect(page).to have_content("Ignored proposal")

      visit moderation_proposals_path(filter: "pending_flag_review")
      expect(page).not_to have_content("Regular proposal")
      expect(page).to have_content("Pending proposal")
      expect(page).not_to have_content("Hidden proposal")
      expect(page).not_to have_content("Ignored proposal")

      visit moderation_proposals_path(filter: "with_ignored_flag")
      expect(page).not_to have_content("Regular proposal")
      expect(page).not_to have_content("Pending proposal")
      expect(page).not_to have_content("Hidden proposal")
      expect(page).to have_content("Ignored proposal")
    end

    scenario "sorting proposals" do
      flagged_proposal = create(:proposal,
                                title: "Flagged proposal",
                                created_at: 1.day.ago,
                                flags_count: 5)
      flagged_new_proposal = create(:proposal,
                                    title: "Flagged new proposal",
                                    created_at: 12.hours.ago,
                                    flags_count: 3)
      newer_proposal = create(:proposal, title: "Newer proposal", created_at: Time.current)

      visit moderation_proposals_path(order: "created_at")

      expect(flagged_new_proposal.title).to appear_before(flagged_proposal.title)

      visit moderation_proposals_path(order: "flags")

      expect(flagged_proposal.title).to appear_before(flagged_new_proposal.title)

      visit moderation_proposals_path(filter: "all", order: "created_at")

      expect(newer_proposal.title).to appear_before(flagged_new_proposal.title)
      expect(flagged_new_proposal.title).to appear_before(flagged_proposal.title)

      visit moderation_proposals_path(filter: "all", order: "flags")

      expect(flagged_proposal.title).to appear_before(flagged_new_proposal.title)
      expect(flagged_new_proposal.title).to appear_before(newer_proposal.title)
    end
  end
end
