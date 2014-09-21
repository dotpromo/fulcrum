require 'spec_helper'

describe Note, :type => :model do

  let(:project) { mock_model(Project, :suppress_notifications => true) }
  let(:user)    { mock_model(User) }
  let(:story)   { mock_model(Story, :project => project) }
  let(:note) { FactoryGirl.build(:note, :story => story, :user => user) }

  subject { note }

  describe "validations" do

    describe "#name" do
      before { subject.note = '' }
      it "should have an error on note" do
        subject.valid?
        expect(subject.errors[:note].size).to eq(1)
      end
    end

  end

  describe "#create_changeset" do

    let(:changesets)  { double("changesets" ) }

    before do
      expect(changesets).to receive(:create!)
      story.stub(:changesets  => changesets)
      story.stub(:project     => project)
    end

    it "creates a changeset on the story" do
      subject.create_changeset
    end

    context "when suppress_notifications is off" do

      let(:user1)         { mock_model(User) }
      let(:notify_users)  { [user, user1] }
      let(:mailer)        { double("mailer") }

      before do
        project.stub(:suppress_notifications => false)
        story.stub(:notify_users => notify_users)
        expect(Notifications).to receive(:new_note).with(subject, [user1]).and_return(mailer)
        expect(mailer).to receive(:deliver)
      end

      it "sends notifications" do
        subject.create_changeset
      end
    end
  end

  describe "#as_json" do

    it "returns the right keys" do
      expect(subject.as_json["note"].keys.sort).to eq(%w[
        created_at errors id note story_id updated_at user_id
      ])
    end

  end

  describe "#to_s" do
    before :each do
      note.note = "Test note"
      note.created_at = "Nov 3, 2011"
      allow(user).to receive(:name).and_return('user')
    end

    describe '#to_s' do
      subject { super().to_s }
      it { is_expected.to eq("Test note (user - Nov 03, 2011)") }
    end
  end
end
