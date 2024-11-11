class Project < ApplicationRecord
  include Loggable

  # Associations
  has_and_belongs_to_many :users #Project Can have many users many-to-many relation
  has_many :tasks, dependent: :destroy # Deletes associated tasks if the project is deleted one-to-many relation

  # Validations
  validates :name, presence: true, uniqueness: true # Name must be present and unique
  validates :description, presence: true, length: { minimum: 10 }  # Description must be present and at least 100 characters
  validates :status, presence: true, inclusion: { in: %w[active completed], message: "%{value} is not a valid status" }  # Valid status values
  validates :start_date, presence: true  #Start Date
  validates :end_date, presence: true, comparison: { greater_than: :start_date } #End Date should be greater than Start Date

  # Exclude soft-deleted tasks by default
  default_scope { where(deleted_at: nil) }

  # Soft delete method - sets the deleted_at timestamp to mark as deleted
  def mark_as_deleted
    update(deleted_at: Time.current)
  end

  # Check if the record is soft-deleted
  def soft_deleted?
    deleted_at.present?
  end

  # Override destroy method to perform soft delete instead of hard delete
  def destroy
    mark_as_deleted
  end

  def restore
    update(deleted_at: nil)
  end
end
