require "test_helper"

class FlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup { sign_in_teacher }

  test "cria turma, envia prova, vê correção, ajusta nota e exporta CSV" do
    activity
    post batches_path, params: { batch: { name: "2B", activity_id: activity.id } }
    batch = Batch.last
    assert_redirected_to batch

    get batch_path(batch)
    assert_response :success
    assert_select "#dropzone_batch_#{batch.id}[data-turbo-permanent]"
    assert_select ".cw-seg button[data-concept]", 5, "filtro: Todos, MB, B, R, NS"

    file = fixture_file_upload(ANSWERED_PDF, "application/pdf")
    assert_enqueued_with(job: GradeSubmissionJob) do
      post batch_submissions_path(batch), params: { files: [ file ] }, as: :multipart_form
    end
    assert_response :created
    submission = batch.submissions.last

    with_fake_openai { perform_enqueued_jobs(only: GradeSubmissionJob) }
    get submission_path(submission)
    assert_response :success
    assert_select "#submission_summary", /36,5/
    assert_select "mark.issue", minimum: 1

    get batch_path(batch)
    assert_select "#submission_#{submission.id}[data-concept=NS]"
    assert_select ".cw-extreme a[href='#{submission_path(submission)}']", minimum: 1

    item = submission.items.find_by!(key: "strongest")
    patch submission_item_path(submission, item), params: { submission_item: { teacher_points: "25,5" } }, as: :turbo_stream
    assert_response :success
    assert_equal 62, submission.reload.total_score
    assert_equal "R", submission.concept

    get batch_path(batch, format: :csv)
    assert_response :success
    assert_includes response.body, "62;R"
  end

  test "rejeita upload de formato inválido" do
    batch = Batch.create!(name: "T", activity: activity)
    post batch_submissions_path(batch), params: { files: [ Rack::Test::UploadedFile.new(StringIO.new("x"), "text/plain", original_filename: "a.txt") ] }
    assert_response :unprocessable_entity
  end

  test "recorrigir é ignorado enquanto a prova está em processamento" do
    submission = create_submission
    submission.update!(status: "grading")
    assert_no_enqueued_jobs(only: GradeSubmissionJob) do
      post regrade_submission_path(submission)
    end
    assert_equal "grading", submission.reload.status
  end

  test "nota igual à da IA depois de arredondar não marca ajuste" do
    submission = create_submission
    with_fake_openai { GradeSubmissionJob.perform_now(submission) }
    item = submission.items.find_by!(key: "interpersonal") # IA: 4,5
    patch submission_item_path(submission, item), params: { submission_item: { teacher_points: "4,4" } }, as: :turbo_stream
    assert_nil item.reload.teacher_points
  end

  test "prova excluída antes do job não gera erro nem chamada à IA" do
    submission = create_submission
    Submission.find(submission.id).destroy
    assert_nothing_raised { with_fake_openai { GradeSubmissionJob.perform_now(submission) } }
  end

  test "várias fotos enviadas juntas viram um único aluno" do
    batch = Batch.create!(name: "T", activity: activity)
    Dir.mktmpdir do |dir|
      front = fixture_file_upload(photo_of(ANSWERED_PDF, 1, dir), "image/jpeg")
      back = fixture_file_upload(photo_of(ANSWERED_PDF, 2, dir), "image/jpeg")
      assert_difference -> { batch.submissions.count }, 1 do
        post batch_submissions_path(batch), params: { files: [ front, back ] }, as: :multipart_form
      end
    end
    assert_response :created
    submission = batch.submissions.last
    assert_equal 2, submission.files.count
    assert_equal "foto1-1.jpg, foto2-2.jpg", submission.original_filename

    with_fake_openai { perform_enqueued_jobs(only: GradeSubmissionJob) }
    assert_equal 2, submission.reload.pages.count
    assert_equal "done", submission.status
  end
end
