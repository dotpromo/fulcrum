require 'spec_helper'

describe Project, :type => :model do
  let(:project) { FactoryGirl.build(:project) }
  subject { project }

  describe "validations" do

    describe "#name" do
      before :each do
        project.name = ''
      end
      it "should have an error on name" do
        subject.valid?
        expect(subject.errors[:name].size).to eq(1)
      end
    end

    describe "#default_velocity" do
      it "must be greater than 0" do
        subject.default_velocity = 0
        subject.valid?
        expect(subject.errors[:default_velocity].size).to eq(1)
      end

      it "must be an integer" do
        subject.default_velocity = 0
        subject.valid?
        expect(subject.errors[:default_velocity].size).to eq(1)
      end
    end

    describe "#point_scale" do
      before { subject.point_scale = 'invalid_point_scale' }
      it "has an error on point scale" do
        subject.valid?
        expect(subject.errors[:point_scale].size).to eq(1)
      end
    end

    describe "#iteration_length" do
      it "must be greater than 0" do
        subject.iteration_length = 0
        subject.valid?
        expect(subject.errors[:iteration_length].size).to eq(1)
      end

      it "must be less than 5" do
        subject.iteration_length = 0
        subject.valid?
        expect(subject.errors[:iteration_length].size).to eq(1)
      end

      it "must be an integer" do
        subject.iteration_length = 2.5
        subject.valid?
        expect(subject.errors[:iteration_length].size).to eq(1)
      end
    end

    describe "#iteration_start_day" do
      it "must be greater than -1" do
        subject.iteration_start_day = -1
        subject.valid?
        expect(subject.errors[:iteration_start_day].size).to eq(1)
      end

      it "must be less than 6" do
        subject.iteration_start_day = 7
        subject.valid?
        expect(subject.errors[:iteration_start_day].size).to eq(1)
      end

      it "must be an integer" do
        subject.iteration_start_day = 2.5
        subject.valid?
        expect(subject.errors[:iteration_start_day].size).to eq(1)
      end
    end

  end


  describe "defaults" do
    subject { Project.new }

    describe '#point_scale' do
      subject { super().point_scale }
      it { is_expected.to eq('fibonacci') }
    end

    describe '#default_velocity' do
      subject { super().default_velocity }
      it { is_expected.to eq(10) }
    end

    describe '#iteration_length' do
      subject { super().iteration_length }
      it { is_expected.to eq(1) }
    end

    describe '#iteration_start_day' do
      subject { super().iteration_start_day }
      it { is_expected.to eq(1) }
    end

    describe '#suppress_notifications' do
      subject { super().suppress_notifications }
      it { is_expected.to eq(false) }
    end
  end


  describe "cascade deletes" do
    let(:user) { FactoryGirl.create(:user) }
    let(:project) { FactoryGirl.create(:project, :users => [user]) }
    let(:story) { FactoryGirl.create(:story, :project => project,
                                 :requested_by => user) }
    before :each do
      story
    end
    specify "stories" do
      expect do
        project.destroy
      end.to change(Story, :count).by(-1)
    end

    specify "changesets" do
      expect do
        project.destroy
      end.to change(Changeset, :count).by(-1)
    end

  end


  describe "#to_s" do
    subject { FactoryGirl.build :project, :name => 'Test Name' }

    describe '#to_s' do
      subject { super().to_s }
      it { is_expected.to eq('Test Name') }
    end
  end

  describe "#point_values" do
    describe '#point_values' do
      subject { super().point_values }
      it { is_expected.to eq(Project::POINT_SCALES['fibonacci']) }
    end
  end

  describe "#last_changeset_id" do
    context "when there are no changesets" do
      before do
        allow(project).to receive(:changesets).and_return([])
      end

      describe '#last_changeset_id' do
        subject { super().last_changeset_id }
        it { is_expected.to be_nil }
      end
    end

    context "when there are changesets" do

      let(:changeset) { double("changeset", :id => 42) }

      before :each do
        allow(project).to receive(:changesets).and_return([nil, nil, changeset])
      end

      describe '#last_changeset_id' do
        subject { super().last_changeset_id }
        it { is_expected.to eq(changeset.id) }
      end
    end
  end

  describe 'CSV import' do
    let(:project) { FactoryGirl.create :project }
    let(:user) do
      FactoryGirl.create(:user).tap do |user|
        # project.users << user
      end
    end
    let(:csv_string) { "Title,Story Type,Requested By,Owned By,Current State\n" }

    it 'converts state to lowercase before creating the story' do
      csv_string << "My Story,feature,#{user.name},#{user.name},Accepted"

      project.stories.from_csv csv_string
      expect(project.stories.first.state).to eq('accepted')
    end

    it 'converts story type to lowercase before creating the story' do
      csv_string << "My Story,Chore,#{user.name},#{user.name},unscheduled"

      project.stories.from_csv csv_string
      expect(project.stories.first.story_type).to eq('chore')
    end
  end

  describe "#csv_filename" do
    subject { FactoryGirl.build(:project, :name => 'Test Project') }

    describe '#csv_filename' do
      subject { super().csv_filename }
      it { is_expected.to match(/^Test Project-\d{8}_\d{4}\.csv$/) }
    end
  end

  describe "#as_json" do
    subject { FactoryGirl.create :project }

    (Project::JSON_ATTRIBUTES + Project::JSON_METHODS).each do |key|
      describe '#as_json' do
        subject { super().as_json }
        it { expect(subject.as_json['project']).to have_key(key) }
      end
    end
  end

end
