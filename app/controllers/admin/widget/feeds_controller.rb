class Admin::Widget::FeedsController < Admin::BaseController
  def update
    @feed = ::Widget::Feed.find(params[:id])
    @feed.update!(feed_params)

    head :ok
  end

  private

    def feed_params
      params.require(:widget_feed).permit(allowed_params)
    end

    def allowed_params
      [:limit]
    end
end
