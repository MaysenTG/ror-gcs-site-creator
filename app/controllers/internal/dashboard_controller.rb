class Internal::DashboardController < ApplicationController
  def show
    @stats = Internal::OpsStats.build
  end
end
