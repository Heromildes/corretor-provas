require "test_helper"

class BatchTest < ActiveSupport::TestCase
  test "estatísticas trazem os alunos da maior e da menor nota" do
    batch = Batch.create!(name: "T", activity: activity)
    ana, bia, caio = %w[Ana Bia Caio].map.with_index do |name, i|
      s = batch.submissions.create!(student_name: name, files: [ { io: File.open(ANSWERED_PDF), filename: "#{name}.pdf", content_type: "application/pdf" } ])
      s.update_columns(status: "done", total_score: [ 92, 41, 92 ][i], concept: Grading.concept_for([ 92, 41, 92 ][i]))
      s
    end

    stats = batch.reload.stats
    assert_equal 92, stats.highest
    assert_equal [ ana, caio ], stats.top, "empate: os dois aparecem"
    assert_equal [ bia ], stats.bottom
    assert_equal({ "NS" => 1, "R" => 0, "B" => 0, "MB" => 2 }, stats.distribution)
  end
end
