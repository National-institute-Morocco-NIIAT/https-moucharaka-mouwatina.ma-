class Shared::TagListComponent < ApplicationComponent
  attr_reader :taggable, :limit
  use_helpers :link_list

  def initialize(taggable, limit:)
    @taggable = taggable
    @limit = limit
  end

  def render?
    taggable.tags_list.any?
  end

  private

    def links
      [*tag_links, see_more_link]
    end

    def tag_links
      taggable.tag_list_with_limit(limit).map do |tag|
        [
          sanitize(tag.name),
          taggables_path(taggable, tag.name)
        ]
      end
    end

    def see_more_link
      render Shared::SeeMoreLinkComponent.new(taggable, :tags_list, limit: limit)
    end

    def taggables_path(taggable, tag_name)
      case taggable.class.name
      when "Legislation::Proposal"
        legislation_process_proposals_path(taggable.process, search: tag_name)
      else
        polymorphic_path(taggable.class, search: tag_name)
      end
    end

    def machine_learning?
      Tag.machine_learning?
    end
end
