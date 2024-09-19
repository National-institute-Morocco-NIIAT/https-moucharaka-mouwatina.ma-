class CreatePollVoters < ActiveRecord::Migration[4.2]
  def change
    create_table :poll_voters do |t|
      t.integer :booth_id
      t.string :document_number
      t.string :document_type
    end
  end
end
