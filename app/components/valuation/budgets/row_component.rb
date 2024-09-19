class Valuation::Budgets::RowComponent < ApplicationComponent
  attr_reader :budget
  with_collection_parameter :budget

  use_helpers :current_user

  def initialize(budget:)
    @budget = budget
  end

  def investments
    return Budget::Investment.none unless budget.valuating_or_later?

    budget.investments.visible_to_valuator(current_user.valuator)
  end

  def valuation_open_investments_count
    return 0 unless budget.valuating?

    investments.valuation_open.count
  end
end
