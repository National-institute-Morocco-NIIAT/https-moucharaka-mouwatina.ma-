require "rails_helper"
require "cancan/matchers"

describe Abilities::Common do
  subject(:ability) { Ability.new(user) }

  let(:geozone)     { create(:geozone)  }

  let(:user) { create(:user, geozone: geozone) }
  let(:another_user) { create(:user) }

  let(:debate)       { create(:debate)   }
  let(:comment)      { create(:comment)  }
  let(:proposal)     { create(:proposal) }
  let(:own_debate)   { create(:debate,   author: user) }
  let(:own_comment)  { create(:comment,  author: user) }
  let(:own_proposal) { create(:proposal, author: user) }
  let(:own_legislation_proposal) { create(:legislation_proposal, author: user) }
  let(:legislation_proposal) { create(:legislation_proposal) }

  let(:accepting_budget) { create(:budget, :accepting) }
  let(:reviewing_budget) { create(:budget, :reviewing) }
  let(:selecting_budget) { create(:budget, :selecting) }
  let(:balloting_budget) { create(:budget, :balloting) }

  let(:investment_in_accepting_budget) { create(:budget_investment, budget: accepting_budget) }
  let(:investment_in_reviewing_budget) { create(:budget_investment, budget: reviewing_budget) }
  let(:investment_in_selecting_budget) { create(:budget_investment, budget: selecting_budget) }
  let(:investment_in_balloting_budget) { create(:budget_investment, budget: balloting_budget) }
  let(:own_investment_in_accepting_budget) do
    create(:budget_investment, budget: accepting_budget, author: user)
  end
  let(:own_investment_in_reviewing_budget) do
    create(:budget_investment, budget: reviewing_budget, author: user)
  end
  let(:own_investment_in_selecting_budget) do
    create(:budget_investment, budget: selecting_budget, author: user)
  end
  let(:own_investment_in_balloting_budget) do
    create(:budget_investment, budget: balloting_budget, author: user)
  end
  let(:ballot_in_accepting_budget) { create(:budget_ballot, budget: accepting_budget) }
  let(:ballot_in_selecting_budget) { create(:budget_ballot, budget: selecting_budget) }
  let(:ballot_in_balloting_budget) { create(:budget_ballot, budget: balloting_budget) }

  let(:current_poll) { create(:poll) }
  let(:expired_poll) { create(:poll, :expired) }
  let(:expired_poll_from_own_geozone) { create(:poll, :expired, geozone_restricted_to: [geozone]) }
  let(:expired_poll_from_other_geozone) { create(:poll, :expired, geozone_restricted_to: [create(:geozone)]) }
  let(:poll) { create(:poll, geozone_restricted: false) }
  let(:poll_from_own_geozone) { create(:poll, geozone_restricted_to: [geozone]) }
  let(:poll_from_other_geozone) { create(:poll, geozone_restricted_to: [create(:geozone)]) }

  let(:poll_question_from_own_geozone)   { create(:poll_question, poll: poll_from_own_geozone) }
  let(:poll_question_from_other_geozone) { create(:poll_question, poll: poll_from_other_geozone) }
  let(:poll_question_from_all_geozones)  { create(:poll_question, poll: poll) }

  let(:expired_poll_question_from_own_geozone) do
    create(:poll_question, poll: expired_poll_from_own_geozone)
  end
  let(:expired_poll_question_from_other_geozone) do
    create(:poll_question, poll: expired_poll_from_other_geozone)
  end
  let(:expired_poll_question_from_all_geozones) { create(:poll_question, poll: expired_poll) }

  let(:own_proposal_document)          { build(:document, documentable: own_proposal) }
  let(:proposal_document)              { build(:document, documentable: proposal) }
  let(:own_budget_investment_document) { build(:document, documentable: own_investment_in_accepting_budget) }
  let(:budget_investment_document)     { build(:document, documentable: investment_in_accepting_budget) }

  let(:own_proposal_image)          { build(:image, imageable: own_proposal) }
  let(:proposal_image)              { build(:image, imageable: proposal) }
  let(:own_budget_investment_image) { build(:image, imageable: own_investment_in_accepting_budget) }
  let(:budget_investment_image)     { build(:image, imageable: investment_in_accepting_budget) }

  it { should be_able_to(:index, Debate) }
  it { should be_able_to(:show, debate)  }
  it { should be_able_to(:create, user.votes.build(votable: debate)) }
  it { should_not be_able_to(:create, another_user.votes.build(votable: debate)) }
  it { should be_able_to(:destroy, user.votes.build(votable: debate)) }
  it { should_not be_able_to(:destroy, another_user.votes.build(votable: debate)) }

  it { should be_able_to(:show, user) }
  it { should be_able_to(:edit, user) }

  it { should     be_able_to(:index, Proposal) }
  it { should     be_able_to(:show, proposal) }
  it { should_not be_able_to(:vote, Proposal) }

  it { should_not be_able_to(:comment_as_administrator, debate)   }
  it { should_not be_able_to(:comment_as_moderator, debate)       }
  it { should_not be_able_to(:comment_as_administrator, proposal) }
  it { should_not be_able_to(:comment_as_moderator, proposal)     }

  it { should_not be_able_to(:new,    DirectMessage) }
  it { should_not be_able_to(:create, DirectMessage) }
  it { should_not be_able_to(:show,   DirectMessage) }

  it { should be_able_to(:destroy, own_proposal_document) }
  it { should_not be_able_to(:destroy, proposal_document) }

  it { should be_able_to(:destroy, own_budget_investment_document) }
  it { should_not be_able_to(:destroy, budget_investment_document) }

  it { should be_able_to(:destroy, own_proposal_image) }
  it { should_not be_able_to(:destroy, proposal_image) }

  it { should be_able_to(:destroy, own_budget_investment_image) }
  it { should_not be_able_to(:destroy, budget_investment_image) }
  it { should_not be_able_to(:manage, Dashboard::Action) }

  it { should_not be_able_to(:manage, LocalCensusRecord) }

  describe "Comment" do
    it { should be_able_to(:create, Comment) }
    it { should be_able_to(:create, user.votes.build(votable: comment)) }
    it { should_not be_able_to(:create, another_user.votes.build(votable: comment)) }
    it { should be_able_to(:destroy, user.votes.build(votable: comment)) }
    it { should_not be_able_to(:destroy, another_user.votes.build(votable: comment)) }

    it { should be_able_to(:hide, own_comment) }
    it { should_not be_able_to(:hide, comment) }
  end

  describe "flagging content" do
    it { should be_able_to(:flag, debate)   }
    it { should be_able_to(:unflag, debate) }

    it { should be_able_to(:flag, comment)   }
    it { should be_able_to(:unflag, comment) }

    it { should be_able_to(:flag, proposal)   }
    it { should be_able_to(:unflag, proposal) }

    describe "own content" do
      it { should_not be_able_to(:flag, own_comment)   }
      it { should_not be_able_to(:unflag, own_comment) }

      it { should_not be_able_to(:flag, own_debate)   }
      it { should_not be_able_to(:unflag, own_debate) }

      it { should_not be_able_to(:flag, own_proposal)   }
      it { should_not be_able_to(:unflag, own_proposal) }
    end
  end

  describe "follows" do
    it { should be_able_to(:create, build(:follow, :followed_proposal, user: user)) }
    it { should_not be_able_to(:create, build(:follow, :followed_proposal, user: another_user)) }

    it { should be_able_to(:destroy, create(:follow, :followed_proposal, user: user)) }
    it { should_not be_able_to(:destroy, create(:follow, :followed_proposal, user: another_user)) }
  end

  describe "other users" do
    it { should     be_able_to(:show, another_user) }
    it { should_not be_able_to(:edit, another_user) }
  end

  describe "editing debates" do
    let(:own_debate_non_editable) { create(:debate, author: user) }

    before { allow(own_debate_non_editable).to receive(:editable?).and_return(false) }

    it { should     be_able_to(:edit, own_debate)              }
    it { should_not be_able_to(:edit, debate)                  } # Not his
    it { should_not be_able_to(:edit, own_debate_non_editable) }
  end

  describe "editing proposals" do
    let(:own_proposal_non_editable) { create(:proposal, author: user) }

    before { allow(own_proposal_non_editable).to receive(:editable?).and_return(false) }

    it { should be_able_to(:edit, own_proposal)                  }
    it { should_not be_able_to(:edit, proposal)                  } # Not his
    it { should_not be_able_to(:edit, own_proposal_non_editable) }

    it { should be_able_to(:destroy, own_proposal_image)         }
    it { should be_able_to(:destroy, own_proposal_document)      }

    it { should_not be_able_to(:destroy, proposal_image)         }
    it { should_not be_able_to(:destroy, proposal_document)      }
  end

  it { should_not be_able_to(:edit, own_legislation_proposal) }
  it { should_not be_able_to(:update, own_legislation_proposal) }

  describe "vote legislation proposal" do
    context "when user is not level_two_or_three_verified" do
      it { should_not be_able_to(:create, user.votes.build(votable: legislation_proposal)) }
      it { should_not be_able_to(:destroy, user.votes.build(votable: legislation_proposal)) }
    end

    context "when user is level_two_or_three_verified" do
      before { user.update(level_two_verified_at: Date.current) }
      it { should be_able_to(:create, user.votes.build(votable: legislation_proposal)) }
      it { should_not be_able_to(:create, another_user.votes.build(votable: legislation_proposal)) }
      it { should be_able_to(:destroy, user.votes.build(votable: legislation_proposal)) }
      it { should_not be_able_to(:destroy, another_user.votes.build(votable: legislation_proposal)) }
    end
  end

  describe "proposals dashboard" do
    it { should be_able_to(:dashboard, own_proposal) }
    it { should_not be_able_to(:dashboard, proposal) }
  end

  describe "proposal polls" do
    let(:poll) { create(:poll, related: own_proposal) }

    it { should be_able_to(:manage_polls, own_proposal) }
    it { should_not be_able_to(:manage_polls, proposal) }
    it { should_not be_able_to(:stats, poll) }
    it { should be_able_to(:results, poll) }
  end

  describe "proposal mailing" do
    it { should be_able_to(:manage_mailing, own_proposal) }
    it { should_not be_able_to(:manage_mailing, proposal) }
  end

  describe "proposal poster" do
    it { should be_able_to(:manage_poster, own_proposal) }
    it { should_not be_able_to(:manage_poster, proposal) }
  end

  describe "publishing proposals" do
    let(:draft_own_proposal) { create(:proposal, :draft, author: user) }
    let(:retired_proposal) { create(:proposal, :draft, :retired, author: user) }

    it { should be_able_to(:publish, draft_own_proposal) }
    it { should_not be_able_to(:publish, own_proposal) }
    it { should_not be_able_to(:publish, proposal) }
    it { should_not be_able_to(:publish, retired_proposal) }
  end

  describe "when level 2 verified" do
    let(:own_direct_message) { create(:direct_message, sender: user) }

    before { user.update(residence_verified_at: Time.current, confirmed_phone: "1") }

    describe "Proposal" do
      it { should be_able_to(:vote, Proposal) }
    end

    describe "Direct Message" do
      it { should     be_able_to(:new,    DirectMessage)           }
      it { should     be_able_to(:create, DirectMessage)           }
      it { should     be_able_to(:show,   own_direct_message)      }
      it { should_not be_able_to(:show,   create(:direct_message)) }
    end

    describe "Poll" do
      it { should     be_able_to(:answer, current_poll)  }
      it { should_not be_able_to(:answer, expired_poll)  }

      it { should     be_able_to(:answer, poll_question_from_own_geozone)   }
      it { should     be_able_to(:answer, poll_question_from_all_geozones)  }
      it { should_not be_able_to(:answer, poll_question_from_other_geozone) }

      it { should_not be_able_to(:answer, expired_poll_question_from_own_geozone)   }
      it { should_not be_able_to(:answer, expired_poll_question_from_all_geozones)  }
      it { should_not be_able_to(:answer, expired_poll_question_from_other_geozone) }

      context "Poll::Answer" do
        let(:own_answer) { create(:poll_answer, author: user) }
        let(:other_user_answer) { create(:poll_answer) }
        let(:expired_poll) { create(:poll, :expired) }
        let(:question) { create(:poll_question, :yes_no, poll: expired_poll) }
        let(:expired_poll_answer) { create(:poll_answer, author: user, question: question, answer: "Yes") }

        it { should be_able_to(:destroy, own_answer) }
        it { should_not be_able_to(:destroy, other_user_answer) }
        it { should_not be_able_to(:destroy, expired_poll_answer) }
      end

      context "without geozone" do
        before { user.geozone = nil }

        it { should_not be_able_to(:answer, poll_question_from_own_geozone)   }
        it { should     be_able_to(:answer, poll_question_from_all_geozones)  }
        it { should_not be_able_to(:answer, poll_question_from_other_geozone) }

        it { should_not be_able_to(:answer, expired_poll_question_from_own_geozone)   }
        it { should_not be_able_to(:answer, expired_poll_question_from_all_geozones)  }
        it { should_not be_able_to(:answer, expired_poll_question_from_other_geozone) }
      end
    end

    describe "Budgets" do
      it { should be_able_to(:create, investment_in_accepting_budget) }
      it { should_not be_able_to(:create, investment_in_selecting_budget) }
      it { should_not be_able_to(:create, investment_in_balloting_budget) }

      it { should be_able_to(:create, user.votes.build(votable: investment_in_selecting_budget)) }
      it { should_not be_able_to(:create, user.votes.build(votable: investment_in_accepting_budget)) }
      it { should_not be_able_to(:create, user.votes.build(votable: investment_in_balloting_budget)) }
      it { should be_able_to(:destroy, user.votes.create!(votable: investment_in_selecting_budget)) }
      it { should_not be_able_to(:destroy, user.votes.create!(votable: investment_in_accepting_budget)) }
      it { should_not be_able_to(:destroy, user.votes.create!(votable: investment_in_balloting_budget)) }

      it { should_not be_able_to(:destroy, investment_in_accepting_budget) }
      it { should_not be_able_to(:destroy, investment_in_reviewing_budget) }
      it { should_not be_able_to(:destroy, investment_in_selecting_budget) }
      it { should_not be_able_to(:destroy, investment_in_balloting_budget) }

      it { should be_able_to(:destroy, own_investment_in_accepting_budget) }
      it { should be_able_to(:destroy, own_investment_in_reviewing_budget) }
      it { should_not be_able_to(:destroy, own_investment_in_selecting_budget) }
      it { should_not be_able_to(:destroy, own_investment_in_balloting_budget) }

      it { should be_able_to(:edit, own_investment_in_accepting_budget) }
      it { should_not be_able_to(:edit, own_investment_in_reviewing_budget) }
      it { should_not be_able_to(:edit, own_investment_in_selecting_budget) }
      it { should_not be_able_to(:edit, own_investment_in_balloting_budget) }

      it { should be_able_to(:create, ballot_in_balloting_budget) }
      it { should_not be_able_to(:create, ballot_in_accepting_budget) }
      it { should_not be_able_to(:create, ballot_in_selecting_budget) }

      it { should be_able_to(:destroy, own_budget_investment_image) }
      it { should be_able_to(:destroy, own_budget_investment_document) }

      it { should_not be_able_to(:destroy, budget_investment_image) }
      it { should_not be_able_to(:destroy, budget_investment_document) }
    end
  end

  describe "when level 3 verified" do
    let(:own_direct_message) { create(:direct_message, sender: user) }

    before { user.update(verified_at: Time.current) }

    it { should be_able_to(:vote, Proposal) }

    it { should     be_able_to(:new, DirectMessage)            }
    it { should     be_able_to(:create, DirectMessage)         }
    it { should     be_able_to(:show, own_direct_message)      }
    it { should_not be_able_to(:show, create(:direct_message)) }

    it { should     be_able_to(:answer, current_poll)  }
    it { should_not be_able_to(:answer, expired_poll)  }

    it { should     be_able_to(:answer, poll_question_from_own_geozone)   }
    it { should     be_able_to(:answer, poll_question_from_all_geozones)  }
    it { should_not be_able_to(:answer, poll_question_from_other_geozone) }

    it { should_not be_able_to(:answer, expired_poll_question_from_own_geozone)   }
    it { should_not be_able_to(:answer, expired_poll_question_from_all_geozones)  }
    it { should_not be_able_to(:answer, expired_poll_question_from_other_geozone) }

    context "without geozone" do
      before { user.geozone = nil }
      it { should_not be_able_to(:answer, poll_question_from_own_geozone)   }
      it { should     be_able_to(:answer, poll_question_from_all_geozones)  }
      it { should_not be_able_to(:answer, poll_question_from_other_geozone) }

      it { should_not be_able_to(:answer, expired_poll_question_from_own_geozone)   }
      it { should_not be_able_to(:answer, expired_poll_question_from_all_geozones)  }
      it { should_not be_able_to(:answer, expired_poll_question_from_other_geozone) }
    end
  end

  describe "#disable_recommendations" do
    it { should be_able_to(:disable_recommendations, Debate) }
    it { should be_able_to(:disable_recommendations, Proposal) }
  end

  it { should_not be_able_to(:read, SDG::Target) }

  it { should_not be_able_to(:read, SDG::Manager) }
  it { should_not be_able_to(:create, SDG::Manager) }
  it { should_not be_able_to(:delete, SDG::Manager) }
end
