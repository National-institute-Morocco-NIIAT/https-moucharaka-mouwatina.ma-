class Organizations::RegistrationsController < Devise::RegistrationsController
  invisible_captcha only: [:create], honeypot: :address, scope: :user

  def new
    super(&:build_organization)
  end

  def success
  end

  def create
    build_resource(sign_up_params)
    if resource.valid?
      super do |user|
        # Removes unuseful "organization is invalid" error message
        user.errors.delete(:organization)
      end
    else
      render :new
    end
  end

  protected

    def after_inactive_sign_up_path_for(resource)
      organizations_sign_up_success_path
    end

  private

    def sign_up_params
      params.require(:user).permit(allowed_params)
    end

    def allowed_params
      [
        :email, :password, :phone_number, :password_confirmation, :terms_of_service,
        organization_attributes: [:name, :responsible_name]
      ]
    end
end
