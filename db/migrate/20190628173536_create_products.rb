class CreateProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :products do |t|
      t.string :name
      t.integer :cost_cents
      t.integer :inventory

      t.timestamps
    end
  end
end
