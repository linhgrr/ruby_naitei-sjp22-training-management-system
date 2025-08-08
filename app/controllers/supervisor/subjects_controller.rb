class Supervisor::SubjectsController < Supervisor::BaseController
  before_action :load_subject, only: %i(show edit update destroy)

  # GET /supervisor/subjects
  def index
    @pagy, @subjects = pagy Subject.includes(:tasks)
                                   .search_by_name(params[:search]),
                            items: Settings.ui.items_per_page
  end

  # GET /supervisor/subjects/:id
  def show; end

  # GET /supervisor/subjects/new
  def new
    @subject = Subject.new
  end

  # POST /supervisor/subjects
  def create
    @subject = Subject.new(subject_params)

    if @subject.save
      flash[:success] = t(".subject_created")
      redirect_to supervisor_subjects_path
    else
      flash[:danger] = t(".create_failed")
      render :new, status: :unprocessable_entity
    end
  end

  # GET /supervisor/subjects/:id/edit
  def edit; end

  # PATCH /supervisor/subjects/:id
  def update
    if @subject.update(subject_params)
      flash[:success] = t(".subject_updated")
      redirect_to supervisor_subject_path(@subject)
    else
      flash[:danger] = t(".update_failed")
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /supervisor/subjects/:id
  def destroy
    if @subject.destroy
      flash[:success] = t(".subject_deleted")
    else
      flash[:danger] = t(".delete_failed")
    end
    redirect_to supervisor_subjects_path
  end

  private

  def load_subject
    @subject = Subject.find_by id: params[:id]
    return if @subject

    flash[:danger] = t("not_found_subject")
    redirect_to supervisor_subjects_path
  end

  def subject_params
    params.require(:subject).permit(:name, :estimated_time_days, :description)
  end
end
