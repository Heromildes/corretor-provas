class SubmissionItem < ApplicationRecord
  ISSUE_KINDS = {
    "grammar"    => "Gramática",
    "spelling"   => "Ortografia",
    "vocabulary" => "Vocabulário",
    "content"    => "Conteúdo",
    "incomplete" => "Incompleto"
  }.freeze

  belongs_to :submission

  validates :key, :title, :max_points, presence: true
  validates :teacher_points, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :teacher_points_within_max

  before_validation :normalize_teacher_points

  after_update_commit :refresh_submission, if: :saved_change_to_teacher_points?

  def effective_points
    teacher_points || ai_points || 0
  end

  def adjusted_by_teacher? = !teacher_points.nil?
  def table? = kind == "table"

  def ratio
    return 0 if max_points.to_d.zero?
    (effective_points.to_d / max_points.to_d).to_f
  end

  # Faixa de cor do bloco (vermelho, âmbar, azul, verde) pela proporção da nota.
  def tone
    case ratio
    when 0.9.. then "mb"
    when 0.75...0.9 then "b"
    when 0.6...0.75 then "r"
    else "ns"
    end
  end

  def issue_list
    Array(issues).map(&:with_indifferent_access)
  end

  private

  def normalize_teacher_points
    self.teacher_points = Grading.normalize_points(teacher_points, max_points) if teacher_points.present? && max_points.present?
  end

  def teacher_points_within_max
    return if teacher_points.nil? || max_points.nil?
    errors.add(:teacher_points, "não pode passar de #{max_points.to_i}") if teacher_points > max_points
  end

  def refresh_submission
    submission.recalculate!
    broadcast_replace_to submission, target: self, partial: "submission_items/item", locals: { item: self }
  end
end
