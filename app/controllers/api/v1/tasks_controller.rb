# app/controllers/api/v1/tasks_controller.rb
module Api
  module V1
    class TasksController < ApplicationController

      # Before updating or deleting a task, find the task and ensure the current user owns the task
      before_action :find_task, only: [:update, :destroy, :task_comments]
      before_action :authorize_task_owner!, only: [:destroy]

      # POST /tasks
      def create
        assigned_user = User.find_by(id: params[:assigned_user_id]) # Find the user assigned to the task and the project the task belongs to
        project = Project.find_by(id: params[:project_id])

        if assigned_user.nil? # Handle the case where the assigned user is not found
          render json: { error: 'Assigned user not found' }, status: :not_found
          return
        end

        raise ProjectNotFoundError.new if project.nil? # Raise a custom error if the project is not found (using ProjectNotFoundError)

        # Create the new task with the provided parameters, current user, assigned user, and project
        @task = Task.new(task_params.merge(user_id: current_user.id, assigned_user_id: assigned_user.id, project_id: project.id))
        @task.save!
        LogActionService.log_action(@task.id, current_user.id, :create, 'Task')
        render json: { message: 'Task created successfully', task: @task }, status: :created # Return a success response with the created task details 
      end

      # PUT /tasks/:id  Updates an existing task with the provided parameters
      def update
        assigned_user = User.find_by(id: params[:assigned_user_id]) # Find the assigned user by ID
        project = Project.find_by(id: params[:project_id])

        if assigned_user.nil?
          render json: { error: 'Assigned user not found' }, status: :not_found
          return
        end

        raise ProjectNotFoundError.new if project.nil?

        @task.update!(task_params.merge(assigned_user_id: assigned_user.id,project_id: project.id)) # Update the task with new parameters, including the new assigned user
        LogActionService.log_action(@task.id, current_user.id, :update, 'Task')
        render json: { message: 'Task updated successfully', task: @task }, status: :ok
      end

      # DELETE /tasks/:id  Deletes the task if the user is authorized
      def destroy
        @task.destroy! # Destroy the task and return a success message
        LogActionService.log_action(@task.id, current_user.id, :destroy, 'Task')
        render json: { message: 'Task deleted successfully' }, status: :ok
      end

      # GET /tasks  Retrieves all tasks with pagination (10 tasks per page)
      def index
        tasks = Task.order(created_at: :desc).page(params[:page]).per(10) # Order tasks by creation time in descending order
        render json: {tasks: tasks}, status: :ok
      end


      # GET /tasks/:id/comments
      def task_comments
        comments = @task.comments # Retrieves all comments for a specific task
        render json: { comments: comments }, status: :ok
      end

      private

      # Finds a task by ID before performing actions like update, delete, or show comments
      def find_task
        @task = Task.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        raise TaskNotFoundError.new # Custom error handling if the task is not found
      end

      # Ensures that only the task owner (the user who created it) can update or delete it
      def authorize_task_owner!
        if @task.user_id != current_user.id
          render json: { error: 'You are not authorized to perform this action' }, status: :forbidden # Return a forbidden error if the current user is not authorized
        end
      end

      # Strong parameters for task creation to ensure only permitted attributes are allowed
      def task_params
        params.require(:task).permit(:task_title, :description, :assign_date, :due_date, :status, :priority)
      end
    end
  end
end


