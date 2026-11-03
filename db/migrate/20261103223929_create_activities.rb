class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.string :name, null: false
      t.string :subject
      t.text :instructions
      t.json :rubric, null: false, default: []
      t.text :reference_text

      t.timestamps
    end
  end
end
