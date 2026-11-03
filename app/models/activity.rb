class Activity < ApplicationRecord
  has_many :batches, dependent: :destroy
  has_one_attached :reference_file

  validates :name, presence: true

  def rubric_items
    Array(rubric).map(&:with_indifferent_access)
  end

  def rubric_item(key)
    rubric_items.find { |item| item[:key] == key.to_s }
  end

  def total_points
    rubric_items.sum { |item| item[:max_points].to_d }
  end

  def sections
    rubric_items.group_by { |item| item[:kind] }
  end
end
