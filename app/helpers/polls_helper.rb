module PollsHelper
  def booth_name_with_location(booth)
    location = booth.location.blank? ? "" : " (#{booth.location})"
    booth.name + location
  end

  def link_to_poll(text, poll, options = {})
    if can?(:results, poll)
      link_to text, results_poll_path(id: poll.slug || poll.id), options
    elsif can?(:stats, poll)
      link_to text, stats_poll_path(id: poll.slug || poll.id), options
    else
      link_to text, poll_path(id: poll.slug || poll.id), options
    end
  end

  def results_menu?
    controller_name == "polls" && action_name == "results"
  end

  def stats_menu?
    controller_name == "polls" && action_name == "stats"
  end

  def info_menu?
    controller_name == "polls" && action_name == "show"
  end

  def show_polls_description?
    @active_poll.present? && @current_filter == "current"
  end
end
