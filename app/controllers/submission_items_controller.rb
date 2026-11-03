class SubmissionItemsController < ApplicationController
  def update
    submission = Submission.find(params[:submission_id])
    @item = submission.items.find(params[:id])
    points = params.dig(:submission_item, :teacher_points)
    value = points.blank? || params[:reset] ? nil : Grading.normalize_points(points.to_s.tr(",", "."), @item.max_points)
    value = nil if value && value == @item.ai_points # igual à nota da IA = sem ajuste

    if @item.update(teacher_points: value)
      render turbo_stream: [
        turbo_stream.replace(@item, partial: "submission_items/item", locals: { item: @item }),
        turbo_stream.replace("submission_header", partial: "submissions/header", locals: { submission: submission.reload }),
        turbo_stream.replace("submission_summary", partial: "submissions/summary", locals: { submission: submission })
      ]
    else
      render turbo_stream: turbo_stream.replace(@item, partial: "submission_items/item", locals: { item: @item.reload }),
             status: :unprocessable_entity
    end
  end
end
