class CreateSpendingProposals < ActiveRecord::Migration[4.2]
  def change
    create_table :spending_proposals do |t|
      t.string :title
      t.text :description
      t.integer :author_id
      t.string :external_url

      t.timestamps null: false
    end
  end
end
