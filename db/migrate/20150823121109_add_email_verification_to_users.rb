class AddEmailVerificationToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :email_verification_token, :string
    add_column :users, :email_for_verification, :string
  end
end
