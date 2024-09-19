require "rails_helper"

describe Admin::Poll::Questions::TableActionsComponent, :admin do
  it "displays the edit and destroy actions when the poll has not started" do
    question = create(:poll_question, poll: create(:poll, :future))

    render_inline Admin::Poll::Questions::TableActionsComponent.new(question)

    expect(page).to have_link "Edit answers"
    expect(page).to have_link "Edit"
    expect(page).to have_button "Delete"
  end

  it "does not display the edit and destroy actions when the poll has started" do
    question = create(:poll_question, poll: create(:poll))

    render_inline Admin::Poll::Questions::TableActionsComponent.new(question)

    expect(page).to have_link "Edit answers"
    expect(page).not_to have_link "Edit"
    expect(page).not_to have_button "Delete"
  end
end
