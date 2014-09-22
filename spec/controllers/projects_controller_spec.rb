require 'spec_helper'

describe ProjectsController, type: :controller do

  context 'when logged out' do
    %w(    index new create    ).each do |action|
      specify do
        get action
        expect(response).to redirect_to(new_user_session_url)
      end
    end
    %w(    show edit update destroy    ).each do |action|
      specify do
        get action, id: 42
        expect(response).to redirect_to(new_user_session_url)
      end
    end
  end

  context 'when logged in' do

    let(:user)      { FactoryGirl.create :user }
    let(:projects)  { double('projects') }

    before do
      sign_in user
      subject.stub(current_user: user)
      user.stub(projects: projects)
    end

    describe 'collection actions' do

      describe '#index' do

        specify do
          get :index
          expect(response).to be_success
          expect(assigns[:projects]).to eq(projects)
        end

      end

      describe '#new' do

        specify do
          get :new
          expect(response).to be_success
          expect(assigns[:project]).to be_new_record
        end

      end

      describe '#create' do

        let(:project) { mock_model(Project) }
        let(:users)   { double('users') }

        before do
          allow(projects).to receive(:build).with({}) { project }
          project.stub(users: users)
          expect(users).to receive(:<<).with(user)
          project.stub(save: true)
        end

        specify do
          post :create, project: {}
          expect(assigns[:project]).to eq(project)
        end

        context 'when save succeeds' do

          specify do
            post :create, project: {}
            expect(response).to redirect_to(project_url(project))
            expect(flash[:notice]).to eq('Project was successfully created.')
          end

        end

        context 'when save fails' do

          before do
            project.stub(save: false)
          end

          specify do
            post :create, project: {}
            expect(response).to be_success
            expect(response).to render_template('new')
          end

        end

      end

    end

    describe 'member actions' do

      let(:project) { mock_model(Project, id: 42, to_json: '{foo:bar}') }
      let(:story)   { mock_model(Story) }

      before do
        allow(projects).to receive(:find).with(project.id.to_s) { project }
        project.stub_chain(:stories, :build) { story }
      end

      describe '#show' do

        context 'as html' do

          specify do
            get :show, id: project.id
            expect(response).to be_success
            expect(assigns[:project]).to eq(project)
            expect(assigns[:story]).to eq(story)
          end

        end

        context 'as json' do

          specify do
            xhr :get, :show, id: project.id
            expect(response).to be_success
            expect(assigns[:project]).to eq(project)
            expect(assigns[:story]).to eq(story)
          end

        end

      end

      describe '#edit' do

        let(:users) { double('users') }

        before do
          project.stub(users: users)
          expect(users).to receive(:build)
        end

        specify do
          get :edit, id: project.id
          expect(response).to be_success
          expect(assigns[:project]).to eq(project)
        end

      end

      describe '#update' do

        before do
          allow(project).to receive(:update_attributes).with({}) { true }
        end

        specify do
          put :update, id: project.id, project: {}
          expect(assigns[:project]).to eq(project)
        end

        context 'when update succeeds' do

          specify do
            put :update, id: project.id, project: {}
            expect(response).to redirect_to(project_url(project))
          end

        end

        context 'when update fails' do

          before do
            allow(project).to receive(:update_attributes).with({}) { false }
          end

          specify do
            put :update, id: project.id, project: {}
            expect(response).to be_success
            expect(response).to render_template('edit')
          end

        end

      end

      describe '#destroy' do

        before do
          expect(project).to receive(:destroy)
        end

        specify do
          delete :destroy, id: project.id
          expect(response).to redirect_to(projects_url)
        end

      end

    end

  end

end
