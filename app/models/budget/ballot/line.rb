class Budget
  class Ballot
    class Line < ApplicationRecord
      belongs_to :ballot, counter_cache: :ballot_lines_count
      belongs_to :investment, counter_cache: :ballot_lines_count
      belongs_to :heading
      belongs_to :group
      belongs_to :budget

      validates :ballot_id, :investment_id, :heading_id, :group_id, :budget_id, presence: true

      validate :check_selected
      validate :check_enough_resources
      validate :check_valid_heading

      scope :by_investment, ->(investment_id) { where(investment_id: investment_id) }

      before_validation :set_denormalized_ids

      def check_enough_resources
        ballot.with_lock do
          unless ballot.enough_resources?(investment)
            errors.add(:resources, ballot.not_enough_resources_error)
          end
        end
      end

      def check_valid_heading
        return if ballot.valid_heading?(heading)

        errors.add(:heading,
                   "This heading's budget is invalid, or a heading on the same group was already selected")
      end

      def check_selected
        errors.add(:investment, "unselected investment") unless investment.selected?
      end

      private

        def set_denormalized_ids
          self.heading_id ||= investment&.heading_id
          self.group_id   ||= investment&.group_id
          self.budget_id  ||= investment&.budget_id
        end
    end
  end
end
