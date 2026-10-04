class ApplicationController < ActionController::Base
  include Pagy::Method
  include OwnerBarCookie

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_internal_staff
  before_action :refresh_owner_bar_cookie

  # Devise: Redirect to admin/sites after sign in
  def after_sign_in_path_for(resource)
    set_owner_bar_cookie(resource) if resource.is_a?(Account)
    "/admin/sites"
  end

  def after_sign_out_path_for(_resource_or_scope)
    clear_owner_bar_cookie
    root_path
  end

  def configure_permitted_parameters
    #devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:email, :password, :password_confirmation, :firstname, :middlename, :lastname, :nickname) }
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :email, :password, :password_confirmation])
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation])
  end
  
  def self.get_max_site_size_for_account_in_mb(current_account)
    plan = current_account.respond_to?(:current_plan) ? current_account.current_plan : Plan.for_handle(current_account.plan_handle)
    plan.max_site_size.to_i
  end

  def self.get_max_site_size_for_account_in_bytes(current_account)
    get_max_site_size_for_account_in_mb(current_account) * 1_048_576
  end
  
  def authenticate_internal_staff
    return unless request.path.start_with?("/internal")

    # Reload so console/admin toggles apply without requiring a re-login.
    account = current_account
    account&.reload

    return if account&.admin?

    redirect_to root_path, alert: "You do not have access to this page."
  end
end
