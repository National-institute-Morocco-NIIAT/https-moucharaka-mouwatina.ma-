class UsersController < ApplicationController
  load_and_authorize_resource
  before_action :check_slug
  helper_method :valid_interests_access?

  def show
    raise CanCan::AccessDenied if params[:filter] == "follows" && !valid_interests_access?(@user)
  end

  def upload_id_card
    @user = current_user
    render "document_verification"
  end

  def submit_id_card
    @user = current_user
    if @user.update(user_params)
      redirect_to root_path, notice: 'ID card uploaded successfully and pending verification.'
    else
      render :upload_id_card, alert: 'There was an error uploading the ID card.'
    end
  end

  private

    def check_slug
      slug = params[:id].split("-", 2)[1]

      raise ActiveRecord::RecordNotFound unless @user.slug == slug.to_s
    end

    def valid_interests_access?(user)
      user.public_interests || user == current_user
    end

    def user_params
      params.require(:user).permit(:front_id_card, :back_id_card)
    end
end
