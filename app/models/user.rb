class User < ApplicationRecord
  has_many :enrollments
  has_many :programs, through: :enrollments
  has_many :teachers, through: :enrollments, source: :teacher

  enum kind: { student: 0, teacher: 1, student_teacher: 2 }

  validates :name, presence: true
  validates :age, numericality: { greater_than_or_equal_to: 0 }

  validate :validate_kind_based_on_enrollments

  def self.classmates(user)
    where.not(id: user.id)
         .joins(enrollments: :program)
         .where(enrollments: { program_id: user.enrollments.pluck(:program_id) })
         .distinct
  end

  def student_favorite_teachers
    teachers.where(enrollments: { favorite: true })
            .where(kind: :teacher)
            .includes(:enrollments)
  end

  private

  def validate_kind_based_on_enrollments
    return unless kind_changed?

    if teacher? && enrollments.exists?
      errors.add(:kind, "can not be teacher because is studying in at least one program")
    elsif student? && Enrollment.where(teacher: self).exists?
      errors.add(:kind, "can not be student because is teaching in at least one program")
    end
  end
end