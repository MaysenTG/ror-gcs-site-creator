class Admin::DomainsController < ApplicationController
  before_action :set_domain, only: %i[ show edit update destroy ]
  before_action :authenticate_account!
  before_action :check_site_owner

  # GET /domains or /domains.json
  def index
    # Used for pointing the custom domain to the NGINX server
    @a_record_ip = "170.64.162.111"
    
    @site = Site.find_by(name: params[:site_name])
    @domains = @site.domains
  end

  # GET /domains/1 or /domains/1.json
  def show
    @site = Site.find_by(name: params[:site_name])
  end

  # GET /domains/new
  def new
    @domain = Domain.new
    @site_name = params[:site_name]
  end

  # GET /domains/1/edit
  def edit
    @site = Site.find_by(name: params[:site_name])
  end

  # POST /domains or /domains.json
  def create
    @domain = Domain.new(domain_params)
    @site = Site.find_by(name: params[:site_name])
    @domain.site_id = @site.id

    respond_to do |format|
      if @domain.save
        format.html { redirect_to admin_domains_url, notice: "Domain was successfully created." }
        format.json { render :show, status: :created, location: @domain }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @domain.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /domains/1 or /domains/1.json
  def update
    @site = Site.find_by(name: params[:site_name])
    
    respond_to do |format|
      if @domain.update(domain_params)
        format.html { redirect_to admin_domain_url(@site.name, @domain), notice: "Domain was successfully updated." }
        format.json { render :show, status: :ok, location: @domain }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @domain.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /domains/1 or /domains/1.json
  def destroy
    @domain.destroy

    respond_to do |format|
      format.html { redirect_to admin_domains_url, notice: "Domain was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_domain
      @domain = Domain.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def domain_params
      params.require(:domain).permit(:domain, :site_name)
    end
    
    def check_site_owner
      @site = Site.find_by(name: params[:site_name])
      if @site.account_id != current_account.id
        redirect_to root_path
      end
    end
end
