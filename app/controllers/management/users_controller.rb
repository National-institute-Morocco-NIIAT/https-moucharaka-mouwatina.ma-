class Management::UsersController < Management::BaseController
  def new
    @user = User.new(user_params.merge(verified_at: Time.current))
  end

  def create
    @user = User.new(user_params)

    if @user.email.blank?
      user_without_email
    else
      user_with_email
    end

    @user.terms_of_service = "1"
    # @user.residence_verified_at = Time.current
    # @user.verified_at = Time.current
    @user.id_card_verification_status = "Pending"

    if @user.save
      render :show
    else
      render :new
    end
  end

  def update_verification
    user = User.find(params[:id])
    update_id_verification(user)

    redirect_to users_path, notice: 'User verification status updated successfully.'
  end

  def erase
    if current_manager.present?
      managed_user.erase(t("management.users.erased_by_manager", manager: current_manager["login"]))
    end

    destroy_session
    redirect_to management_document_verifications_path, notice: t("management.users.erased_notice")
  end

  def logout
    destroy_session
    redirect_to management_root_path, notice: t("management.sessions.signed_out_managed_user")
  end

  private

    def user_params
      params.require(:user).permit(allowed_params)
    end

    def allowed_params
      [:document_type, :document_number, :username, :email, :date_of_birth, :id_card_verification_status]
    end

    def destroy_session
      session[:document_type] = nil
      session[:document_number] = nil
      clear_password
    end

    def user_without_email
      new_password = "aAbcdeEfghiJkmnpqrstuUvwxyz23456789$!".chars.sample(10).join
      @user.password = new_password
      @user.password_confirmation = new_password

      @user.email = nil
      @user.confirmed_at = Time.current
      @user.id_card_verification_status = "pending"

      @user.newsletter = false
      @user.email_digest = false
      @user.email_on_direct_message = false
      @user.email_on_comment = false
      @user.email_on_comment_reply = false
    end

    def user_with_email
      @user.skip_password_validation = true
    end
end
