class Admin::UsersController < Admin::BaseController
  load_and_authorize_resource

  has_filters %w[active erased], only: :index

  def index
    @users = @users.send(@current_filter)
    @users = @users.by_username_email_or_document_number(params[:search]) if params[:search]
    @users = @users.page(params[:page])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @user = User.find(params[:id])
  end

  # Renders a view where you can show user info (like ID card) for verification
  def verify_id_card
    @user = User.find(params[:id])
  end


  def verify_id_card_update
    @user = User.find(params[:id])

    if @user.update(id_card_verified_at: Time.current)
      redirect_to admin_users_path, notice: "User ID card verified."
    else
      redirect_to verify_id_card_admin_user_path(@user), alert: "There was an error verifying the user's ID card."
    end
  end
end
