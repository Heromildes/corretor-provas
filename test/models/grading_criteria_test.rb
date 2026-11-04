require "test_helper"

class GradingCriteriaTest < ActiveSupport::TestCase
  def table_item = activity.rubric_item(:teamwork)

  test "soma os níveis dos critérios" do
    criteria, total = Grading.score_criteria(table_item, [
      { key: "cena", points: 2, reason: "ok" }, { key: "ligacao", points: 1, reason: "ok" },
      { key: "detalhe", points: 0.5, reason: "ok" }, { key: "ingles", points: 0.5, reason: "ok" }
    ])
    assert_equal 4, total
    assert_equal %w[cena ligacao detalhe ingles], criteria.map { _1["key"] }
    assert_equal "Cena do filme", criteria.first["label"]
  end

  test "valor fora dos níveis é encaixado no nível mais próximo; empate vai para o menor" do
    _, total = Grading.score_criteria(table_item, [
      { key: "cena", points: 1.6, reason: "" },    # → 2
      { key: "ligacao", points: 0.75, reason: "" }, # empate 0,5 / 1 → 0,5
      { key: "detalhe", points: 7, reason: "" },     # → 1 (máximo)
      { key: "ingles", points: -3, reason: "" }      # → 0
    ])
    assert_equal 3.5, total
  end

  test "critério ausente vale zero e resposta em branco zera tudo" do
    _, total = Grading.score_criteria(table_item, [ { key: "cena", points: 2, reason: "" } ])
    assert_equal 2, total

    criteria, total = Grading.score_criteria(table_item, [ { key: "cena", points: 2, reason: "" } ], blank: true)
    assert_equal 0, total
    assert criteria.all? { _1["points"].zero? }
  end

  test "perguntas abertas somam até 30" do
    item = activity.rubric_item(:strongest)
    _, total = Grading.score_criteria(item, [
      { key: "identificacao", points: 6 }, { key: "justificativa", points: 12 },
      { key: "analise", points: 6 }, { key: "ingles", points: 6 }
    ])
    assert_equal 30, total
  end
end
