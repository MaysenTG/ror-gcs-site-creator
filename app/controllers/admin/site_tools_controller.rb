class Admin::SiteToolsController < ApplicationController
  before_action :authenticate_account!
  before_action :set_site

  def ship_check
    return if performed?

    result = ShipCheck.new(site: @site).run
    render json: result
  end

  def apply_theme
    return if performed?

    theme = params[:theme].presence || "blank"
    ThemeRemix.new(site: @site).apply_theme!(theme)
    redirect_to "/admin/sites/#{@site.name}?filename=index.html",
                notice: "Starter files replaced with the #{theme.tr('_', ' ')} theme."
  rescue ArgumentError, SiteStorage::NotFoundError => e
    redirect_to "/admin/sites/#{@site.name}", alert: e.message
  end

  def apply_palette
    return if performed?

    palette_id = params[:palette].to_s
    label = ThemeRemix::PALETTES.dig(palette_id, :label) || palette_id
    ThemeRemix.new(site: @site).apply_palette!(palette_id)
    redirect_to "/admin/sites/#{@site.name}?filename=style.css",
                notice: "Applied #{label} colors/fonts to style.css."
  rescue ArgumentError, ActiveRecord::RecordNotFound => e
    redirect_to "/admin/sites/#{@site.name}", alert: e.message
  end

  private

  def set_site
    @site = current_account.sites.find_by(name: params[:site_name].to_s.downcase.strip)
    return if @site

    respond_to do |format|
      format.html { redirect_to "/admin/sites", notice: "Site not found." }
      format.json { render json: { error: "Site not found" }, status: :not_found }
    end
  end
end
