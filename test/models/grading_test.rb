require "test_helper"

class GradingTest < ActiveSupport::TestCase
  test "conceitos nos limites de cada faixa" do
    { 0 => "NS", 59 => "NS", 59.5 => "NS", 60 => "R", 74.5 => "R", 75 => "B", 89.5 => "B", 90 => "MB", 100 => "MB" }.each do |score, concept|
      assert_equal concept, Grading.concept_for(score), "nota #{score}"
    end
    assert_nil Grading.concept_for(nil)
  end

  test "arredonda para meio ponto e limita ao máximo" do
    assert_equal 4.5, Grading.normalize_points(4.4, 5)
    assert_equal 5, Grading.normalize_points(7, 5)
    assert_equal 0, Grading.normalize_points(-2, 5)
    assert_equal 27.5, Grading.normalize_points(27.6, 30)
  end

  test "rubrica soma 100 pontos: 8 x 5 + 2 x 30" do
    assert_equal 100, activity.total_points
    assert_equal 8, activity.sections["table"].size
    assert_equal [ 30, 30 ], activity.sections["open"].map { _1[:max_points] }
  end
end
