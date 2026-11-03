class Batch < ApplicationRecord
  belongs_to :activity
  has_many :submissions, -> { order(:created_at, :id) }, dependent: :destroy, inverse_of: :batch

  validates :name, presence: true

  Stats = Data.define(:total, :done, :processing, :failed, :average, :highest, :lowest, :top, :bottom, :distribution) do
    def progress = total.zero? ? 0 : ((done + failed) * 100.0 / total).round
    def finished? = total.positive? && processing.zero?
  end

  def stats
    list = submissions.to_a
    graded = list.select(&:done?)
    scores = graded.map { |s| s.total_score.to_d }
    ranked = graded.sort_by { |s| [ s.total_score.to_d, s.id ] }
    distribution = Grading::CONCEPTS.reverse.to_h { |c| [ c[:code], graded.count { |s| s.concept == c[:code] } ] }

    Stats.new(
      total: list.size,
      done: graded.size,
      processing: list.count(&:processing?),
      failed: list.count(&:failed?),
      average: scores.any? ? (scores.sum / scores.size).round(1) : nil,
      highest: scores.max,
      lowest: scores.min,
      top: ranked.select { |s| s.total_score.to_d == scores.max },
      bottom: ranked.select { |s| s.total_score.to_d == scores.min },
      distribution: distribution
    )
  end

  def to_csv
    require "csv"
    keys = activity.rubric_items
    "\uFEFF" + CSV.generate(col_sep: ";") do |csv|
      csv << [ "Aluno(a)", *keys.map { |k| "#{k[:title]} (#{k[:max_points].to_i})" }, "Total", "Conceito", "Status" ]
      submissions.includes(:items).each do |s|
        by_key = s.items.index_by(&:key)
        csv << [
          s.display_name,
          *keys.map { |k| fmt(by_key[k[:key]]&.effective_points) },
          fmt(s.total_score), s.concept, s.status_label
        ]
      end
    end
  end

  private

  def fmt(value)
    return "" if value.nil?
    value.to_d.to_s("F").sub(/\.0\z/, "").tr(".", ",")
  end
end
