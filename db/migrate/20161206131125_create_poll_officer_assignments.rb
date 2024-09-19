class CreatePollOfficerAssignments < ActiveRecord::Migration[4.2]
  def change
    create_table :poll_officer_assignments do |t|
      t.integer :booth_assignment_id
      t.integer :officer_id
      t.timestamps null: false
    end
  end
end
