require 'spec_helper'

describe StoriesController, :type => :controller do

  describe "when logged out" do
    %w[index done backlog in_progress create import import_upload].each do |action|
      specify do
        get action, :project_id => 99
        expect(response).to redirect_to(new_user_session_url)
      end
    end

    %w[show update destroy start finish deliver accept reject].each do |action|
      specify do
        get action, :project_id => 99, :id => 42
        expect(response).to redirect_to(new_user_session_url)
      end
    end
  end

  context "when logged in" do

    let(:user)      { FactoryGirl.create(:user) }
    let(:project)   { mock_model(Project, :id => 99, :stories => stories) }
    let(:story)     { mock_model(Story, :id => 42) }
    let(:projects)  { double("projects") }
    let(:stories)   { double("stories", :to_json => '{foo:bar}') }

    before do
      allow(subject).to receive(:current_user) { user }
      allow(user).to receive(:projects) { projects }
      allow(projects).to receive(:find).with(project.id.to_s) { project }
      sign_in user
    end

    describe "#index" do

      before do
        allow(projects).to receive(:find)
        allow(projects).to receive(:stories_notes)
        projects.stub_chain(:with_stories_notes, :find).with(
          project.id.to_s
        ) { project }
      end

      specify do
        xhr :get, :index, :project_id => project.id, :id => story.id
        expect(response).to be_success
        expect(response.body).to eq(stories.to_json)
      end
    end

    describe "#import" do
      specify do
        get :import, :project_id => project.id
        expect(response).to be_success
        expect(assigns[:project]).to eq(project)
        expect(response).to render_template('import')
      end
    end

    describe "#import_upload" do

      before do
        expect(project).to receive(:suppress_notifications=).with(true)
      end

      context "when csv file is missing" do
        specify do
          post :import_upload, :project_id => project.id
          expect(response).to render_template('import')
          expect(flash[:alert]).to eq("You must select a file for import")
        end
      end

      context "when csv file is present" do

        let(:csv)             { fixture_file_upload('csv/stories.csv') }
        let(:valid_story)     { mock_model(Story, :valid? => true) }
        let(:invalid_story)   { mock_model(Story, :valid? => false) }
        let(:import_stories)  { [valid_story, invalid_story] }

        before do
          allow(stories).to receive(:from_csv) { import_stories }
        end

        specify do
          post :import_upload, :project_id => project.id, :csv => csv
          expect(response).to be_success
          expect(assigns[:valid_stories]).to eq([valid_story])
          expect(assigns[:invalid_stories]).to eq([invalid_story])
          expect(flash[:notice]).to eq("Imported 1 story")
          expect(response).to render_template('import')
        end

        context "when a csv parse error occurs" do

          before do
            allow(stories).to receive(:from_csv).and_raise(
              CSV::MalformedCSVError.new("Bad CSV!")
            )
          end

          specify do
            post :import_upload, :project_id => project.id, :csv => csv
            expect(response).to be_success
            expect(flash[:alert]).to eq("Unable to import CSV: Bad CSV!")
            expect(response).to render_template('import')
          end

        end

      end
    end

    context "member actions" do

      let(:story) { mock_model(Story, :to_json => '{foo:bar}') }
      # The "foo" key should be stripped from this hash by the controller
      let(:story_params)  { {'title' => 'New Title', 'foo' => 'Bar'} }


      before do
        allow(stories).to receive(:find).with(story.id.to_s) { story }
        allow(projects).to receive(:find).with(project.id.to_s) { project }
      end

      describe "#show" do
        specify do
          xhr :get, :show, :project_id => project.id, :id => story.id
          expect(response).to be_success
          expect(response.body).to eq(story.to_json)
        end
      end

      describe "#update" do

        before do
          expect(story).to receive(:acting_user=).with(user)
        end

        context "when update succeeds" do

          before do
            expect(story).to receive(:update_attributes).with(
              {'title' => 'New Title'}
            ) { true }
          end

          specify do
            xhr :get, :update, :project_id => project.id, :id => story.id,
              :story => story_params
            expect(response).to be_success
            expect(response.body).to eq(story.to_json)
          end

        end

        context "when update fails" do

          before do
            expect(story).to receive(:update_attributes).with(
              {'title' => 'New Title'}
            ) { false }
          end

          specify do
            xhr :get, :update, :project_id => project.id, :id => story.id,
              :story => story_params
            expect(response.status).to eq(422)
            expect(response.body).to eq(story.to_json)
          end
        end
      end

      describe "#destroy" do

        before { expect(story).to receive(:destroy) }

        specify do
          xhr :delete, :destroy, :project_id => project.id, :id => story.id
          expect(response).to be_success
        end
      end

      %w[done backlog in_progress].each do |action|

        let(:scoped_stories)  { double("scoped_stories", :to_json => '{scoped:y}') }

        describe action do

          before do
            expect(stories).to receive(action) { scoped_stories }
          end

          specify do
            xhr :get, action, :project_id => project.id, :id => story.id
            expect(response).to be_success
            expect(response.body).to eq(scoped_stories.to_json)
          end
        end
      end

      describe "#create" do

        before do
          expect(stories).to receive(:build).with(
            {'title' => 'New Title'}
          ) { story }
          expect(story).to receive(:requested_by_id=).with(user.id)
        end

        context "when save succeeds" do

          before do
            expect(story).to receive(:save) { true }
          end

          specify do
            xhr :post, :create, :project_id => project.id, :id => story.id,
              :story => story_params
            expect(response).to be_success
            expect(response.body).to eq(story.to_json)
          end
        end

        context "when save fails" do

          before do
            expect(story).to receive(:save) { false }
          end

          specify do
            xhr :post, :create, :project_id => project.id, :id => story.id,
              :story => story_params
            expect(response.status).to eq(422)
            expect(response.body).to eq(story.to_json)
          end
        end

      end

      %w[start finish deliver accept reject].each do |action|

        describe action do
          before do
            expect(story).to receive("#{action}!")
          end
          specify do
            xhr :put, action, :project_id => project.id, :id => story.id
            expect(response).to redirect_to(project_url(project))
          end
        end

      end

    end
  end
end
