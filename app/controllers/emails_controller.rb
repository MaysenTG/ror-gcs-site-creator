class EmailsController < ApplicationController
  before_action :set_view_path
  
  def index
  end
  
  def new
  end
  
  private
  def set_view_path
    render 'index'
  end
end
