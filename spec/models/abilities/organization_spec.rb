require "rails_helper"
require "cancan/matchers"

describe "Abilities::Organization" do
  subject(:ability) { Ability.new(user) }

  let(:user) { organization.user }
  let(:organization) { create(:organization) }
  let(:debate) { create(:debate) }
  let(:proposal) { create(:proposal) }
  let(:comment) { create(:comment) }

  it { should be_able_to(:show, user) }
  it { should be_able_to(:edit, user) }

  it { should be_able_to(:index, Debate) }
  it { should be_able_to(:show, debate) }
  it { should_not be_able_to(:create, user.votes.build(votable: debate)) }
  it { should_not be_able_to(:destroy, user.votes.build(votable: debate)) }

  it { should be_able_to(:index, Proposal) }
  it { should be_able_to(:show, proposal) }
  it { should_not be_able_to(:vote, Proposal) }

  it { should be_able_to(:create, Comment) }
  it { should_not be_able_to(:create, user.votes.build(votable: comment)) }
  it { should_not be_able_to(:destroy, user.votes.build(votable: comment)) }

  it { should_not be_able_to(:read, SDG::Target) }

  it { should_not be_able_to(:read, SDG::Manager) }
  it { should_not be_able_to(:create, SDG::Manager) }
  it { should_not be_able_to(:delete, SDG::Manager) }
end
