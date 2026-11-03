class GradeSubmissionJob < ApplicationJob
  queue_as :default

  # Nunca duas correções da mesma prova ao mesmo tempo (Solid Queue).
  limits_concurrency to: 1, key: ->(submission) { submission }, duration: 15.minutes

  # Qualquer erro inesperado marca a prova como "Falhou" (com botão de tentar de novo na tela).
  rescue_from(StandardError) do |error|
    Rails.logger.error("[GradeSubmissionJob] #{error.class}: #{error.message}\n#{error.backtrace&.first(5)&.join("\n")}")
    submission = arguments.first
    submission.fail!(error.message) if Submission.exists?(submission.id)
  end

  # Erros temporários (rede, limite de uso, 5xx) são tentados de novo com espera crescente.
  retry_on AiGrader::TransientError, wait: :polynomially_longer, attempts: 3 do |job, error|
    submission = job.arguments.first
    submission.fail!(error.message) if Submission.exists?(submission.id)
  end

  # Prova excluída antes ou durante a correção: não há o que fazer.
  discard_on ActiveJob::DeserializationError, ActiveRecord::RecordNotFound

  def perform(submission)
    submission.reload.update!(status: "reading", error_message: nil)

    PageExtractor.new(submission.file).call do |extracted|
      ensure_still_exists!(submission)
      attach_pages(submission, extracted.images)
      submission.update!(status: "grading", extracted_text: extracted.text)

      result = AiGrader.new(activity: submission.activity, text: extracted.text, images: extracted.images).call
      ensure_still_exists!(submission)
      submission.apply_result!(result)
    end
  end

  private

  def ensure_still_exists!(submission)
    raise ActiveRecord::RecordNotFound, "Prova #{submission.id} foi excluída" unless Submission.exists?(submission.id)
  end

  def attach_pages(submission, images)
    submission.pages.purge
    images.each_with_index do |path, index|
      submission.pages.attach(io: File.open(path), filename: "pagina-#{index + 1}.jpg", content_type: "image/jpeg")
    end
  end
end
