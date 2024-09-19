class CreateWidgetFeeds < ActiveRecord::Migration[4.2]
  def change
    create_table :widget_feeds do |t|
      t.string :kind
      t.integer :limit, default: 3
      t.timestamps null: false
    end
  end
end
