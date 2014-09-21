require 'spec_helper'

describe Changeset, :type => :model do

  describe "validations" do

    it "must have a story" do
      subject.story = nil
      subject.valid?
      expect(subject.errors[:story].size).to eq(1)
    end

    describe "associations" do
      let(:user)    { FactoryGirl.create(:user) }
      let(:project) { FactoryGirl.create(:project, :users => [user]) }
      let(:story)   { FactoryGirl.create(:story, :project => project,
                                     :requested_by => user) }
      let(:changeset) { FactoryGirl.create :changeset, :story => story, :project => project }

      it "must have a valid project" do
        changeset.project_id = "invalid"
        changeset.valid?
        expect(changeset.errors[:project].size).to eq(1)
      end

      it "must have a valid story" do
        changeset.story_id = "invalid"
        changeset.valid?
        expect(changeset.errors[:story].size).to eq(1)
      end
    end
  end

  describe "#project_id" do

    context "when project_id is blank" do

      let(:user)    { FactoryGirl.create(:user) }
      let(:project) { FactoryGirl.create(:project, :users => [user]) }
      let(:story)   { FactoryGirl.create(:story, :project => project,
                                     :requested_by => user) }

      subject do
        FactoryGirl.create :changeset, :story => story, :project => nil
      end

      it "shouldn't have any errors on project" do
        story.valid?
        expect(story.errors[:project].size).to eq(0)
      end

      describe '#project' do
        subject { super().project }
        it { is_expected.to eq(project) }
      end

    end

  end

  describe ".since" do
    specify do
      expect(Changeset.since(234).where_values.first).to eq('id > 234')
    end
  end
end
