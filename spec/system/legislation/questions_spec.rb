require "rails_helper"

describe "Legislation" do
  context "process debate page" do
    let(:process) do
      create(:legislation_process,
             debate_start_date: Date.current - 3.days,
             debate_end_date: Date.current + 2.days)
    end

    before do
      create(:legislation_question, process: process, title: "Question 1", description: "Description 1")
      create(:legislation_question, process: process, title: "Question 2", description: "Description 2")
      create(:legislation_question, process: process, title: "Question 3", description: "Description 3")
    end

    it_behaves_like "notifiable in-app", :legislation_question

    scenario "shows question list" do
      visit legislation_process_path(process)

      expect(page).to have_content("Question 1")
      expect(page).to have_content("Question 2")
      expect(page).to have_content("Question 3")

      click_link "Question 1"

      expect(page).to have_content("Question 1")
      expect(page).to have_content("Description 1")
      expect(page).to have_content("NEXT QUESTION")

      click_link "Next question"

      expect(page).to have_content("Question 2")
      expect(page).to have_content("Description 2")
      expect(page).to have_content("NEXT QUESTION")

      click_link "Next question"

      expect(page).to have_content("Question 3")
      expect(page).to have_content("Description 3")
      expect(page).not_to have_content("NEXT QUESTION")
    end

    scenario "shows question page" do
      visit legislation_process_question_path(process, process.questions.first)

      expect(page).to have_content("Question 1")
      expect(page).to have_content("Description 1")
      expect(page).to have_content("Open answers (0)")
    end

    scenario "shows next question link in question page" do
      visit legislation_process_question_path(process, process.questions.first)

      expect(page).to have_content("Question 1")
      expect(page).to have_content("Description 1")
      expect(page).to have_content("NEXT QUESTION")

      click_link "Next question"

      expect(page).to have_content("Question 2")
      expect(page).to have_content("Description 2")
      expect(page).to have_content("NEXT QUESTION")

      click_link "Next question"

      expect(page).to have_content("Question 3")
      expect(page).to have_content("Description 3")
      expect(page).not_to have_content("NEXT QUESTION")
    end

    scenario "answer question", :no_js do
      question = process.questions.first
      create(:legislation_question_option, question: question, value: "Yes")
      create(:legislation_question_option, question: question, value: "No")
      option = create(:legislation_question_option, question: question, value: "I don't know")
      user = create(:user, :level_two)

      login_as(user)

      visit legislation_process_question_path(process, question)

      expect(page).to have_selector(:radio_button, "Yes")
      expect(page).to have_selector(:radio_button, "No")
      expect(page).to have_selector(:radio_button, "I don't know")
      expect(page).to have_selector(:link_or_button, "Submit answer")

      choose("I don't know")
      click_button "Submit answer"

      within(:css, "label.is-active") do
        expect(page).to have_content("I don't know")
        expect(page).not_to have_content("Yes")
        expect(page).not_to have_content("No")
      end
      expect(page).not_to have_selector(:link_or_button, "Submit answer")

      expect(question.reload.answers_count).to eq(1)
      expect(option.reload.answers_count).to eq(1)
    end

    scenario "cannot answer question when phase not open", :no_js do
      process.update!(debate_end_date: Date.current - 1.day)
      question = process.questions.first
      create(:legislation_question_option, question: question, value: "Yes")
      create(:legislation_question_option, question: question, value: "No")
      create(:legislation_question_option, question: question, value: "I don't know")
      user = create(:user, :level_two)

      login_as(user)

      visit legislation_process_question_path(process, question)

      expect(page).to have_selector(:radio_button, "Yes", disabled: true)
      expect(page).to have_selector(:radio_button, "No", disabled: true)
      expect(page).to have_selector(:radio_button, "I don't know", disabled: true)

      expect(page).not_to have_selector(:link_or_button, "Submit answer")
    end

    scenario "render link to questions comments with anchor" do
      question = create(:legislation_question, process: process, title: "Question without comments")

      visit legislation_process_path(process)

      expect(page).to have_link "No comments", href: legislation_process_question_path(process,
                                                                                       question,
                                                                                       anchor: "comments")
    end
  end
end
