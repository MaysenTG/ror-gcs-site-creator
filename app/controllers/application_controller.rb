class ApplicationController < ActionController::Base
  include Pagy::Backend
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_internal_staff
  # Before action authenticate account if the request contains internal
  
  
  # Devise: Redirect to admin/sites after sign in
  def after_sign_in_path_for(resource)
    "/admin/sites"
  end

  def configure_permitted_parameters
    #devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:email, :password, :password_confirmation, :firstname, :middlename, :lastname, :nickname) }
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :email, :password, :password_confirmation])
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation])
  end
  
  def self.get_max_site_size_for_account_in_mb(current_account)
    # max_site_size is in MB, so convert to bytes
    Plan.where(plan_handle: current_account.plan_handle).first.max_site_size.to_i
  end
  
  def self.get_max_site_size_for_account_in_bytes(current_account)
    # max_site_size is in MB, so convert to bytes
    Plan.where(plan_handle: current_account.plan_handle).first.max_site_size.to_i * 1048576
  end
  
  def authenticate_internal_staff
    if request.path.include? "internal"
      if current_account
        if current_account.admin == false
          redirect_to root_path, notice: "You do not have access to this page."
        end
      else
        redirect_to root_path, notice: "You do not have access to this page."
      end
    end
  end
end
