class CourseSubject < ApplicationRecord
  # Associations
  belongs_to :course
  belongs_to :subject, -> {with_deleted}
  has_many :tasks, as: :taskable, dependent: :destroy
  has_many :user_subjects, dependent: :destroy

  accepts_nested_attributes_for :tasks, allow_destroy: true,
reject_if: :all_blank

  # Position management with acts_as_list
  acts_as_list scope: :course

  # Validations
  validates :course_id, uniqueness: {scope: :subject_id}
  validate :finish_date_after_start_date

  # Scopes
  scope :ordered_by_position, -> {order(:position)}
  scope :by_course, ->(course) {where(course:)}
  scope :by_subject, ->(subject) {where(subject:)}
  scope :with_deleted, -> {all}

  private

  def finish_date_after_start_date
    return unless start_date && finish_date

    return unless finish_date < start_date

    errors.add(:finish_date,
               :finish_date_after_start_date)
  end
end
