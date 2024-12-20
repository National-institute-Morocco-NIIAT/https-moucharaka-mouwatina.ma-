namespace :polls do
  desc "Removes duplicate poll voters"
  task remove_duplicate_voters: :environment do
    logger = ApplicationLogger.new
    duplicate_records_logger = DuplicateRecordsLogger.new

    logger.info "Removing duplicate voters in polls"

    Tenant.run_on_each do
      duplicate_ids = Poll::Voter.select(:user_id, :poll_id)
                                 .group(:user_id, :poll_id)
                                 .having("count(*) > 1")
                                 .pluck(:user_id, :poll_id)

      duplicate_ids.each do |user_id, poll_id|
        voters = Poll::Voter.where(user_id: user_id, poll_id: poll_id)
        voters.excluding(voters.first).each do |voter|
          voter.delete

          tenant_info = " on tenant #{Tenant.current_schema}" unless Tenant.default?
          log_message = "Deleted duplicate record with ID #{voter.id} " \
                        "from the #{Poll::Voter.table_name} table " \
                        "with user_id #{user_id} " \
                        "and poll_id #{poll_id}" + tenant_info.to_s
          logger.info(log_message)
          duplicate_records_logger.info(log_message)
        end
      end
    end
  end

  desc "Removes duplicate poll answers"
  task remove_duplicate_answers: :environment do
    logger = ApplicationLogger.new
    duplicate_records_logger = DuplicateRecordsLogger.new

    logger.info "Removing duplicate answers in polls"

    Tenant.run_on_each do
      Poll::Question.find_each do |question|
        manageable_titles = PollOptionFinder.new(question).manageable_choices.keys

        question.question_options.each do |option|
          titles = option.translations.where(title: manageable_titles).select(:title).distinct

          author_ids = question.answers
                               .where(answer: titles)
                               .select(:author_id)
                               .group(:author_id)
                               .having("count(*) > 1")
                               .pluck(:author_id)

          author_ids.each do |author_id|
            poll_answers = question.answers.where(option_id: nil, answer: titles, author_id: author_id)

            poll_answers.excluding(poll_answers.first).each do |poll_answer|
              poll_answer.delete

              tenant_info = " on tenant #{Tenant.current_schema}" unless Tenant.default?
              log_message = "Deleted duplicate record with ID #{poll_answer.id} " \
                            "from the #{Poll::Answer.table_name} table " \
                            "with question_id #{question.id}, " \
                            "author_id #{author_id} " \
                            "and answer #{poll_answer.answer}" + tenant_info.to_s
              logger.info(log_message)
              duplicate_records_logger.info(log_message)
            end
          end
        end
      end
    end
  end

  desc "populates the poll answers option_id column"
  task populate_option_id: :remove_duplicate_answers do
    logger = ApplicationLogger.new
    logger.info "Updating option_id column in poll_answers"

    Tenant.run_on_each do
      questions = Poll::Question.select do |question|
        # Change this if you've added a custom votation type
        # to your Moucharaka Mouwatina installation that implies
        # choosing among a few given options
        question.unique? || question.multiple?
      end

      questions.each do |question|
        option_finder = PollOptionFinder.new(question)

        option_finder.manageable_choices.each do |choice, ids|
          question.answers.where(option_id: nil, answer: choice).update_all(option_id: ids.first)
        end

        option_finder.unmanageable_choices.each do |choice, ids|
          tenant_info = " on tenant #{Tenant.current_schema}" unless Tenant.default?

          if ids.count == 0
            logger.warn "Skipping poll_answers with the text \"#{choice}\" for the poll_question " \
                        "with ID #{question.id}. This question has no poll_question_answers " \
                        "containing the text \"#{choice}\"" + tenant_info.to_s
          else
            logger.warn "Skipping poll_answers with the text \"#{choice}\" for the poll_question " \
                        "with ID #{question.id}. The text \"#{choice}\" could refer to any of these " \
                        "IDs in the poll_question_answers table: #{ids.join(", ")}" + tenant_info.to_s
          end
        end
      end
    end
  end
end
