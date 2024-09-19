class AddsTsvectorUpdateTrigger < ActiveRecord::Migration[4.2]
  def up
    add_column :proposals, :tsv, :tsvector
    add_index :proposals, :tsv, using: "gin"
  end

  def down
    remove_index :proposals, :tsv
    remove_column :proposals, :tsv
  end
end
