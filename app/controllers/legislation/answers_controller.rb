class Legislation::AnswersController < Legislation::BaseController
  before_action :authenticate_user!
  before_action :verify_resident!

  load_and_authorize_resource :process
  load_and_authorize_resource :question, through: :process
  load_and_authorize_resource :answer, through: :question

  respond_to :html, :js

  def create
    if @process.debate_phase.open?
      @answer.user = current_user
      @answer.save!
      respond_to do |format|
        format.js
        format.html { redirect_to legislation_process_question_path(@process, @question) }
      end
    else
      alert = t("legislation.questions.participation.phase_not_open")
      respond_to do |format|
        format.js { render json: {}, status: :not_found }
        format.html { redirect_to legislation_process_question_path(@process, @question), alert: alert }
      end
    end
  end

  private

    def answer_params
      params.require(:legislation_answer).permit(allowed_params)
    end

    def allowed_params
      [:legislation_question_option_id]
    end
end
