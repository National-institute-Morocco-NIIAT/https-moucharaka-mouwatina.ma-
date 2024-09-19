class CreatePollWhiteResults < ActiveRecord::Migration[4.2]
  def change
    create_table :poll_white_results do |t|
      t.integer :author_id
      t.integer :amount
      t.string  :origin
      t.date    :date
      t.integer :booth_assignment_id
      t.integer :officer_assignment_id
      t.text    :amount_log,                default: ""
      t.text    :officer_assignment_id_log, default: ""
      t.text    :author_id_log,             default: ""
    end

    add_index :poll_white_results, :officer_assignment_id
    add_index :poll_white_results, :booth_assignment_id
  end
end
