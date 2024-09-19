class Admin::SettingsController < Admin::BaseController
  def index
  end

  def update
    @setting = Setting.find(params[:id])
    @setting.update!(settings_params)

    respond_to do |format|
      format.html { redirect_to request_referer, notice: t("admin.settings.flash.updated") }
      format.js
    end
  end

  def update_map
    Setting["map.latitude"] = params[:latitude].to_f
    Setting["map.longitude"] = params[:longitude].to_f
    Setting["map.zoom"] = params[:zoom].to_i
    redirect_to request_referer, notice: t("admin.settings.index.map.flash.update")
  end

  def update_content_types
    setting = Setting.find(params[:id])
    group = setting.content_type_group
    mime_type_values = content_type_params.keys.map do |content_type|
      Setting.mime_types[group][content_type]
    end
    setting.update! value: mime_type_values.join(" ")
    redirect_to request_referer, notice: t("admin.settings.flash.updated")
  end

  private

    def settings_params
      params.require(:setting).permit(allowed_params)
    end

    def allowed_params
      [:value]
    end

    def content_type_params
      params.permit(:jpg, :png, :gif, :pdf, :doc, :docx, :xls, :xlsx, :csv, :zip)
    end

    def request_referer
      request.referer + params[:tab].to_s
    end
end
