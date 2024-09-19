class Admin::Poll::Questions::FilterComponent < ApplicationComponent
  attr_reader :polls
  use_helpers :current_path_with_query_params

  def initialize(polls)
    @polls = polls
  end

  private

    def poll_select_options
      options_from_collection_for_select(polls, :id, :name, params[:poll_id])
    end
end
