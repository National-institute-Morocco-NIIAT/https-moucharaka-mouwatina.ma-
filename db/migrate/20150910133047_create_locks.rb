class CreateLocks < ActiveRecord::Migration[4.2]
  def change
    create_table :locks do |t|
      t.references :user, index: true, foreign_key: true
      t.integer :tries, default: 0
      t.datetime :locked_until, null: false, default: Time.zone.now

      t.timestamps null: false
    end
  end
end
