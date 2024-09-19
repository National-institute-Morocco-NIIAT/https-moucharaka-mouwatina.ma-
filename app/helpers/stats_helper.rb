module StatsHelper
  def number_to_stats_percentage(number, options = {})
    number_to_percentage(number, { strip_insignificant_zeros: true, precision: 2 }.merge(options))
  end

  def number_with_info_tags(number, text, html_class: "")
    tag.p class: "number-with-info #{html_class}".strip do
      tag.span class: "content" do
        tag.span(number, class: "number") + tag.span(text, class: "info")
      end
    end
  end
end
