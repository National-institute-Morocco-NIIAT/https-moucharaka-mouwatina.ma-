class Admin::BannersController < Admin::BaseController
  include Translatable

  has_filters %w[all with_active with_inactive], only: :index

  before_action :banner_sections, only: [:edit, :new, :create, :update]

  respond_to :html, :js

  load_and_authorize_resource

  def index
    @banners = Banner.send(@current_filter).page(params[:page])
  end

  def create
    @banner = Banner.new(banner_params)
    if @banner.save
      redirect_to admin_banners_path, notice: t("admin.banners.create.notice")
    else
      render :new
    end
  end

  def update
    if @banner.update(banner_params)
      redirect_to admin_banners_path, notice: t("admin.banners.update.notice")
    else
      render :edit
    end
  end

  def destroy
    @banner.destroy!
    redirect_to admin_banners_path, notice: t("admin.banners.destroy.notice")
  end

  private

    def banner_params
      params.require(:banner).permit(allowed_params)
    end

    def allowed_params
      [:target_url, :post_started_at, :post_ended_at, :background_color, :font_color,
       translation_params(Banner),
       web_section_ids: []]
    end

    def banner_sections
      @banner_sections = WebSection.all
    end

    def resource
      @banner ||= Banner.find(params[:id])
    end
end
