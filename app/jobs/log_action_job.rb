class LogActionJob < ApplicationJob
  queue_as :default

  def perform(record_id, current_user_id, action_type, model_type)
    record = find_record(record_id, model_type)  # Dynamically find the model (Project,Comment and task)
    return unless record  # Return if the record is not found
    record.store_log_message(current_user_id, action_type) # Call the model's method to store the log message for create/update/destroy
  end

  private

  def find_record(record_id, model_type)
    model = model_type.constantize  # Convert the model type from string to constant (e.g., 'Task' -> Task model).
    # Check if the model has a 'deleted_at' column (indicating soft delete support).
    # If it does, find the record including soft-deleted ones.
    return model.unscope(where: :deleted_at).find_by(id: record_id) if model.column_names.include?('deleted_at')
    model.find_by(id: record_id) # If the model does not support soft deletion, find the record normally.
  end  
end
