class AddGeozoneToProposalsAndDebates < ActiveRecord::Migration[4.2]
  def change
    add_column :proposals, :geozone_id, :integer, default: nil
    add_index :proposals, :geozone_id

    add_column :debates, :geozone_id, :integer, default: nil
    add_index :debates, :geozone_id
  end
end
