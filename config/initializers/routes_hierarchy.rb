# This module is expanded in order to make it easier to use polymorphic
# routes with nested resources in the admin namespace
module ActionDispatch::Routing::UrlFor
  def resource_hierarchy_for(resource)
    resolve = resolve_for(resource)

    if resolve
      if resolve.last.is_a?(Hash)
        [resolve.first, *resolve.last.values]
      else
        resolve
      end
    else
      resource
    end
  end

  def admin_polymorphic_path(resource, options = {})
    namespaced_polymorphic_path(:admin, resource, options)
  end

  def sdg_management_polymorphic_path(resource, options = {})
    namespaced_polymorphic_path(:sdg_management, resource, options)
  end

  def namespaced_polymorphic_path(namespace, resource, options = {})
    if %w[Budget::Group Budget::Heading Legislation::DraftVersion Legislation::Question
          Poll::Booth Poll::BoothAssignment Poll::Officer Poll::Question Poll::Question::Option
          Poll::Question::Option::Video Poll::Shift SDG::LocalTarget].include?(resource.class.name)
      resolve = resolve_for(resource)
      resolve_options = resolve.pop

      polymorphic_path([namespace.to_sym, *resolve], options.merge(resolve_options))
    else
      polymorphic_path([namespace.to_sym, *resource_hierarchy_for(resource)], options)
    end
  end

  private

    def resolve_for(resource)
      polymorphic_mapping(resource)&.send(:eval_block, self, resource, {})
    end
end
