require "test_helper"

class GradeSubmissionJobTest < ActiveSupport::TestCase
  test "corrige a prova respondida: tabela alta, perguntas em branco = NS" do
    submission = create_submission
    with_fake_openai { GradeSubmissionJob.perform_now(submission) }
    submission.reload

    assert_equal "done", submission.status
    assert_equal 10, submission.items.count
    assert_equal 2, submission.pages.count
    assert_equal 36.5, submission.items.where(kind: "table").sum(:ai_points)
    assert_equal 0, submission.items.where(kind: "open").sum(:ai_points)
    assert_equal "NS", submission.concept
    assert_includes submission.extracted_text, "Chris"
  end

  test "erro definitivo marca a prova como falha com mensagem" do
    submission = create_submission
    previous = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = ""
    GradeSubmissionJob.perform_now(submission)
    submission.reload
    assert_equal "failed", submission.status
    assert_match "OPENAI_API_KEY", submission.error_message
  ensure
    ENV["OPENAI_API_KEY"] = previous
  end
end
