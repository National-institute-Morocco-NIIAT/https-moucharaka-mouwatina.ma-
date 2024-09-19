class Budgets::Investments::MyBallotComponent < ApplicationComponent
  attr_reader :ballot, :heading, :investment_ids, :assigned_heading
  use_helpers :can?, :heading_link

  def initialize(ballot:, heading:, investment_ids:, assigned_heading: nil)
    @ballot = ballot
    @heading = heading
    @investment_ids = investment_ids
    @assigned_heading = assigned_heading
  end

  def render?
    heading && can?(:show, ballot)
  end

  private

    def budget
      ballot.budget
    end

    def investments
      ballot.investments.by_heading(heading.id).sort_by_ballot_lines
    end
end
