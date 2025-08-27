class Supervisor::TasksController < Supervisor::BaseController
  before_action :authorize_task_read, only: %i(index show)
  before_action :authorize_task_update, only: %i(new create edit update destroy)
  before_action :load_task, only: %i(destroy show edit update)

  # GET /supervisor/tasks
  def index
    @pagy, @tasks = pagy Task.for_taskable_type(Subject.name)
                             .includes(:taskable)
                             .recent
                             .by_subject(params[:subject_id])
                             .search_by_name(params[:search]),
                         items: Settings.ui.items_per_page
  end

  # DELETE /supervisor/tasks/:id
  def destroy
    if @task.destroy
      flash[:success] = t(".task_deleted")
    else
      flash[:danger] = t(".delete_failed")
    end
    redirect_to supervisor_tasks_path
  end

  # GET /supervisor/tasks/new
  def new
    @task = Task.new
  end

  # POST /supervisor/tasks
  def create
    @task = Task.new task_params

    if @task.save
      flash[:success] = t(".create_success")
      redirect_to supervisor_tasks_path
    else
      flash.now[:danger] = t(".create_fail")
      render :new, status: :unprocessable_entity
    end
  end

  # GET /supervisor/tasks/:id
  def show; end

  # GET /supervisor/tasks/:id/edit
  def edit; end

  # PATCH /supervisor/tasks/:id/
  def update
    if @task.update(task_params)
      flash[:success] = t(".update_success")
      redirect_to supervisor_tasks_path
    else
      flash.now[:danger] = t(".update_fail")
      render :new, status: :unprocessable_entity
    end
  end

  private
  def authorize_task_read
    authorize! :read, Task
  end

  def authorize_task_update
    authorize! :update, Task
  end

  def task_params
    params.require(:task).permit Task::TASK_PERMITTED_PARAMS
  end

  def load_task
    @task = Task.find_by id: params[:id]
    return if @task

    flash[:danger] = t("not_found_task")
    redirect_to supervisor_tasks_path
  end
end
