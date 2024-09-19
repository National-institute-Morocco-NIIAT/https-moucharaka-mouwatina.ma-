require "rails_helper"

describe "Poll Results" do
  scenario "List each Poll question" do
    user1 = create(:user, :level_two)
    user2 = create(:user, :level_two)
    user3 = create(:user, :level_two)

    poll = create(:poll, results_enabled: true)
    question1 = create(:poll_question, poll: poll)
    option1 = create(:poll_question_option, question: question1, title: "Yes")
    option2 = create(:poll_question_option, question: question1, title: "No")

    question2 = create(:poll_question, poll: poll)
    option3 = create(:poll_question_option, question: question2, title: "Blue")
    option4 = create(:poll_question_option, question: question2, title: "Green")
    option5 = create(:poll_question_option, question: question2, title: "Yellow")

    login_as user1
    vote_for_poll_via_web(poll, question1, "Yes")
    vote_for_poll_via_web(poll, question2, "Blue")
    logout

    login_as user2
    vote_for_poll_via_web(poll, question1, "Yes")
    vote_for_poll_via_web(poll, question2, "Green")
    logout

    login_as user3
    vote_for_poll_via_web(poll, question1, "No")
    vote_for_poll_via_web(poll, question2, "Yellow")
    logout

    travel_to(poll.ends_at + 1.day)

    visit results_poll_path(poll)

    expect(page).to have_content(question1.title)
    expect(page).to have_content(question2.title)

    within("#question_#{question1.id}_results_table") do
      expect(find("#option_#{option1.id}_result")).to have_content("2 (66.67%)")
      expect(find("#option_#{option2.id}_result")).to have_content("1 (33.33%)")
    end

    within("#question_#{question2.id}_results_table") do
      expect(find("#option_#{option3.id}_result")).to have_content("1 (33.33%)")
      expect(find("#option_#{option4.id}_result")).to have_content("1 (33.33%)")
      expect(find("#option_#{option5.id}_result")).to have_content("1 (33.33%)")
    end
  end

  scenario "Results for polls with questions but without options" do
    poll = create(:poll, :expired, results_enabled: true)
    question = create(:poll_question, poll: poll)

    visit results_poll_path(poll)

    expect(page).to have_content question.title
  end
end
