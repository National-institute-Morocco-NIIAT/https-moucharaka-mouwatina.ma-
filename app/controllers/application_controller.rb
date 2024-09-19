class ApplicationController < ActionController::Base
  include TenantVariants
  include GlobalizeFallbacks
  include HasFilters
  include HasOrders
  include AccessDeniedHandler

  default_form_builder ConsulFormBuilder

  before_action :authenticate_http_basic, if: :http_basic_auth_site?

  before_action :ensure_signup_complete
  around_action :switch_locale
  before_action :set_return_url

  check_authorization unless: :devise_controller?
  self.responder = ApplicationResponder

  layout :set_layout
  respond_to :html
  helper_method :current_budget

  private

    def authenticate_http_basic
      authenticate_or_request_with_http_basic do |username, password|
        username == Tenant.current_secrets.http_basic_username &&
          password == Tenant.current_secrets.http_basic_password
      end
    end

    def http_basic_auth_site?
      Tenant.current_secrets.http_basic_auth
    end

    def verify_lock
      if current_user.locked?
        redirect_to account_path, alert: t("verification.alert.lock")
      end
    end

    def switch_locale(&action)
      locale = current_locale

      if current_user && current_user.locale != locale.to_s
        current_user.update(locale: locale)
      end

      session[:locale] = locale.to_s
      I18n.with_locale(locale, &action)
    end

    def current_locale
      if Setting.enabled_locales.include?(params[:locale]&.to_sym)
        params[:locale]
      elsif Setting.enabled_locales.include?(session[:locale]&.to_sym)
        session[:locale]
      else
        Setting.default_locale
      end
    end

    def set_layout
      if devise_controller?
        "devise"
      else
        "application"
      end
    end

    def set_comment_flags(comments)
      @comment_flags = current_user ? current_user.comment_flags(comments) : {}
    end

    def ensure_signup_complete
      if user_signed_in? && !devise_controller? && current_user.registering_with_oauth
        redirect_to finish_signup_path
      end
    end

    def verify_resident!
      unless current_user.residence_verified?
        redirect_to new_residence_path, alert: t("verification.residence.alert.unconfirmed_residency")
      end
    end

    def verify_verified!
      if current_user.level_three_verified?
        redirect_to(account_path, notice: t("verification.redirect_notices.already_verified"))
      end
    end

    def set_return_url
      if request.get? && !devise_controller? && is_navigational_format?
        store_location_for(:user, request.fullpath)
      end
    end

    def current_budget
      Budget.current
    end

    def redirect_with_query_params_to(options, response_status = {})
      path_options = { controller: params[:controller] }.merge(options).merge(only_path: true)
      path = url_for(request.query_parameters.merge(path_options))

      redirect_to path, response_status
    end
end
