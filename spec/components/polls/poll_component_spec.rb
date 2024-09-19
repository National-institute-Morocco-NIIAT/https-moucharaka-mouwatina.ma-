require "rails_helper"

describe Polls::PollComponent do
  include Rails.application.routes.url_helpers

  describe "status message" do
    it "asks anonymous users to sign in" do
      render_inline Polls::PollComponent.new(create(:poll))

      expect(page).to have_css ".not-logged-in", count: 1
      expect(page).to have_content "You must sign in or sign up to participate"
    end

    it "asks unverified users to verify their account" do
      sign_in(create(:user))

      render_inline Polls::PollComponent.new(create(:poll))

      expect(page).to have_css ".unverified", count: 1
      expect(page).to have_content "You must verify your account to participate"
    end

    it "tell users from different geozones that the poll isn't available" do
      sign_in(create(:user, :level_two))

      render_inline Polls::PollComponent.new(create(:poll, geozone_restricted: true))

      expect(page).to have_css ".cant-answer", count: 1
      expect(page).to have_content "This poll is not available on your geozone"
    end

    it "informs users when they've already participated" do
      user = create(:user, :level_two)
      poll = create(:poll)
      create(:poll_voter, user: user, poll: poll)

      sign_in(user)
      render_inline Polls::PollComponent.new(poll)

      expect(page).to have_css ".already-answer", count: 1
      expect(page).to have_content "You already have participated in this poll"
    end
  end

  describe "dates" do
    it "renders the dates inside an HTML tag" do
      poll = create(:poll, starts_at: "2015-07-15", ends_at: "2015-07-22")

      render_inline Polls::PollComponent.new(poll)

      expect(page).to have_css ".dates", exact_text: "From 2015-07-15 to 2015-07-22"
    end

    it "allows customizing the text to display dates" do
      poll = create(:poll, starts_at: "2015-07-15", ends_at: "2015-07-22")
      create(:i18n_content, key: "polls.dates", value: "Starts someday and finishes who-knows-when")

      render_inline Polls::PollComponent.new(poll)

      expect(page).to have_css ".dates", exact_text: "Starts someday and finishes who-knows-when"
      expect(page).not_to have_content "2015-07-15"
      expect(page).not_to have_content "2015-07-22"
    end
  end

  describe "geozones" do
    it "renders a list of geozones when the poll is geozone-restricted" do
      render_inline Polls::PollComponent.new(create(:poll, geozone_restricted_to: [create(:geozone)]))

      expect(page).to have_css ".tags"
    end

    it "does not render a list of geozones when the poll isn't geozone-restricted" do
      render_inline Polls::PollComponent.new(create(:poll))

      expect(page).not_to have_css ".tags"
    end
  end

  it "shows a link to poll stats if enabled" do
    poll = create(:poll, :expired, name: "Poll with stats", stats_enabled: true)

    render_inline Polls::PollComponent.new(poll)

    expect(page).to have_link "Poll with stats", href: stats_poll_path(poll.slug)
    expect(page).to have_link "Poll ended", href: stats_poll_path(poll.slug)
  end

  it "shows a link to poll results if enabled" do
    poll = create(:poll, :expired, name: "Poll with results", stats_enabled: true, results_enabled: true)

    render_inline Polls::PollComponent.new(poll)

    expect(page).to have_link "Poll with results", href: results_poll_path(poll.slug)
    expect(page).to have_link "Poll ended", href: results_poll_path(poll.slug)
  end

  it "shows SDG tags when that feature is enabled" do
    Setting["feature.sdg"] = true
    Setting["sdg.process.polls"] = true
    poll = create(:poll, sdg_goals: [SDG::Goal[1]], sdg_targets: [SDG::Target["1.1"]])

    render_inline Polls::PollComponent.new(poll)

    expect(page).to have_css "img[alt='1. No Poverty']"
    expect(page).to have_content "target 1.1"
  end
end
