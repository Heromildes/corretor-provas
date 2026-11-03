# Regras de nota e conceito do Instituto.
#   NS (Não Satisfatório) 0–59 · R (Regular) 60–74 · B (Bom) 75–89 · MB (Muito Bom) 90–100
module Grading
  CONCEPTS = [
    { code: "MB", min: 90, label: "Muito Bom" },
    { code: "B",  min: 75, label: "Bom" },
    { code: "R",  min: 60, label: "Regular" },
    { code: "NS", min: 0,  label: "Não Satisfatório" }
  ].freeze

  STEP = 0.5

  module_function

  def concept_for(score)
    return nil if score.nil?
    CONCEPTS.find { |c| score.to_d >= c[:min] }[:code]
  end

  def label_for(code)
    CONCEPTS.find { |c| c[:code] == code }&.dig(:label)
  end

  # Arredonda para o passo de 0,5 e limita entre 0 e o máximo do item.
  def normalize_points(points, max)
    value = (points.to_d / STEP).round * STEP
    value.clamp(0, max.to_d).to_d
  end
end
