class Budgets::Investments::FiltersComponent < ApplicationComponent
  use_helpers :valid_filters, :current_filter, :link_list, :current_path_with_query_params

  def render?
    valid_filters&.any?
  end

  private

    def filters
      valid_filters.map do |filter|
        [
          t("budgets.investments.index.filters.#{filter}"),
          current_path_with_query_params(filter: filter, page: 1),
          current_filter == filter
        ]
      end
    end
end
