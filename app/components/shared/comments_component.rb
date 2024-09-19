class Shared::CommentsComponent < ApplicationComponent
  attr_reader :record, :comment_tree, :valuation
  use_helpers :current_user, :current_order, :locale_and_user_status, :commentable_cache_key

  def initialize(record, comment_tree, valuation: false)
    @record = record
    @comment_tree = comment_tree
    @valuation = valuation
  end

  private

    def cache_key
      [
        locale_and_user_status,
        current_order,
        commentable_cache_key(record),
        comment_tree.comments,
        comment_tree.comment_authors,
        record.comments_count
      ]
    end
end
