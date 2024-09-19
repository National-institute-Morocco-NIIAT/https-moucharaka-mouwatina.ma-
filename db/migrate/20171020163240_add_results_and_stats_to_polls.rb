class AddResultsAndStatsToPolls < ActiveRecord::Migration[4.2]
  def change
    add_column :polls, :results_enabled, :boolean, default: false
    add_column :polls, :stats_enabled, :boolean, default: false
  end
end
