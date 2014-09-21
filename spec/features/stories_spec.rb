require 'spec_helper'

describe "Stories", :type => :feature do

  before(:each) do
    sign_in user
  end

  let(:user)  {
    FactoryGirl.create :user, :email => 'user@example.com',
                              :password => 'password'
  }

  let(:project) do
    FactoryGirl.create :project,  :name => 'Test Project',
                                  :users => [user]
  end

  describe "full story life cycle" do

    before do
      project
    end

    it "steps through the full story life cycle", :js => true do
      visit project_path(project)

      click_on 'Add story'

      within('#chilly_bin') do
        fill_in 'title', :with => 'New story'
        click_on 'Save'
      end

      # Estimate the story
      within('#chilly_bin .story') do
        click_on '1'
        click_on 'start'
      end

      within('#in_progress .story') do
        click_on 'finish'
        click_on 'deliver'
        click_on 'accept'
      end

      expect(find('#in_progress .story.accepted .story-title')).to have_content('New story')

    end

  end

  describe "delete a story" do

    let(:story) {
      FactoryGirl.create(:story, :title => 'Delete Me', :project => project,
                                  :requested_by => user)
    }

    before do
      story
    end

    it "deletes the story", :js => true do
      visit project_path(project)

      within(story_selector(story)) do
        find('.story-title').trigger 'click'
        click_on 'Delete'
      end

      expect(page).not_to have_css(story_selector(story))
    end

  end

  describe "show and hide columns" do

    before do
      project
      Capybara.ignore_hidden_elements = true
    end

    it "hides and shows the columns", :js => true do

      visit project_path(project)

      columns = {
        "done"        => "Done",
        "in_progress" => "In Progress",
        "backlog"     => "Backlog",
        "chilly_bin"  => "Chilly Bin"
      }

      columns.each do |column, button_text|
        selector = "table.stories td.#{column}_column"
        expect(page).to have_css(selector)

        # Hide the column
        within('#column-toggles') do
          click_on button_text
        end
        expect(page).not_to have_css(selector)

        # Show the column
        within('#column-toggles') do
          click_on button_text
        end
        expect(page).to have_css(selector)

        # Hide the column with the 'close' button in the column header
        within("#{selector} .column_header") do
          click_link 'Close'
        end
        expect(page).not_to have_css(selector)

      end
    end
  end

  def story_selector(story)
    "#story-#{story.id}"
  end

end
