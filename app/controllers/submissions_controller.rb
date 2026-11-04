class SubmissionsController < ApplicationController
  before_action :set_submission, except: :create

  # Um envio = um aluno: todos os arquivos (frente, verso, várias fotos ou PDFs) viram uma única prova.
  def create
    batch = Batch.find(params[:batch_id])
    uploads = Array(params.expect(files: []))
    submission = batch.submissions.new(files: uploads, original_filename: Submission.describe_files(uploads))

    if submission.save
      submission.start!
      render json: { id: submission.id, url: submission_path(submission) }, status: :created
    else
      render json: { error: submission.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def show
    @batch = @submission.batch
    @activity = @batch.activity
    @previous_id, @next_id = @submission.neighbors
  end

  def update
    @submission.update(params.expect(submission: [ :student_name ]))
    # Sem replace do cabeçalho: o campo do nome está com foco e seria recriado no meio da digitação.
    respond_to do |format|
      format.turbo_stream { head :no_content }
      format.html { redirect_to @submission }
    end
  end

  def regrade
    # Ignora cliques repetidos enquanto a prova já está sendo corrigida.
    unless @submission.processing?
      @submission.items.destroy_all
      @submission.update!(total_score: nil, concept: nil)
      @submission.start!
    end
    respond_to do |format|
      format.turbo_stream { head :ok }
      format.html { redirect_back_or_to @submission }
    end
  end

  def destroy
    batch = @submission.batch
    @submission.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@submission) }
      format.html { redirect_to batch, notice: "Prova removida.", status: :see_other }
    end
  end

  private

  def set_submission
    @submission = Submission.find(params[:id])
  end
end
