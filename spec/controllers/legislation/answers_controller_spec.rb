require "rails_helper"

describe Legislation::AnswersController do
  describe "POST create" do
    let(:legal_process) do
      create(:legislation_process, debate_start_date: Date.current - 3.days,
                                   debate_end_date: Date.current + 2.days)
    end
    let(:question) { create(:legislation_question, process: legal_process, title: "Question 1") }
    let(:question_option) { create(:legislation_question_option, question: question, value: "Yes") }
    let(:user) { create(:user, :level_two) }

    it "creates an answer if the process debate phase is open" do
      sign_in user

      expect do
        post :create, xhr: true,
                      params: {
                        process_id: legal_process.id,
                        question_id: question.id,
                        legislation_answer: {
                          legislation_question_option_id: question_option.id
                        }
                      }
      end.to change { question.reload.answers_count }.by(1)
    end

    it "does not create an answer if the process debate phase is not open" do
      sign_in user
      legal_process.update!(debate_end_date: Date.current - 1.day)

      expect do
        post :create, xhr: true,
                      params: {
                        process_id: legal_process.id,
                        question_id: question.id,
                        legislation_answer: {
                          legislation_question_option_id: question_option.id
                        }
                      }
      end.not_to change { question.reload.answers_count }
    end
  end
end
