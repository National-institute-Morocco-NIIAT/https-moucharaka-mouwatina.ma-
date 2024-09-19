require "rails_helper"

describe "Videos", :admin do
  let(:future_poll) { create(:poll, :future) }
  let(:current_poll) { create(:poll) }
  let(:title) { "'Magical' by Junko Ohashi" }
  let(:url) { "https://www.youtube.com/watch?v=-JMf43st-1A" }

  describe "Create" do
    scenario "Is possible for a not started poll" do
      question = create(:poll_question, poll: future_poll)
      option = create(:poll_question_option, question: question)

      visit admin_question_path(question)

      within("#poll_question_option_#{option.id}") do
        click_link "Video list"
      end
      click_link "Add video"

      fill_in "Title", with: title
      fill_in "External video", with: url

      click_button "Save"

      expect(page).to have_content "Video created successfully"
      expect(page).to have_content title
      expect(page).to have_content url
    end

    scenario "Is not possible for an already started poll" do
      option = create(:poll_question_option, poll: current_poll)

      visit admin_option_videos_path(option)

      expect(page).not_to have_link "Add video"
      expect(page).to have_content "Once the poll has started it will not be possible to create, edit or"
    end
  end

  scenario "Update" do
    video = create(:poll_option_video, poll: future_poll)

    visit edit_admin_option_video_path(video.option, video)

    expect(page).to have_link "Go back", href: admin_option_videos_path(video.option)

    fill_in "Title", with: title
    fill_in "External video", with: url

    click_button "Save"

    expect(page).to have_content "Changes saved"
    expect(page).to have_content title
    expect(page).to have_content url
  end

  scenario "Destroy" do
    video = create(:poll_option_video, poll: future_poll)

    visit admin_option_videos_path(video.option)

    within("tr", text: video.title) do
      accept_confirm("Are you sure? This action will delete \"#{video.title}\" and can't be undone.") do
        click_button "Delete"
      end
    end

    expect(page).to have_content "Answer video deleted successfully."
    expect(page).not_to have_content video.title
  end
end
