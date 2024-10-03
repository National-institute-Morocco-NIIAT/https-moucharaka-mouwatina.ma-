class AddIdCardImagesToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :front_id_card, :string
    add_column :users, :back_id_card, :string
  end
end
