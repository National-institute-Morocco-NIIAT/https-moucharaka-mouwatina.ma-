class Officing::VotersController < Officing::BaseController
  respond_to :html, :js

  before_action :load_officer_assignment
  before_action :verify_officer_assignment
  before_action :verify_booth

  def new
    @user = User.find(params[:id])
    @polls = current_booth.polls.current
  end

  def create
    @poll = Poll.find(voter_params[:poll_id])
    @user = User.find(voter_params[:user_id])
    @voter = Poll::Voter.new(document_type: @user.document_type,
                             document_number: @user.document_number,
                             user: @user,
                             poll: @poll,
                             origin: "booth",
                             officer: current_user.poll_officer,
                             booth_assignment: current_booth.booth_assignments.find_by(poll: @poll),
                             officer_assignment: officer_assignment(@poll))

    @user.with_lock { @voter.save! }
  end

  private

    def voter_params
      params.require(:voter).permit(:poll_id, :user_id)
    end

    def officer_assignment(poll)
      Poll::OfficerAssignment.by_officer(current_user.poll_officer)
                             .by_poll(poll)
                             .by_booth(current_booth)
                             .by_date(Date.current)
                             .find_by(final: false)
    end
end
