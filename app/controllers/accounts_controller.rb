class AccountsController < ApplicationController
  def get_plans
    # Get all plans except the current plan
    
    @plans = Plan.where.not(plan_handle: [current_account.plan_handle, 'free'])
  end
end
