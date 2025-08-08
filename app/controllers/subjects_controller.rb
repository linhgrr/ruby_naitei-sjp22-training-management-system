class SubjectsController < ApplicationController
  # GET /subjects.json
  def index
    @subjects = Subject.includes(:tasks)
                       .where.not(id: excluded_subject_ids)
                       .search_by_name(params[:query])
                       .ordered_by_name
                       .limit(Settings.ui_limits.subject_search_limit || 10)

    respond_to do |format|
      format.json do
        formatted_subjects = @subjects.map do |subject|
          {
            id: subject.id,
            name: subject.name,
            estimated_time_days: subject.estimated_time_days,
            max_score: subject.max_score,
            tasks: subject.tasks.map do |task|
              {
                id: task.id,
                name: task.name
              }
            end,
            task_names: subject.tasks.pluck(:name)
          }
        end

        render json: formatted_subjects
      end
    end
  end

  private

  def excluded_subject_ids
    return [] if params[:course_id].blank?

    Course.find(params[:course_id]).subjects.pluck(:id)
  rescue ActiveRecord::RecordNotFound
    []
  end
end
