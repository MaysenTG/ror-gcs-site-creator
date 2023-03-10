class Internal::AccountsController < ApplicationController  
  def index
    #@accounts = Account.all
    @pagy, @accounts = pagy(Account.all)
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
  
  def search
    search_term = params[:q]
    
    
    if search_term.present?
      @pagy, @accounts = pagy(Account.where("name LIKE :search or email LIKE :search or plan_handle LIKE :search", search: "%#{search_term}%"))
      @query = search_term
    else
      @query = ""
      @pagy, @accounts = pagy(Account.all)
    end
    render turbo_stream: turbo_stream.update("accounts_list", partial: "internal/accounts/accounts", locals: { accounts: @accounts, query: @query })
  end
end
