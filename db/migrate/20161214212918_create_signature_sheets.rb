class CreateSignatureSheets < ActiveRecord::Migration[4.2]
  def change
    create_table :signature_sheets do |t|
      t.references :signable, polymorphic: true
      t.text :document_numbers
      t.boolean :processed, default: false
      t.references :author
      t.timestamps
    end
  end
end
