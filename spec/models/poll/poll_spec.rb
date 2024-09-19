require "rails_helper"

describe Poll do
  let(:poll) { build(:poll, :future) }

  describe "Concerns" do
    it_behaves_like "notifiable"
    it_behaves_like "acts as paranoid", :poll
    it_behaves_like "reportable"
    it_behaves_like "globalizable", :poll
  end

  describe "validations" do
    it "is valid" do
      expect(poll).to be_valid
    end

    it "is not valid without a name" do
      poll.name = nil
      expect(poll).not_to be_valid
    end

    it "is not valid without a start date" do
      poll.starts_at = nil

      expect(poll).not_to be_valid
      expect(poll.errors[:starts_at]).to eq ["can't be blank"]
    end

    it "is not valid without an end date" do
      poll.ends_at = nil

      expect(poll).not_to be_valid
      expect(poll.errors[:ends_at]).to eq ["can't be blank"]
    end

    it "is not valid without a proper start/end date range" do
      poll.starts_at = 1.week.ago
      poll.ends_at = 2.months.ago
      expect(poll).not_to be_valid
    end

    it "is valid if start date is greater than current time" do
      poll.starts_at = 1.minute.from_now
      expect(poll).to be_valid
    end

    it "is not valid if start date is a past date" do
      poll.starts_at = 1.minute.ago

      expect(poll).not_to be_valid
      expect(poll.errors[:starts_at]).to eq ["Must not be a past date"]
    end

    context "persisted poll" do
      let(:poll) { create(:poll, :future) }

      it "is valid if the start date changes to a future date" do
        poll.starts_at = 1.minute.from_now
        expect(poll).to be_valid
      end

      it "is not valid if the start date changes to a past date" do
        poll.starts_at = 1.minute.ago
        expect(poll).not_to be_valid
      end

      it "is not valid if changing the start date for an already started poll" do
        poll = create(:poll, starts_at: 10.days.ago)

        poll.starts_at = 10.days.from_now
        expect(poll).not_to be_valid
      end

      it "is valid if changing the end date for a non-expired poll to a future date" do
        poll.ends_at = 1.day.from_now
        expect(poll).to be_valid
      end

      it "is not valid if changing the end date to a past date" do
        poll = create(:poll, starts_at: 10.days.ago, ends_at: 10.days.from_now)

        poll.ends_at = 1.day.ago
        expect(poll).not_to be_valid
      end

      it "is valid if the past end date is the same as it was" do
        poll = create(:poll, starts_at: 3.days.ago, ends_at: 2.days.ago)
        poll.ends_at = poll.ends_at

        expect(poll).to be_valid
      end

      it "is not valid if changing the end date for an expired poll" do
        poll = create(:poll, :expired)

        poll.ends_at = 1.day.from_now
        expect(poll).not_to be_valid
      end
    end
  end

  describe "proposal polls specific validations" do
    let(:proposal) { create(:proposal) }
    let(:poll) { build(:poll, :future, related: proposal) }

    it "is valid when overlapping but different proposals" do
      other_proposal = create(:proposal)
      _other_poll = create(:poll, related: other_proposal,
                                  starts_at: poll.starts_at,
                                  ends_at: poll.ends_at)

      expect(poll).to be_valid
    end

    it "is valid when same proposal but not overlapping" do
      _other_poll = create(:poll, related: proposal,
                                  starts_at: poll.ends_at + 1.day,
                                  ends_at: poll.ends_at + 8.days)
      expect(poll).to be_valid
    end

    it "is not valid when overlaps from the beginning" do
      _other_poll = create(:poll, related: proposal,
                                  starts_at: poll.starts_at - 8.days,
                                  ends_at: poll.starts_at)
      expect(poll).not_to be_valid
    end

    it "is not valid when overlaps from the end" do
      _other_poll = create(:poll, related: proposal,
                                  starts_at: poll.ends_at,
                                  ends_at: poll.ends_at + 8.days)
      expect(poll).not_to be_valid
    end

    it "is not valid when overlaps with same interval" do
      _other_poll = create(:poll, related: proposal,
                                  starts_at: poll.starts_at,
                                  ends_at: poll.ends_at)
      expect(poll).not_to be_valid
    end

    it "is not valid when overlaps with interval contained" do
      _other_poll = create(:poll, related: proposal,
                                  starts_at: poll.starts_at + 1.day,
                                  ends_at: poll.ends_at - 1.day)
      expect(poll).not_to be_valid
    end

    it "is not valid when overlaps with interval containing" do
      _other_poll = create(:poll, related: proposal,
                                  starts_at: poll.starts_at - 8.days,
                                  ends_at: poll.ends_at + 8.days)
      expect(poll).not_to be_valid
    end
  end

  describe "#current?", :with_frozen_time do
    it "returns true only when it isn't too late" do
      about_to_start = create(:poll, starts_at: 1.second.from_now)
      just_started = create(:poll, starts_at: Time.current)
      about_to_end = create(:poll, ends_at: Time.current)
      just_ended = create(:poll, ends_at: 1.second.ago)

      expect(just_started).to be_current
      expect(about_to_end).to be_current
      expect(about_to_start).not_to be_current
      expect(just_ended).not_to be_current
    end
  end

  describe "#expired?", :with_frozen_time do
    it "returns true only when it is too late" do
      about_to_start = create(:poll, starts_at: 1.second.from_now)
      about_to_end = create(:poll, ends_at: Time.current)
      just_ended = create(:poll, ends_at: 1.second.ago)
      recounting_ended = create(:poll, starts_at: 3.years.ago, ends_at: 2.years.ago)

      expect(just_ended).to be_expired
      expect(recounting_ended).to be_expired
      expect(about_to_start).not_to be_expired
      expect(about_to_end).not_to be_expired
    end
  end

  describe "#published?" do
    it "returns true only when published is true" do
      expect(create(:poll)).not_to be_published
      expect(create(:poll, :published)).to be_published
    end
  end

  describe "answerable_by" do
    let(:geozone) { create(:geozone) }

    let!(:current_poll) { create(:poll) }
    let!(:expired_poll) { create(:poll, :expired) }

    let!(:current_restricted_poll) { create(:poll, geozone_restricted_to: [geozone]) }
    let!(:expired_restricted_poll) { create(:poll, :expired, geozone_restricted_to: [geozone]) }

    let!(:all_polls) { [current_poll, expired_poll, current_poll, expired_restricted_poll] }
    let(:non_current_polls) { [expired_poll, expired_restricted_poll] }

    let(:non_user) { nil }
    let(:level1)   { create(:user) }
    let(:level2)   { create(:user, :level_two) }
    let(:level2_from_geozone) { create(:user, :level_two, geozone: geozone) }
    let(:all_users) { [non_user, level1, level2, level2_from_geozone] }

    describe "instance method" do
      it "rejects non-users and level 1 users" do
        all_polls.each do |poll|
          expect(poll).not_to be_answerable_by(non_user)
          expect(poll).not_to be_answerable_by(level1)
        end
      end

      it "rejects everyone when not current" do
        non_current_polls.each do |poll|
          all_users.each do |user|
            expect(poll).not_to be_answerable_by(user)
          end
        end
      end

      it "accepts level 2 users when unrestricted and current" do
        expect(current_poll).to be_answerable_by(level2)
        expect(current_poll).to be_answerable_by(level2_from_geozone)
      end

      it "accepts level 2 users only from the same geozone when restricted by geozone" do
        expect(current_restricted_poll).not_to be_answerable_by(level2)
        expect(current_restricted_poll).to be_answerable_by(level2_from_geozone)
      end
    end

    describe "class method" do
      it "returns no polls for non-users and level 1 users" do
        expect(Poll.answerable_by(nil)).to be_empty
        expect(Poll.answerable_by(level1)).to be_empty
      end

      it "returns unrestricted polls for level 2 users" do
        expect(Poll.answerable_by(level2).to_a).to eq([current_poll])
      end

      it "returns restricted & unrestricted polls for level 2 users of the correct geozone" do
        list = Poll.answerable_by(level2_from_geozone).order(:geozone_restricted)
        expect(list.to_a).to eq([current_poll, current_restricted_poll])
      end
    end
  end

  describe ".votable_by" do
    it "returns polls that have not been voted by a user" do
      user = create(:user, :level_two)

      poll1 = create(:poll)
      poll2 = create(:poll)
      poll3 = create(:poll)

      create(:poll_voter, user: user, poll: poll1)

      expect(Poll.votable_by(user)).to match_array [poll2, poll3]
    end

    it "returns polls that are answerable by a user" do
      user = create(:user, :level_two, geozone: nil)
      poll1 = create(:poll)
      poll2 = create(:poll)

      allow(Poll).to receive(:answerable_by).and_return(Poll.where(id: poll1))

      expect(Poll.votable_by(user)).to eq [poll1]
      expect(Poll.votable_by(user)).not_to include(poll2)
    end

    it "returns polls even if there are no voters yet" do
      user = create(:user, :level_two)
      poll = create(:poll)

      expect(Poll.votable_by(user)).to eq [poll]
    end
  end

  describe "#votable_by" do
    it "returns false if the user has already voted the poll" do
      user = create(:user, :level_two)
      poll = create(:poll)

      create(:poll_voter, user: user, poll: poll)

      expect(poll.votable_by?(user)).to be false
    end

    it "returns false if the poll is not answerable by the user" do
      user = create(:user, :level_two)
      poll = create(:poll)

      allow_any_instance_of(Poll).to receive(:answerable_by?).and_return(false)

      expect(poll.votable_by?(user)).to be false
    end

    it "return true if a poll is answerable and has not been voted by the user" do
      user = create(:user, :level_two)
      poll = create(:poll)

      allow_any_instance_of(Poll).to receive(:answerable_by?).and_return(true)

      expect(poll.votable_by?(user)).to be true
    end
  end

  describe "#voted_by?" do
    it "return false if the user has not voted for this poll" do
      user = create(:user, :level_two)
      poll = create(:poll)

      expect(poll.voted_by?(user)).to be false
    end

    it "returns true if the user has voted for this poll" do
      user = create(:user, :level_two)
      poll = create(:poll)

      create(:poll_voter, user: user, poll: poll)

      expect(poll.voted_by?(user)).to be true
    end
  end

  describe "#voted_in_booth?" do
    it "returns true if the user has already voted in booth" do
      user = create(:user, :level_two)
      poll = create(:poll)

      create(:poll_voter, :from_booth, poll: poll, user: user)

      expect(poll.voted_in_booth?(user)).to be
    end

    it "returns false if the user has not already voted in a booth" do
      user = create(:user, :level_two)
      poll = create(:poll)

      expect(poll.voted_in_booth?(user)).not_to be
    end

    it "returns false if the user has voted in web" do
      user = create(:user, :level_two)
      poll = create(:poll)

      create(:poll_voter, :from_web, poll: poll, user: user)

      expect(poll.voted_in_booth?(user)).not_to be
    end
  end

  describe ".overlaping_with" do
    let(:proposal) { create(:proposal) }
    let(:other_proposal) { create(:proposal) }
    let(:poll) { create(:poll, related: proposal) }
    let(:overlaping_poll) do
      build(:poll, related: proposal, starts_at: poll.starts_at + 1.day, ends_at: poll.ends_at - 1.day)
    end

    let(:non_overlaping_poll) do
      create(:poll, related: proposal, starts_at: poll.ends_at + 1.day, ends_at: poll.ends_at + 31.days)
    end

    let(:overlaping_poll_2) do
      create(:poll, related: other_proposal, starts_at: poll.starts_at + 1.day, ends_at: poll.ends_at - 1.day)
    end

    it "a poll can not overlap itself" do
      expect(Poll.overlaping_with(poll)).not_to include(poll)
    end

    it "returns overlaping polls for the same proposal" do
      expect(Poll.overlaping_with(overlaping_poll)).to eq [poll]
    end

    it "do not returs non overlaping polls for the same proposal" do
      expect(Poll.overlaping_with(poll)).not_to include(non_overlaping_poll)
    end

    it "do not returns overlaping polls for other proposal" do
      expect(Poll.overlaping_with(poll)).not_to include(overlaping_poll_2)
    end
  end

  describe "scopes" do
    describe ".current", :with_frozen_time do
      it "returns polls which have started but not ended" do
        about_to_start = create(:poll, starts_at: 1.second.from_now)
        just_started = create(:poll, starts_at: Time.current)
        about_to_end = create(:poll, ends_at: Time.current)
        just_ended = create(:poll, ends_at: 1.second.ago)

        current_polls = Poll.current

        expect(current_polls).to match_array [just_started, about_to_end]
        expect(current_polls).not_to include(about_to_start)
        expect(current_polls).not_to include(just_ended)
      end
    end

    describe ".expired", :with_frozen_time do
      it "returns polls which have already ended" do
        about_to_start = create(:poll, starts_at: 1.second.from_now)
        about_to_end = create(:poll, ends_at: Time.current)
        just_ended = create(:poll, ends_at: 1.second.ago)
        recounting_ended = create(:poll, starts_at: 3.years.ago, ends_at: 2.years.ago)

        expired_polls = Poll.expired

        expect(expired_polls).to match_array [just_ended, recounting_ended]
        expect(expired_polls).not_to include(about_to_start)
        expect(expired_polls).not_to include(about_to_end)
      end
    end

    describe ".recounting", :with_frozen_time do
      it "returns polls in recount & scrutiny phase" do
        about_to_start = create(:poll, starts_at: 1.second.from_now)
        about_to_end = create(:poll, ends_at: Time.current)
        just_ended = create(:poll, ends_at: 1.second.ago)
        recounting_ended = create(:poll, starts_at: 3.years.ago, ends_at: 2.years.ago)

        recounting_polls = Poll.recounting

        expect(recounting_polls).to eq [just_ended]
        expect(recounting_polls).not_to include(about_to_start)
        expect(recounting_polls).not_to include(about_to_end)
        expect(recounting_polls).not_to include(recounting_ended)
      end
    end

    describe ".current_or_recounting", :with_frozen_time do
      it "returns current or recounting polls" do
        about_to_start = create(:poll, starts_at: 1.second.from_now)
        just_started = create(:poll, starts_at: Time.current)
        about_to_end = create(:poll, ends_at: Time.current)
        just_ended = create(:poll, ends_at: 1.second.ago)
        recounting_ended = create(:poll, starts_at: 3.years.ago, ends_at: 2.years.ago)

        current_or_recounting = Poll.current_or_recounting

        expect(current_or_recounting).to match_array [just_started, about_to_end, just_ended]
        expect(current_or_recounting).not_to include(about_to_start)
        expect(current_or_recounting).not_to include(recounting_ended)
      end
    end

    describe ".not_budget" do
      it "returns polls not associated to a budget" do
        poll1 = create(:poll)
        poll2 = create(:poll)
        poll3 = create(:poll, :for_budget)

        expect(Poll.not_budget).to match_array [poll1, poll2]
        expect(Poll.not_budget).not_to include(poll3)
      end
    end
  end

  describe ".sort_for_list" do
    context "sort polls by weight" do
      it "returns poll not restricted by geozone first" do
        poll_with_geozone_restricted = create(:poll, geozone_restricted: true)
        poll_not_restricted_by_geozone = create(:poll, geozone_restricted: false)

        expect(Poll.sort_for_list).to eq [poll_not_restricted_by_geozone, poll_with_geozone_restricted]
      end

      it "returns poll with geozone restricted by user geozone" do
        geozone = create(:geozone)
        geozone_user = create(:user, :level_two, geozone: geozone)
        poll_not_answerable_by_user = create(:poll, geozone_restricted: true)
        poll_anserable_by_user = create(:poll, geozone_restricted: true, geozone_restricted_to: [geozone])

        expect(Poll.sort_for_list(geozone_user)).to eq [poll_anserable_by_user, poll_not_answerable_by_user]
      end
    end

    context "sort polls by time when weight comparison is zero" do
      it "when polls are expired returns the most recently finished first" do
        poll_ends_first = create(:poll, ends_at: 1.day.ago - 1.hour)
        poll_ends_last = create(:poll, ends_at: 1.day.ago)

        expect(Poll.sort_for_list).to eq [poll_ends_last, poll_ends_first]
      end

      it "when polls are current returns the most recently started first" do
        ends_at = 1.day.from_now
        poll_starts_first = create(:poll, starts_at: 1.day.ago - 1.hour, ends_at: ends_at)
        poll_starts_last = create(:poll, starts_at: 1.day.ago, ends_at: ends_at)

        expect(Poll.sort_for_list).to eq [poll_starts_first, poll_starts_last]
      end
    end

    it "sort polls by name ASC when weight and time comparison are zero", :with_frozen_time do
      poll1 = create(:poll, name: "Zzz...")
      poll2 = create(:poll, name: "Aaaaah!")

      expect(Poll.sort_for_list).to eq [poll2, poll1]
    end

    it "returns polls with multiple translations only once" do
      create(:poll, name_en: "English", name_es: "Spanish")

      expect(Poll.sort_for_list.count).to eq 1
    end

    context "fallback locales" do
      before do
        allow(I18n.fallbacks).to receive(:[]).and_return([:es])
        Globalize.set_fallbacks_to_all_available_locales
      end

      it "orders by name considering fallback locales" do
        starts_at = 1.day.from_now
        poll1 = create(:poll, starts_at: starts_at, name: "Charlie")
        poll2 = create(:poll, starts_at: starts_at, name: "Delta")
        poll3 = I18n.with_locale(:es) do
          create(:poll, starts_at: starts_at, name: "Zzz...", name_fr: "Aaaah!")
        end
        poll4 = I18n.with_locale(:es) do
          create(:poll, starts_at: starts_at, name: "Bravo")
        end

        expect(Poll.sort_for_list).to eq [poll4, poll1, poll2, poll3]
      end
    end
  end

  describe "#recounts_confirmed" do
    it "is false for current polls" do
      poll = create(:poll)

      expect(poll.recounts_confirmed?).to be false
    end

    it "is false for recounting polls" do
      poll = create(:poll, ends_at: 1.second.ago)

      expect(poll.recounts_confirmed?).to be false
    end

    it "is false for polls which finished less than a month ago" do
      poll = create(:poll, starts_at: 3.months.ago, ends_at: 27.days.ago)

      expect(poll.recounts_confirmed?).to be false
    end

    it "is true for polls which finished more than a month ago" do
      poll = create(:poll, starts_at: 3.months.ago, ends_at: 1.month.ago - 1.day)

      expect(poll.recounts_confirmed?).to be true
    end
  end

  describe ".search" do
    let!(:square) do
      create(:poll, name: "Square reform", summary: "Next to the park", description: "Give it more space")
    end

    let!(:park) do
      create(:poll, name: "New park", summary: "Green spaces", description: "Next to the square")
    end

    it "returns only matching polls" do
      expect(Poll.search("reform")).to eq [square]
      expect(Poll.search("green")).to eq [park]
      expect(Poll.search("nothing here")).to be_empty
    end

    it "gives more weight to name" do
      expect(Poll.search("square")).to eq [square, park]
      expect(Poll.search("park")).to eq [park, square]
    end

    it "gives more weight to summary than description" do
      expect(Poll.search("space")).to eq [park, square]
    end
  end
end
