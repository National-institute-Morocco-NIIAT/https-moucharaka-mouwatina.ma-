require "rails_helper"

describe Poll::Stats do
  let(:poll) { create(:poll) }
  let(:stats) { Poll::Stats.new(poll) }

  describe "#participants" do
    it "includes hidden users" do
      create(:poll_voter, poll: poll)
      create(:poll_voter, poll: poll, user: create(:user, :level_two, :hidden))

      expect(stats.participants.count).to eq(2)
    end
  end

  describe "total participants" do
    before { allow(stats).to receive(:total_web_white).and_return(1) }

    it "supports every channel" do
      3.times { create(:poll_voter, :from_web, poll: poll) }
      create(:poll_recount, :from_booth, poll: poll,
                                         total_amount: 8,
                                         white_amount: 4,
                                         null_amount: 1)

      expect(stats.total_participants_web).to eq(3)
      expect(stats.total_participants_booth).to eq(13)
      expect(stats.total_participants).to eq(16)
    end
  end

  describe "#total_participants_booth" do
    it "uses recounts even if there are discrepancies when recounting" do
      create(:poll_recount, :from_booth, poll: poll, total_amount: 1)
      2.times { create(:poll_voter, :from_booth, poll: poll) }

      expect(stats.total_participants_booth).to eq(1)
    end
  end

  describe "total participants percentage by channel" do
    it "is relative to the total amount of participants" do
      create(:poll_voter, :from_web, poll: poll)
      create(:poll_recount, :from_booth, poll: poll, total_amount: 5)

      expect(stats.total_participants_web_percentage).to eq(16.667)
      expect(stats.total_participants_booth_percentage).to eq(83.333)
    end
  end

  describe "#total_web_valid" do
    before { allow(stats).to receive(:total_web_white).and_return(1) }

    it "returns only valid votes" do
      3.times { create(:poll_voter, :from_web, poll: poll) }

      expect(stats.total_web_valid).to eq(2)
    end
  end

  describe "#total_web_null" do
    it "returns 0" do
      expect(stats.total_web_null).to eq(0)
    end
  end

  describe "#total_booth_valid" do
    it "sums the total amounts in the recounts" do
      create(:poll_recount, :from_booth, poll: poll, total_amount: 3, white_amount: 1)
      create(:poll_recount, :from_booth, poll: poll, total_amount: 4, null_amount: 2)

      expect(stats.total_booth_valid).to eq(7)
    end
  end

  describe "#total_booth_white" do
    it "sums the white amounts in the recounts" do
      create(:poll_recount, :from_booth, poll: poll, white_amount: 120, total_amount: 3)
      create(:poll_recount, :from_booth, poll: poll, white_amount: 203, null_amount: 5)

      expect(stats.total_booth_white).to eq(323)
    end
  end

  describe "#total_booth_null" do
    it "sums the null amounts in the recounts" do
      create(:poll_recount, :from_booth, poll: poll, null_amount: 125, total_amount: 3)
      create(:poll_recount, :from_booth, poll: poll, null_amount: 34, white_amount: 5)

      expect(stats.total_booth_null).to eq(159)
    end
  end

  describe "valid percentage by channel" do
    it "is relative to the total amount of valid votes" do
      create(:poll_recount, :from_booth, poll: poll, total_amount: 2)
      create(:poll_voter, :from_web, poll: poll)

      expect(stats.valid_percentage_web).to eq(33.333)
      expect(stats.valid_percentage_booth).to eq(66.667)
    end
  end

  describe "white percentage by channel" do
    before { allow(stats).to receive(:total_web_white).and_return(10) }

    it "is relative to the total amount of white votes" do
      create(:poll_recount, :from_booth, poll: poll, white_amount: 70)

      expect(stats.white_percentage_web).to eq(12.5)
      expect(stats.white_percentage_booth).to eq(87.5)
    end
  end

  describe "null percentage by channel" do
    it "only accepts null votes from booth" do
      create(:poll_recount, :from_booth, poll: poll, null_amount: 70)

      expect(stats.null_percentage_web).to eq(0)
      expect(stats.null_percentage_booth).to eq(100)
    end
  end

  describe "#total_valid_votes" do
    it "counts valid votes from every channel" do
      2.times { create(:poll_voter, :from_web, poll: poll) }
      create(:poll_recount, :from_booth, poll: poll, total_amount: 3, white_amount: 10)
      create(:poll_recount, :from_booth, poll: poll, total_amount: 4, null_amount: 20)

      expect(stats.total_valid_votes).to eq(9)
    end
  end

  describe "#total_white_votes" do
    before { allow(stats).to receive(:total_web_white).and_return(9) }

    it "counts white votes on every channel" do
      create(:poll_recount, :from_booth, poll: poll, white_amount: 12)

      expect(stats.total_white_votes).to eq(21)
    end
  end

  describe "#total_null_votes" do
    it "only accepts null votes from booth" do
      create(:poll_recount, :from_booth, poll: poll, null_amount: 32)

      expect(stats.total_null_votes).to eq(32)
    end
  end

  describe "total percentage by type" do
    before { allow(stats).to receive(:total_web_white).and_return(1) }

    it "is relative to the total amount of votes" do
      3.times { create(:poll_voter, :from_web, poll: poll) }
      create(:poll_recount, :from_booth, poll: poll,
                                         total_amount: 8,
                                         white_amount: 5,
                                         null_amount: 4)

      expect(stats.total_valid_percentage).to eq(50)
      expect(stats.total_white_percentage).to eq(30)
      expect(stats.total_null_percentage).to eq(20)
    end
  end

  describe "#participants_by_age" do
    it "returns stats based on what happened when the voting took place" do
      travel_to(100.years.ago) do
        [16, 18, 32, 32, 33, 34, 64, 65, 71, 73, 90, 99, 105].each do |age|
          create(:user, date_of_birth: age.years.ago - rand(0..11).months)
        end

        create(:poll, starts_at: 1.minute.from_now, ends_at: 2.minutes.from_now)
      end

      stats = Poll::Stats.new(Poll.last)
      allow(stats).to receive(:participants).and_return(User.all)

      expect(stats.participants_by_age["16 - 19"][:count]).to eq 2
      expect(stats.participants_by_age["20 - 24"][:count]).to eq 0
      expect(stats.participants_by_age["25 - 29"][:count]).to eq 0
      expect(stats.participants_by_age["30 - 34"][:count]).to eq 4
      expect(stats.participants_by_age["35 - 39"][:count]).to eq 0
      expect(stats.participants_by_age["40 - 44"][:count]).to eq 0
      expect(stats.participants_by_age["45 - 49"][:count]).to eq 0
      expect(stats.participants_by_age["50 - 54"][:count]).to eq 0
      expect(stats.participants_by_age["55 - 59"][:count]).to eq 0
      expect(stats.participants_by_age["60 - 64"][:count]).to eq 1
      expect(stats.participants_by_age["65 - 69"][:count]).to eq 1
      expect(stats.participants_by_age["70 - 74"][:count]).to eq 2
      expect(stats.participants_by_age["75 - 79"][:count]).to eq 0
      expect(stats.participants_by_age["80 - 84"][:count]).to eq 0
      expect(stats.participants_by_age["85 - 89"][:count]).to eq 0
      expect(stats.participants_by_age["90 - 300"][:count]).to eq 3
    end
  end

  describe "#participation_date", :with_frozen_time do
    let(:poll) { create(:poll, starts_at: 3.years.ago, ends_at: 2.years.ago) }

    it "returns the date when the poll finishes" do
      expect(stats.participation_date).to eq 2.years.ago
    end
  end

  describe "#participants_by_geozone" do
    it "groups by geozones in alphabetic order" do
      %w[Oceania Eurasia Eastasia].each { |name| create(:geozone, name: name) }

      expect(stats.participants_by_geozone.keys).to eq %w[Eastasia Eurasia Oceania]
    end

    it "calculates percentage relative to total participants" do
      hobbiton = create(:geozone, name: "Hobbiton")
      rivendel = create(:geozone, name: "Rivendel")

      3.times { create(:poll_voter, poll: poll, user: create(:user, :level_two, geozone: hobbiton)) }
      2.times { create(:poll_voter, poll: poll, user: create(:user, :level_two, geozone: rivendel)) }

      expect(stats.participants_by_geozone["Hobbiton"][:count]).to eq 3
      expect(stats.participants_by_geozone["Hobbiton"][:percentage]).to eq 60.0
      expect(stats.participants_by_geozone["Rivendel"][:count]).to eq 2
      expect(stats.participants_by_geozone["Rivendel"][:percentage]).to eq 40.0
    end
  end

  describe "#total_no_demographic_data" do
    before do
      create(:poll_voter, :from_web, poll: poll, user: create(:user, :level_two, gender: nil))
    end

    context "more registered participants than participants in recounts" do
      before do
        create(:poll_recount, :from_booth, poll: poll, total_amount: 1)
        2.times { create(:poll_voter, :from_booth, poll: poll) }
      end

      it "returns registered users with no demographic data" do
        expect(stats.total_no_demographic_data).to eq 1
      end
    end

    context "more participants in recounts than registered participants" do
      before do
        create(:poll_recount, :from_booth, poll: poll, total_amount: 3)
        2.times { create(:poll_voter, :from_booth, poll: poll) }
      end

      it "returns registered users with no demographic data plus users not registered" do
        expect(stats.total_no_demographic_data).to eq 2
      end
    end
  end

  describe "#channels" do
    context "no participants" do
      it "returns no channels" do
        expect(stats.channels).to eq []
      end
    end

    context "only participants from web" do
      before { create(:poll_voter, :from_web, poll: poll) }

      it "returns the web channel" do
        expect(stats.channels).to eq ["web"]
      end
    end

    context "only participants from booth" do
      before do
        create(:poll_recount, :from_booth, poll: poll, total_amount: 1)
      end

      it "returns the booth channel" do
        expect(stats.channels).to eq ["booth"]
      end
    end

    context "only participants from letter" do
      before { create(:poll_voter, origin: "letter", poll: poll) }

      it "returns the web channel" do
        expect(stats.channels).to eq ["letter"]
      end
    end

    context "participants from all channels" do
      before do
        create(:poll_voter, :from_web, poll: poll)
        create(:poll_recount, :from_booth, poll: poll, total_amount: 1)
        create(:poll_voter, origin: "letter", poll: poll)
      end

      it "returns all channels" do
        expect(stats.channels).to eq %w[web booth letter]
      end
    end
  end
end
