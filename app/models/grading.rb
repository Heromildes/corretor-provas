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

  # Converte a avaliação da IA por critério na nota do bloco.
  # Cada critério só pode valer um dos níveis da rubrica: o valor da IA é "encaixado" no nível mais próximo
  # (empate → o menor). A nota do bloco é a soma — calculada aqui, não pela IA.
  # Retorna [ critérios (com label, pontos, máximo e justificativa), total ].
  def score_criteria(rubric_item, answers, blank: false)
    answers = Array(answers).map { |a| a.to_h.with_indifferent_access }
    scored = Array(rubric_item[:criteria]).map do |criterion|
      criterion = criterion.with_indifferent_access
      levels = criterion[:levels].map { |l| l[:points].to_d }.sort
      answer = answers.find { |a| a[:key].to_s == criterion[:key].to_s }
      raw = blank || answer.nil? ? 0 : answer[:points].to_d
      points = levels.min_by { |level| [ (level - raw).abs, level ] }
      {
        "key" => criterion[:key], "label" => criterion[:label],
        "points" => points.to_f, "max" => levels.max.to_f,
        "reason" => (blank ? "Resposta em branco." : answer&.dig(:reason).to_s)
      }
    end
    total = scored.sum { |c| c["points"].to_d }
    [ scored, normalize_points(total, rubric_item[:max_points]) ]
  end

  # Arredonda para o passo de 0,5 e limita entre 0 e o máximo do item.
  def normalize_points(points, max)
    value = (points.to_d / STEP).round * STEP
    value.clamp(0, max.to_d).to_d
  end
end
