class BatchesController < ApplicationController
  before_action :set_batch, only: %i[show update destroy]

  def index
    @batches = Batch.includes(:activity, :submissions).order(updated_at: :desc)
    @batch = Batch.new(activity: Activity.first, name: default_name)
  end

  def show
    @submissions = @batch.submissions.includes(:items)
    respond_to do |format|
      format.html
      format.csv { send_data @batch.to_csv, filename: "#{@batch.name.parameterize}-notas.csv", type: "text/csv; charset=utf-8" }
    end
  end

  def create
    @batch = Batch.new(batch_params)
    @batch.activity ||= Activity.first
    if @batch.save
      redirect_to @batch
    else
      @batches = Batch.includes(:activity, :submissions).order(updated_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if @batch.update(batch_params)
      redirect_to @batch, notice: "Turma renomeada."
    else
      redirect_to @batch, alert: @batch.errors.full_messages.to_sentence
    end
  end

  def destroy
    @batch.destroy
    redirect_to root_path, notice: "Turma excluída.", status: :see_other
  end

  private

  def set_batch
    @batch = Batch.find(params[:id])
  end

  def batch_params
    params.expect(batch: %i[name activity_id])
  end

  def default_name
    "Turma – #{I18n.l(Date.current, format: '%d/%m/%Y')}"
  end
end
