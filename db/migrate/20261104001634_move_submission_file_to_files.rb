# Uma prova (aluno) passa a ter vários arquivos (ex.: foto da frente e do verso).
# Os anexos antigos `file` viram o primeiro item de `files`.
class MoveSubmissionFileToFiles < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE active_storage_attachments SET name = 'files' WHERE record_type = 'Submission' AND name = 'file'"
  end

  def down
    execute "UPDATE active_storage_attachments SET name = 'file' WHERE record_type = 'Submission' AND name = 'files'"
  end
end
