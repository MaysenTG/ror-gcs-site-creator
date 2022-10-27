class SitesController < ApplicationController
  before_action :set_view_path
  
  def index
  end
  
  def new
  end
  
  def show
  end
  
  def show_file
  end
  
  private
  def set_view_path
    #render layout 'index'
    
    render 'index'
  end
  
end
