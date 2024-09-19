require "rails_helper"

RSpec.describe Legislation::Answer do
  let(:legislation_answer) { build(:legislation_answer) }

  it "is valid" do
    expect(legislation_answer).to be_valid
  end

  it "counts answers" do
    question = create(:legislation_question)
    option_1 = create(:legislation_question_option, question: question, value: "Yes")
    option_2 = create(:legislation_question_option, question: question, value: "No")

    answer = create(:legislation_answer, question: question, question_option: option_2)

    expect(answer).to be_valid
    expect(question.answers_count).to eq 1
    expect(option_2.answers_count).to eq 1
    expect(option_1.answers_count).to eq 0
  end

  it "can't answer same question more than once" do
    question = create(:legislation_question)
    option_1 = create(:legislation_question_option, question: question, value: "Yes")
    option_2 = create(:legislation_question_option, question: question, value: "No")
    user = create(:user)

    answer = create(:legislation_answer, question: question, question_option: option_2, user: user)
    expect(answer).to be_valid

    second_answer = build(:legislation_answer, question: question, question_option: option_1, user: user)
    expect(second_answer).not_to be_valid

    expect(question.answers_count).to eq 1
    expect(option_2.answers_count).to eq 1
    expect(option_1.answers_count).to eq 0
  end

  it "does not delete users that created the answer" do
    user = legislation_answer.user

    legislation_answer.destroy!

    expect(user).not_to be_hidden
  end
end
