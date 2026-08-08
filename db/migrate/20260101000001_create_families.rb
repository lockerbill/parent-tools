class CreateFamilies < ActiveRecord::Migration[8.0]
  def change
    create_table :families do |t|
      t.string :name, null: false
      t.json :settings, null: false, default: {}

      t.timestamps
    end
  end
end
