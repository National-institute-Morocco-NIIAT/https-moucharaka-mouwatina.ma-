class CreatePollQuestionAnswers < ActiveRecord::Migration[4.2]
  def change
    create_table :poll_question_answers do |t|
      t.string :title
      t.text :description
      t.references :poll_question, index: true, foreign_key: true
    end
  end
end
