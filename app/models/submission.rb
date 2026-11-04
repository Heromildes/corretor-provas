class Submission < ApplicationRecord
  STATUSES = {
    "queued"  => "Na fila",
    "reading" => "Lendo a prova",
    "grading" => "Corrigindo com IA",
    "done"    => "Corrigida",
    "failed"  => "Falhou"
  }.freeze

  MAX_FILE_SIZE = 25.megabytes
  MAX_FILES = 8

  ACCEPTED_TYPES = %w[
    application/pdf image/jpeg image/png image/webp image/heic image/heif
  ].freeze

  belongs_to :batch, touch: true
  has_many :items, -> { order(:position) }, class_name: "SubmissionItem", dependent: :destroy, inverse_of: :submission
  # Todas as páginas/fotos/PDFs de UM aluno (ex.: frente e verso), na ordem do envio.
  has_many_attached :files
  has_many_attached :pages

  validates :status, inclusion: { in: STATUSES.keys }
  validate :files_are_supported, on: :create

  delegate :activity, to: :batch

  after_create_commit :broadcast_created
  after_update_commit :broadcast_changed
  after_destroy_commit :broadcast_removed

  STATUSES.each_key do |name|
    define_method(:"#{name}?") { status == name }
  end

  def processing? = %w[queued reading grading].include?(status)
  def status_label = STATUSES[status]
  def concept_label = Grading.label_for(concept)

  def display_name
    student_name.presence || original_filename.to_s.split(",").first.to_s.strip.sub(/\.[^.]+\z/, "").presence || "Aluno sem nome"
  end

  # Nomes dos arquivos enviados, para mostrar na lista (ex.: "frente.jpg, verso.jpg").
  def self.describe_files(uploads)
    uploads.map { |u| u.respond_to?(:original_filename) ? u.original_filename : u[:filename] }.compact.join(", ")
  end

  def section_points(kind)
    items.select { |item| item.kind == kind }.sum(&:effective_points)
  end

  def adjusted_by_teacher?
    items.any?(&:adjusted_by_teacher?)
  end

  def neighbors
    ids = batch.submissions.ids
    index = ids.index(id)
    [ index&.positive? ? ids[index - 1] : nil, index ? ids[index + 1] : nil ]
  end

  def start!
    update!(status: "queued", error_message: nil)
    GradeSubmissionJob.perform_later(self)
  end

  def fail!(message)
    update!(status: "failed", error_message: message.to_s.truncate(500))
  end

  # Grava o resultado estruturado vindo da IA.
  def apply_result!(result)
    transaction do
      items.destroy_all
      activity.rubric_items.each_with_index do |rubric, index|
        answer = result.item(rubric[:key])
        transcription = answer[:transcription].to_s.strip
        criteria, points = Grading.score_criteria(rubric, answer[:criteria], blank: transcription.blank?)
        items.create!(
          key: rubric[:key],
          title: rubric[:title],
          kind: rubric[:kind],
          max_points: rubric[:max_points],
          position: index,
          page_number: answer[:page],
          ai_points: points,
          criteria: criteria,
          transcription: transcription,
          feedback: answer[:feedback],
          strengths: answer[:strengths],
          issues: answer[:issues]
        )
      end
      self.student_name = result.student_name if student_name.blank? && result.student_name.present?
      self.overall_feedback = result.overall_feedback
      self.graded_at = Time.current
      self.status = "done"
      recalculate(save: false)
      save!
    end
  end

  def recalculate!(save: true) = recalculate(save:)

  def recalculate(save: true)
    total = items.reload.sum(&:effective_points)
    self.total_score = total
    self.concept = Grading.concept_for(total)
    save! if save
  end

  private

  def files_are_supported
    blobs = files.map(&:blob)
    if blobs.empty?
      errors.add(:files, "são obrigatórios")
    elsif blobs.size > MAX_FILES
      errors.add(:files, "são no máximo #{MAX_FILES} por aluno")
    elsif (bad = blobs.find { |b| ACCEPTED_TYPES.exclude?(b.content_type) })
      errors.add(:files, "precisam ser PDF ou imagem (JPG, PNG, HEIC): #{bad.filename}")
    elsif (big = blobs.find { |b| b.byte_size > MAX_FILE_SIZE })
      errors.add(:files, "não podem passar de #{MAX_FILE_SIZE / 1.megabyte} MB cada: #{big.filename}")
    end
  end

  def broadcast_created
    broadcast_append_to [ batch, :submissions ], target: "submissions", partial: "submissions/row", locals: { submission: self }
    broadcast_batch_stats
  end

  def broadcast_changed
    broadcast_replace_to [ batch, :submissions ], target: self, partial: "submissions/row", locals: { submission: self }
    # Mudança só no nome: o cabeçalho já mostra o que a professora digitou (evita recriar o campo com foco).
    unless (saved_changes.keys - %w[student_name updated_at]).empty?
      broadcast_replace_to self, target: "submission_header", partial: "submissions/header", locals: { submission: self }
      broadcast_replace_to self, target: "submission_summary", partial: "submissions/summary", locals: { submission: self }
    end
    if saved_change_to_status?
      broadcast_replace_to self, target: "submission_body", partial: "submissions/body", locals: { submission: self }
      broadcast_replace_to self, target: "submission_pages", partial: "submissions/pages", locals: { submission: self }
    end
    broadcast_batch_stats
  end

  def broadcast_removed
    return unless Batch.exists?(batch_id)
    broadcast_remove_to [ batch, :submissions ], target: self
    broadcast_batch_stats
  end

  def broadcast_batch_stats
    return unless Batch.exists?(batch_id)
    broadcast_replace_to [ batch, :submissions ], target: "batch_stats", partial: "batches/stats", locals: { batch: batch.reload }
  end
end
