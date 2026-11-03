class CreateSubmissionItems < ActiveRecord::Migration[8.1]
  def change
    create_table :submission_items do |t|
      t.references :submission, null: false, foreign_key: true
      t.string :key
      t.string :title
      t.string :kind
      t.decimal :max_points, precision: 5, scale: 1, null: false
      t.decimal :ai_points, precision: 5, scale: 1
      t.decimal :teacher_points, precision: 5, scale: 1
      t.text :transcription
      t.text :feedback
      t.text :strengths
      t.json :issues, null: false, default: []
      t.integer :position
      t.integer :page_number

      t.timestamps
    end
  end
end
