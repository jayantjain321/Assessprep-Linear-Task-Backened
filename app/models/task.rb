class Task < ApplicationRecord
  include Loggable

  #Associations
  belongs_to :user  #Each task belongs to a user many-to-one Relation
  has_many :comments, dependent: :destroy #If a task deleted, commeent will be deleted too one-to-many relation
  belongs_to :project #Many-to-One Relation 
  
  #Validations
  validates :task_title, presence: true, uniqueness: true, length: { maximum: 255 }  # Name task_title be present and unique
  validates :description, presence: true, length: { maximum: 1000 }  # Description must be present and at least 1000 characters
  validates :assign_date, presence: true #Ensure assignment date is present
  validates :due_date, presence: true, comparison: { greater_than: :assign_date } # Ensure due date is present
  validates :status, presence: true, inclusion: { in: %w[Todo Done InProgress InDevReview] } # Valid status values
  validates :priority, presence: true, inclusion: { in: %w[Urgent High Low] } # Valid priority values

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
end

