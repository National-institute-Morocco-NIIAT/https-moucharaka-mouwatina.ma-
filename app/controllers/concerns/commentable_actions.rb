module CommentableActions
  extend ActiveSupport::Concern
  include Polymorphic
  include Search
  include RemotelyTranslatable

  def index
    @resources = resource_model.all

    @resources = if @current_order == "recommendations" && current_user.present?
                   @resources.recommendations(current_user)
                 else
                   @resources.for_render
                 end
    @resources = @resources.search(@search_terms) if @search_terms.present?
    @resources = @resources.filter_by(@advanced_search_terms)

    @resources = @resources.page(params[:page]).send("sort_by_#{@current_order}")

    index_customization

    @tag_cloud = tag_cloud

    set_resources_instance
    @remote_translations = detect_remote_translations(@resources, featured_proposals)
  end

  def show
    @commentable = resource
    @comment_tree = CommentTree.new(@commentable, params[:page], @current_order)
    set_comment_flags(@comment_tree.comments)
    set_resource_instance
    @remote_translations = detect_remote_translations([@resource], @comment_tree.comments)
  end

  def new
    @resource = resource_model.new
    set_geozone
    set_resource_instance
  end

  def suggest
    @limit = 5
    @resources = @search_terms.present? ? resource_relation.search(@search_terms) : nil
  end

  def edit
  end

  def update
    if resource.update(strong_params)
      redirect_to resource, notice: t("flash.actions.update.#{resource_name.underscore}")
    else
      load_geozones
      set_resource_instance
      render :edit
    end
  end

  private

    def tag_cloud
      TagCloud.new(resource_model, params[:search])
    end

    def load_geozones
      @geozones = Geozone.order(name: :asc)
    end

    def set_geozone
      geozone_id = params[resource_name.to_sym].try(:[], :geozone_id)
      @resource.geozone = Geozone.find(geozone_id) if geozone_id.present?
    end

    def load_categories
      @categories = Tag.category.order(:name)
    end

    def index_customization
      nil
    end

    def featured_proposals
      @featured_proposals ||= []
    end
end
