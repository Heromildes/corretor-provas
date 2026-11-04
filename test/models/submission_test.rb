require "test_helper"

class SubmissionTest < ActiveSupport::TestCase
  test "rejeita arquivos que não são PDF ou imagem" do
    batch = Batch.create!(name: "T", activity: activity)
    submission = batch.submissions.new(files: [ { io: StringIO.new("oi"), filename: "nota.txt", content_type: "text/plain" } ])
    assert_not submission.valid?
    assert submission.errors[:files].any?
  end

  test "nota ajustada pela professora recalcula total e conceito" do
    submission = create_submission
    with_fake_openai { GradeSubmissionJob.perform_now(submission) }
    submission.reload
    assert_equal 36.5, submission.total_score
    assert_equal "NS", submission.concept

    strongest = submission.items.find_by!(key: "strongest")
    weakest = submission.items.find_by!(key: "weakest")
    strongest.update!(teacher_points: 30)
    weakest.update!(teacher_points: 26.3) # vira 26,5

    submission.reload
    assert_equal 26.5, weakest.reload.teacher_points
    assert_equal 93, submission.total_score
    assert_equal "MB", submission.concept
    assert submission.adjusted_by_teacher?
  end

  test "professora não pode dar mais que o máximo do item" do
    submission = create_submission
    with_fake_openai { GradeSubmissionJob.perform_now(submission) }
    item = submission.items.find_by!(key: "teamwork")
    item.teacher_points = 9
    assert item.valid?, "valor é limitado ao máximo antes de validar"
    assert_equal 5, item.teacher_points
  end

  test "rejeita arquivo maior que o limite" do
    batch = Batch.create!(name: "T", activity: activity)
    submission = batch.submissions.new(files: [ { io: StringIO.new("%PDF-1.4"), filename: "grande.pdf", content_type: "application/pdf" } ])
    submission.files.first.blob.byte_size = Submission::MAX_FILE_SIZE + 1
    assert_not submission.valid?
    assert_match "25 MB", submission.errors[:files].to_sentence
  end
end
