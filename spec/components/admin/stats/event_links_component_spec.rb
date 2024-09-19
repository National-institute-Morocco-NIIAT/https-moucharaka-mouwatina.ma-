require "rails_helper"

describe Admin::Stats::EventLinksComponent do
  it "renders a list of links" do
    render_inline Admin::Stats::EventLinksComponent.new(
      %w[legislation_annotation_created legislation_answer_created]
    )

    expect(page).to have_link count: 2

    page.find("ul") do |list|
      expect(list).to have_link "Legislation annotations created"
      expect(list).to have_link "Legislation answers created"
    end
  end
end
