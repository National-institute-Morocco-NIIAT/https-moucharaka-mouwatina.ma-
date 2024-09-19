class CommunitiesController < ApplicationController
  has_orders %w[newest most_commented oldest]
  before_action :set_community, :load_topics, :load_participants

  skip_authorization_check

  def show
    raise ActionController::RoutingError, "Not Found" unless communitable_exists?

    redirect_to root_path if Setting["feature.community"].blank?
  end

  private

    def set_community
      @community = Community.find(params[:id])
    end

    def load_topics
      @topics = @community.topics.send("sort_by_#{@current_order}").page(params[:page])
    end

    def load_participants
      @participants = @community.participants
    end

    def communitable_exists?
      @community.proposal.present? || @community.investment.present?
    end
end
