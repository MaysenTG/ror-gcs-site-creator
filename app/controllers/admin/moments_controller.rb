class Admin::MomentsController < ApplicationController
  before_action :authenticate_account!
  before_action :set_site
  before_action :set_moment, only: %i[show restore]

  def index
    return if performed?

    @moments = @site.site_moments.recent_first.limit(SiteMoment::MAX_PER_SITE)
    respond_to do |format|
      format.html
      format.json do
        render json: {
          moments: @moments.map { |m|
            {
              id: m.id,
              name: m.name,
              note: m.note,
              file_count: m.file_count,
              created_at: m.created_at.iso8601,
              label: m.created_at.strftime("%b %d, %Y %I:%M %p")
            }
          }
        }
      end
    end
  end

  def create
    return if performed?

    moment = SiteMoment.capture!(
      site: @site,
      name: params[:name].presence || "Moment #{Time.current.strftime("%b %d %H:%M")}",
      note: params[:note]
    )
    respond_to do |format|
      format.html { redirect_to admin_moments_path(@site.name), notice: "Saved moment “#{moment.name}”." }
      format.json { render json: { status: "success", id: moment.id, name: moment.name } }
    end
  rescue StandardError => e
    respond_to do |format|
      format.html { redirect_to "/admin/sites/#{@site.name}", alert: e.message }
      format.json { render json: { status: "error", error: e.message }, status: :unprocessable_entity }
    end
  end

  def show
    return if performed?

    @diff = @moment.diff_against_live
    respond_to do |format|
      format.html
      format.json { render json: { moment: serialize_moment(@moment), diff: @diff } }
    end
  end

  def restore
    return if performed?

    @moment.restore!
    respond_to do |format|
      format.html { redirect_to "/admin/sites/#{@site.name}", notice: "Restored moment “#{@moment.name}”." }
      format.json { render json: { status: "success" } }
    end
  rescue StandardError => e
    respond_to do |format|
      format.html { redirect_to admin_moment_path(@site.name, @moment), alert: e.message }
      format.json { render json: { status: "error", error: e.message }, status: :unprocessable_entity }
    end
  end

  private

  def set_site
    @site = current_account.sites.find_by(name: params[:site_name].to_s.downcase.strip)
    return if @site

    redirect_to "/admin/sites", notice: "Site not found."
  end

  def set_moment
    return if performed? || @site.nil?

    @moment = @site.site_moments.find_by(id: params[:id])
    return if @moment

    redirect_to admin_moments_path(@site.name), notice: "Moment not found."
  end

  def serialize_moment(moment)
    {
      id: moment.id,
      name: moment.name,
      note: moment.note,
      file_count: moment.file_count,
      created_at: moment.created_at.iso8601
    }
  end
end
