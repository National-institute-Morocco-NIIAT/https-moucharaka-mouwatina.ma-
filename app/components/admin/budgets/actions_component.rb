class Admin::Budgets::ActionsComponent < ApplicationComponent
  attr_reader :budget

  def initialize(budget)
    @budget = budget
  end

  private

    def action(action_name, **)
      render Admin::ActionComponent.new(action_name, budget, "aria-describedby": true, **)
    end

    def actions
      @actions ||= {
        calculate_winners: {
          hint: winners_hint,
          html: winners_action
        },
        ballots: {
          hint: ballots_hint,
          html: ballots_action
        },
        destroy: {
          hint: destroy_hint,
          html: destroy_action
        }
      }.select { |_, button| button[:html].present? }
    end

    def winners_action
      render Admin::Budgets::CalculateWinnersButtonComponent.new(budget)
    end

    def winners_hint
      t("admin.budgets.actions.descriptions.calculate_winners", phase: t("budgets.phase.finished"))
    end

    def destroy_action
      action(:destroy,
             text: t("admin.budgets.edit.delete"),
             confirm: t("admin.budgets.actions.confirm.destroy"),
             disabled: budget.investments.any? || budget.poll)
    end

    def destroy_hint
      if budget.investments.any?
        t("admin.budgets.destroy.unable_notice")
      elsif budget.poll
        t("admin.budgets.destroy.unable_notice_polls")
      else
        t("admin.budgets.actions.descriptions.destroy")
      end
    end

    def ballots_action
      if budget.published? && !budget.balloting_finished? && !budget.poll.present?
        action(:ballots,
               text: t("admin.budgets.actions.ballots"),
               path: create_budget_poll_path,
               method: :post,
               confirm: t("admin.budgets.actions.confirm.ballots"),
               disabled: !feature?("polls"))
      end
    end

    def ballots_hint
      if feature?("polls")
        t("admin.budgets.actions.descriptions.ballots")
      else
        link = admin_settings_path(anchor: "tab-participation-processes")
        t("admin.budgets.ballots.feature_disabled", link: link)
      end
    end

    def create_budget_poll_path
      balloting_phase = budget.phases.find_by(kind: "balloting")

      admin_polls_path(poll: {
        name: budget.name,
        budget_id: budget.id,
        starts_at: balloting_phase.starts_at,
        ends_at: balloting_phase.ends_at
      })
    end

    def descriptor_id(action_name)
      "#{dom_id(budget, action_name)}_descriptor"
    end
end
