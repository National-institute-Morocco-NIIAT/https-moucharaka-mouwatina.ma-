class AddFormerUsersDataLogToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :former_users_data_log, :text, default: ""
  end
end
