class CreateSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :submissions do |t|
      t.references :batch, null: false, foreign_key: true
      t.string :student_name
      t.string :status, null: false, default: "queued"
      t.string :original_filename
      t.decimal :total_score, precision: 5, scale: 1
      t.string :concept
      t.text :overall_feedback
      t.text :extracted_text
      t.text :error_message
      t.datetime :graded_at
      t.integer :position

      t.timestamps
    end
  end
end
