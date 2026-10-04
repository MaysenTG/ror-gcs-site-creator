class Internal::AccountsController < ApplicationController
  def index
    @pagy, @accounts = pagy(Account.includes(:plan, :sites).order(created_at: :desc))
  end

  def show
    @account = Account.includes(:plan).find(params[:id])
    @pagy, @account_sites = pagy(@account.sites.order(created_at: :desc))
    @plans = Plan.all.sort_by { |plan| plan.max_sites.to_i }
    @traffic = Internal::AccountTrafficStats.build(@account)
  rescue ActiveRecord::RecordNotFound
    redirect_to internal_accounts_path, notice: "Account not found."
  end

  def update
    account = Account.find(params[:id])
    account.update!(plan_handle: params[:plan_handle])
    redirect_to internal_account_path(account), notice: "Plan successfully updated."
  end

  def new
    @plans = Plan.all.sort_by { |plan| plan.max_sites.to_i }
  end

  def create
    account = Account.new(
      name: params[:name],
      email: params[:email],
      password: params[:password],
      password_confirmation: params[:password],
      plan_handle: params[:plan_handle]
    )
    account.save!
    redirect_to internal_account_path(account), notice: "Account successfully created."
  end

  def destroy
    account = Account.find(params[:id])
    account.destroy
    redirect_to internal_accounts_path, notice: "Account successfully deleted."
  end

  def search
    search_term = params[:q].to_s.strip

    scope = Account.includes(:plan, :sites).order(created_at: :desc)
    if search_term.present?
      @query = search_term
      @pagy, @accounts = pagy(
        scope.where(
          "accounts.name ILIKE :search OR accounts.email ILIKE :search OR accounts.plan_handle ILIKE :search",
          search: "%#{search_term}%"
        )
      )
    else
      @query = ""
      @pagy, @accounts = pagy(scope)
    end

    render turbo_stream: turbo_stream.update(
      "accounts_list",
      partial: "internal/accounts/accounts",
      locals: { accounts: @accounts, query: @query }
    )
  end
end
