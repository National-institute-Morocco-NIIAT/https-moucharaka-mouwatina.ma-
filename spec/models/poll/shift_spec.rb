require "rails_helper"

describe Poll::Shift do
  let(:poll) { create(:poll) }
  let(:booth) { create(:poll_booth) }
  let(:user) { create(:user, username: "Ana", email: "ana@example.com") }
  let(:officer) { create(:poll_officer, user: user) }
  let(:recount_shift) do
    build(:poll_shift, booth: booth, officer: officer, date: Date.current, task: :recount_scrutiny)
  end

  describe "validations" do
    let(:shift) { build(:poll_shift) }

    it "is valid" do
      expect(shift).to be_valid
    end

    it "is not valid without a booth" do
      shift.booth = nil
      expect(shift).not_to be_valid
    end

    it "is not valid without an officer" do
      shift.officer = nil
      expect(shift).not_to be_valid
    end

    it "is not valid without a date" do
      shift.date = nil
      expect(shift).not_to be_valid
    end

    it "is not valid without a task" do
      shift.task = nil
      expect(shift).not_to be_valid
    end

    it "is not valid with same booth, officer, date and task" do
      recount_shift.save!

      expect(build(:poll_shift, booth: booth,
                                officer: officer,
                                date: Date.current,
                                task: :recount_scrutiny)).not_to be_valid
    end

    it "is valid with same booth, officer and date but different task" do
      recount_shift.save!

      expect(build(:poll_shift, booth: booth,
                                officer: officer,
                                date: Date.current,
                                task: :vote_collection)).to be_valid
    end

    it "is valid with same booth, officer and task but different date" do
      recount_shift.save!

      expect(build(:poll_shift, booth: booth,
                                officer: officer,
                                date: Date.tomorrow,
                                task: :recount_scrutiny)).to be_valid
    end
  end

  describe "officer_assignments" do
    it "creates and destroy corresponding officer_assignments" do
      booth_assignment1 = create(:poll_booth_assignment, booth: booth)
      booth_assignment2 = create(:poll_booth_assignment, booth: booth)

      expect do
        create(:poll_shift, booth: booth, officer: officer, date: Date.current)
      end.to change { Poll::OfficerAssignment.count }.by(2)

      officer_assignments = Poll::OfficerAssignment.all
      oa1 = officer_assignments.first
      oa2 = officer_assignments.second

      expect(oa1.officer).to eq(officer)
      expect(oa1.date).to eq(Date.current)
      expect(oa1.booth_assignment).to eq(booth_assignment1)
      expect(oa1.final).to be_falsey

      expect(oa2.officer).to eq(officer)
      expect(oa2.date).to eq(Date.current)
      expect(oa2.booth_assignment).to eq(booth_assignment2)
      expect(oa2.final).to be_falsey

      create(:poll_officer_assignment, officer: officer,
                                       booth_assignment: booth_assignment1,
                                       date: Date.tomorrow)

      expect { Poll::Shift.last.destroy }.to change { Poll::OfficerAssignment.count }.by(-2)
    end

    it "creates final officer_assignments" do
      booth_assignment = create(:poll_booth_assignment, poll: poll, booth: booth)
      recount_shift.save!

      officer_assignments = Poll::OfficerAssignment.all
      expect(officer_assignments.count).to eq(1)

      officer_assignment = officer_assignments.first

      expect(officer_assignment.officer).to eq(officer)
      expect(officer_assignment.date).to eq(Date.current)
      expect(officer_assignment.booth_assignment).to eq(booth_assignment)
      expect(officer_assignment.final).to be_truthy
    end
  end

  describe "#persist_data" do
    let(:shift) { create(:poll_shift, officer: officer, booth: booth) }

    it "maintains officer data after destroying associated user" do
      shift.officer.user.destroy!

      expect(shift.officer_name).to eq "Ana"
      expect(shift.officer_email).to eq "ana@example.com"
    end

    it "maintains officer data after destroying officer role" do
      shift.officer.destroy!

      expect(shift.officer_name).to eq "Ana"
      expect(shift.officer_email).to eq "ana@example.com"
    end
  end
end
