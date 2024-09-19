class Budgets::Executions::ImageComponent < ApplicationComponent
  attr_reader :investment
  use_helpers :image_path_for

  def initialize(investment)
    @investment = investment
  end

  private

    def milestone
      investment.milestones
                .order_by_publication_date
                .select { |milestone| milestone.image.present? }
                .last
    end
end
