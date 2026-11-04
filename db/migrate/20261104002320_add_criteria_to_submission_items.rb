# Nota por critério da rubrica (nível escolhido pela IA + justificativa). A nota do bloco é a soma.
class AddCriteriaToSubmissionItems < ActiveRecord::Migration[8.1]
  def change
    add_column :submission_items, :criteria, :json, null: false, default: []
  end
end
