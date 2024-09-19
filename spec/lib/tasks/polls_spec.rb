require "rails_helper"

describe "polls tasks" do
  let(:poll) { create(:poll) }
  let(:user) { create(:user, :level_two) }

  describe "polls:remove_duplicate_voters" do
    before { Rake::Task["polls:remove_duplicate_voters"].reenable }

    it "removes duplicate voters" do
      second_user = create(:user, :level_two)

      voter = create(:poll_voter, poll: poll, user: user)
      second_voter = create(:poll_voter, poll: poll, user: second_user)
      other_user_voter = create(:poll_voter, poll: poll, user: create(:user, :level_two))
      other_poll_voter = create(:poll_voter, poll: create(:poll), user: user)

      2.times { insert(:poll_voter, poll_id: poll.id, user_id: user.id) }
      insert(:poll_voter, poll_id: poll.id, user_id: second_user.id)

      expect(Poll::Voter.count).to eq 7

      Rake.application.invoke_task("polls:remove_duplicate_voters")

      expect(Poll::Voter.count).to eq 4
      expect(Poll::Voter.all).to match_array [voter, second_voter, other_user_voter, other_poll_voter]
    end

    it "removes duplicate voters on tenants" do
      create(:tenant, schema: "voters")

      Tenant.switch("voters") do
        poll = create(:poll)
        user = create(:user, :level_two)

        create(:poll_voter, poll: poll, user: user)
        insert(:poll_voter, poll_id: poll.id, user_id: user.id)

        expect(Poll::Voter.count).to eq 2
      end

      Rake.application.invoke_task("polls:remove_duplicate_voters")

      Tenant.switch("voters") do
        expect(Poll::Voter.count).to eq 1
      end
    end
  end

  describe "polls:remove_duplicate_answers" do
    before { Rake::Task["polls:remove_duplicate_answers"].reenable }

    it "removes duplicate answers" do
      question = create(:poll_question_multiple, :abcde, poll: poll, max_votes: 4)
      abc_question = create(:poll_question_multiple, :abc, poll: poll)

      answer_attributes = {
        question_id: question.id,
        author_id: user.id,
        answer: "Answer A",
        option_id: nil
      }
      abc_answer_attributes = answer_attributes.merge(question_id: abc_question.id, answer: "Answer B")

      answer = create(:poll_answer, answer_attributes)
      other_answer = create(:poll_answer, answer_attributes.merge(answer: "Answer B"))
      other_user_answer = create(:poll_answer, answer_attributes.merge(author_id: create(:user).id))
      abc_answer = create(:poll_answer, abc_answer_attributes)

      2.times { insert(:poll_answer, answer_attributes) }
      insert(:poll_answer, abc_answer_attributes)

      expect(Poll::Answer.count).to eq 7

      Rake.application.invoke_task("polls:remove_duplicate_answers")

      expect(Poll::Answer.count).to eq 4
      expect(Poll::Answer.all).to match_array [answer, other_answer, other_user_answer, abc_answer]
    end

    it "does not remove answers with the same text and different options" do
      question = create(:poll_question_multiple, :abcde, max_votes: 4)
      option_a = question.question_options.find_by(title: "Answer A")
      option_b = question.question_options.find_by(title: "Answer B")

      answer_attributes = { question: question, author: user, answer: "Answer A" }
      create(:poll_answer, answer_attributes.merge(option: option_a))
      create(:poll_answer, answer_attributes.merge(option: option_b))

      expect(Poll::Answer.count).to eq 2

      Rake.application.invoke_task("polls:remove_duplicate_answers")

      expect(Poll::Answer.count).to eq 2
    end

    it "removes duplicate answers in different languages" do
      question = create(:poll_question_multiple, max_votes: 2)

      create(:poll_question_option, question: question, title_en: "Yes", title_de: "Ja")
      create(:poll_question_option, question: question, title_en: "No", title_de: "Nein")
      create(:poll_question_option, question: question, title_en: "Maybe", title_de: "Vielleicht")

      create(:poll_answer, author: user, question: question, answer: "Yes", option: nil)
      create(:poll_answer, author: user, question: question, answer: "Ja", option: nil)

      expect(Poll::Answer.count).to eq 2

      Rake.application.invoke_task("polls:remove_duplicate_answers")

      expect(Poll::Answer.count).to eq 1
    end

    it "does not remove duplicate answers when many options are possible" do
      question = create(:poll_question_multiple, title: "How do you pronounce it?", max_votes: 2)

      create(:poll_question_option, question: question, title_en: "A", title_es: "EI")
      create(:poll_question_option, question: question, title_en: "E", title_es: "I")
      create(:poll_question_option, question: question, title_en: "I", title_es: "AI")

      create(:poll_answer, question: question, author: user, answer: "I", option: nil)
      create(:poll_answer, question: question, author: user, answer: "AI", option: nil)

      expect(Poll::Answer.count).to eq 2

      Rake.application.invoke_task("polls:remove_duplicate_answers")

      expect(Poll::Answer.count).to eq 2
    end

    it "removes duplicate answers on tenants" do
      create(:tenant, schema: "answers")

      Tenant.switch("answers") do
        user = create(:user, :level_two)
        question = create(:poll_question_multiple, :abc)

        answer_attributes = {
          question_id: question.id,
          author_id: user.id,
          answer: "Answer A",
          option_id: nil
        }
        create(:poll_answer, answer_attributes)
        insert(:poll_answer, answer_attributes)

        expect(Poll::Answer.count).to eq 2
      end

      Rake.application.invoke_task("polls:remove_duplicate_answers")

      Tenant.switch("answers") do
        expect(Poll::Answer.count).to eq 1
      end
    end
  end

  describe "polls:populate_option_id" do
    before do
      Rake::Task["polls:remove_duplicate_answers"].reenable
      Rake::Task["polls:populate_option_id"].reenable
    end

    it "populates the option_id column of existing answers when there's one valid answer" do
      yes_no_question = create(:poll_question, :yes_no, poll: poll)
      abc_question = create(:poll_question_multiple, :abc, poll: poll)
      option_a = abc_question.question_options.find_by(title: "Answer A")
      option_b = abc_question.question_options.find_by(title: "Answer B")

      answer = create(:poll_answer, question: yes_no_question, author: user, answer: "Yes", option: nil)
      abc_answer = create(:poll_answer, question: abc_question, author: user, answer: "Answer A", option: nil)
      answer_with_inconsistent_option = create(:poll_answer, question: abc_question,
                                                             author: user,
                                                             answer: "Answer A",
                                                             option: option_b)
      answer_with_invalid_option = build(:poll_answer, question: abc_question,
                                                       author: user,
                                                       answer: "Non existing",
                                                       option: nil)
      answer_with_invalid_option.save!(validate: false)

      Rake.application.invoke_task("polls:populate_option_id")
      answer.reload
      abc_answer.reload
      answer_with_inconsistent_option.reload
      answer_with_invalid_option.reload

      expect(answer.option_id).to eq yes_no_question.question_options.find_by(title: "Yes").id
      expect(abc_answer.option_id).to eq option_a.id
      expect(answer_with_inconsistent_option.option_id).to eq option_b.id
      expect(answer_with_invalid_option.option_id).to be nil
    end

    it "does not populate the option_id column when there are several valid options" do
      question = create(:poll_question, title: "How do you pronounce it?")

      create(:poll_question_option, question: question, title_en: "A", title_es: "EI")
      create(:poll_question_option, question: question, title_en: "E", title_es: "I")
      create(:poll_question_option, question: question, title_en: "I", title_es: "AI")

      answer = create(:poll_answer, question: question, author: user, answer: "I", option: nil)

      Rake.application.invoke_task("polls:populate_option_id")
      answer.reload

      expect(answer.option_id).to be nil
    end

    it "removes duplicate answers before populating the option_id column" do
      user = create(:user, :level_two)
      question = create(:poll_question_multiple, :abc)

      localized_question = create(:poll_question_multiple)
      create(:poll_question_option, question: localized_question, title_en: "Yes", title_de: "Ja")
      create(:poll_question_option, question: localized_question, title_en: "No", title_de: "Nein")
      create(:poll_question_option, question: localized_question, title_en: "Maybe", title_de: "Vielleicht")

      answer_attributes = {
        question_id: question.id,
        author_id: user.id,
        answer: "Answer A",
        option_id: nil
      }
      answer = create(:poll_answer, answer_attributes)
      insert(:poll_answer, answer_attributes)

      localized_answer_attributes = { author: user, question: localized_question, option: nil }
      localized_answer = create(:poll_answer, localized_answer_attributes.merge(answer: "Yes"))
      create(:poll_answer, localized_answer_attributes.merge(answer: "Ja"))

      answer.reload
      localized_answer.reload

      expect(answer.option_id).to be nil
      expect(localized_answer.option_id).to be nil

      Rake.application.invoke_task("polls:populate_option_id")
      answer.reload
      localized_answer.reload

      expect(Poll::Answer.count).to eq 2
      expect(answer.option_id).to eq question.question_options.find_by(title: "Answer A").id
      expect(localized_answer.option_id).to eq localized_question.question_options.find_by(title: "Yes").id
    end

    it "populates the option_id column on tenants" do
      create(:tenant, schema: "answers")

      Tenant.switch("answers") do
        question = create(:poll_question_multiple, :abc)

        create(:poll_answer, question: question, answer: "Answer A", option: nil)
      end

      Rake.application.invoke_task("polls:populate_option_id")

      Tenant.switch("answers") do
        expect(Poll::Question.count).to eq 1
        expect(Poll::Answer.count).to eq 1

        question = Poll::Question.first
        option_a = question.question_options.find_by(title: "Answer A")

        expect(Poll::Answer.first.option_id).to eq option_a.id
      end
    end
  end
end
