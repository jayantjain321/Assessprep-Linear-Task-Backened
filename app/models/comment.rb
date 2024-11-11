class Comment < ApplicationRecord
  include Loggable

  # Associations
  belongs_to :task  #Each comment belongs to a task many-to-one relation
  belongs_to :user  #Each comment belongs to a user many-to-ont relation

  # Validations
  validates :text, presence: true 

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
