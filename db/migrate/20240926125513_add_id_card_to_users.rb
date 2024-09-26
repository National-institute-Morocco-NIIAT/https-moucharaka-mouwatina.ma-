class AddIdCardToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :id_card_file, :string
    add_column :users, :id_card_verified_at, :datetime
    add_column :users, :id_card_verification_status, :string
  end
end
