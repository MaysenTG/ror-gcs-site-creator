class Internal::AccountsController < ApplicationController
  before_action :authenticate_internal_staff
  
  def index
    @accounts = Account.all
  end

  def show
    begin
      @account = Account.find(params[:id])
      @plans = Plan.all
    rescue ActiveRecord::RecordNotFound
      redirect_to internal_accounts_path, notice: "Account not found."
    end
  end

  def update
    new_plan_handle = params[:plan_handle]
    account_id = params[:account_id]
    
    account = Account.find(account_id)
    account.plan_handle = new_plan_handle
    account.save!
    
    redirect_to internal_path(account_id), notice: "Plan successfully updated."
  end
  
  def new
  end
  
  def create
    account = Account.new
    account.name = params[:name]
    account.email = params[:email]
    account.password = params[:password]
    account.password_confirmation = params[:password]
    account.plan_handle = params[:plan_handle]
    account.save!
    
    redirect_to internal_path(account.id), notice: "Account successfully created."
  end
  
  def destroy
    account = Account.find(params[:id])
    account.destroy
    
    redirect_to internal_accounts_path, notice: "Account successfully deleted."
  end
  
  private
  def authenticate_internal_staff
    # Account must have the email of "greenwood.maysen@gmail.com" to access
    # the internal dashboard
    if !current_account.admin
      redirect_to root_path, notice: "You do not have access to this page."
    end
  end
end
