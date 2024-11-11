class ApplicationController < ActionController::API

  include ErrorHandler  #Managing centrallized errorhandling throughout the controllers
  include Restoreable   #Restoring deleted data throughout the controllers

  # Before every action, ensure the user is authenticated
  before_action :authenticate_user!

  private

  # Authenticate the user by decoding the JWT token
  def authenticate_user!
    begin
      @current_user = decode_token
    rescue JWT::ExpiredSignature
      # Handle expired token case and inform the user
      render json: { error: 'Token has expired. Please refresh token.' }, status: :unauthorized
    rescue JWT::DecodeError
      # Handle invalid token case and request re-login
      render json: { error: 'Invalid token. Please login again.' }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      # Handle missing user record for the decoded user ID
      render json: { error: 'User not found. Please login again.' }, status: :unauthorized
    end
  end      

  # Get the current authenticated user
  def current_user
    @current_user
  end

  private

  # Private method for decoding JWT tokens
  def decode_token
    # Check if the Authorization header is present in the request
    if request.headers['Authorization'].present?

      # Extract the token from the Authorization header
      token = request.headers['Authorization'].split(' ').last

      # Decode the token using the application's secret key
      decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: 'HS256')
      
      # Get the user_id from the decoded token payload
      user_id = decoded_token[0]['user_id']

       # Find and return the user from the database or raise an error if not found
      User.find_by(id: user_id) || raise(ActiveRecord::RecordNotFound)
    else

      # Raise an error if the token is missing from the request
      raise StandardError.new('Token is missing')
    end
  end
end
