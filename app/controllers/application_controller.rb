class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  # Devise: Redirect to admin/sites after sign in
  def after_sign_in_path_for(resource)
    "/admin/sites"
  end

   

  def configure_permitted_parameters
    #devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:email, :password, :password_confirmation, :firstname, :middlename, :lastname, :nickname) }
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :email, :password, :password_confirmation])
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation])
  end
end
