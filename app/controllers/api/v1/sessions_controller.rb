# app/controllers/api/v1/sessions_controller.rb
module Api
  module V1
    class SessionsController < ApplicationController

      # Skip authentication for session creation (login) and token refresh actions
      skip_before_action :authenticate_user!, only: [:create, :refresh_token]

      # POST /login
      # Handles user login by generating access and refresh tokens
      def create
        user = User.find_by(email: params[:email])   #Verify the passed email
        if user && user.authenticate(params[:password])  #Verifying wheather the user and password is matching or not

          # Generate access and refresh tokens with expiration times
          access_token = encode_token({ user_id: user.id, exp: 24.hours.from_now.to_i })
          refresh_token = encode_token({ user_id: user.id, exp: 48.hours.from_now.to_i })

          # Return tokens and user information in the response
          render json: { 
            access_token: access_token, 
            refresh_token: refresh_token, 
            user: user.as_json(only: [:id, :name, :email, :position]) 
          }, status: :ok
        else

          # Return error if credentials are invalid
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      # POST /refresh_token
      # Refreshes the access token if the provided refresh token is valid
      def refresh_token
        if request.headers['Authorization'].present?
          refresh_token = request.headers['Authorization'].split(' ').last # Extract the refresh token from the Authorization header

          begin
            
            # Decode the refresh token to retrieve the user ID
            decoded_token = JWT.decode(refresh_token, Rails.application.credentials.secret_key_base, true, algorithm: 'HS256')
            user_id = decoded_token[0]['user_id']
            user = User.find_by(id: user_id)
      
            if user
              new_access_token = encode_token({ user_id: user.id, exp: 24.hours.from_now.to_i }) #Here it is generating the new access token
              render json: { access_token: new_access_token }, status: :ok
            else
              render json: { error: 'User not found' }, status: :unauthorized # Return error if user not found
            end
      
          rescue JWT::ExpiredSignature
            render json: { error: 'Refresh token has expired. Please login again.' }, status: :unauthorized # Handle expired refresh token
          rescue JWT::DecodeError
            render json: { error: 'Invalid refresh token. Please login again.' }, status: :unauthorized  # Handle invalid token
          end
        else
          render json: { error: 'Refresh token is missing' }, status: :unauthorized
        end
      end

      # /logout
      def logout
        # The logout process is primarily handled on the client side.
        # Inform the client to remove JWT tokens from storage.
        render json: { message: 'Logged out successfully' }, status: :ok
      end
    
      private

      # Method to encode JWT tokens with a secret key and HS256 algorithm
      def encode_token(payload)
        secret_key = Rails.application.credentials.secret_key_base
        JWT.encode(payload, secret_key, 'HS256')
      end
    end   
  end
end

